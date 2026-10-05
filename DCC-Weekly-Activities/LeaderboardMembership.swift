//
//  LeaderboardMembership.swift
//  DCC-Weekly-Activities
//
//  Opting in and out of the club leaderboard.
//
//  Strava removed the club activity feed on 1 September 2026, so the app can no
//  longer read the whole club's rides from one admin account. Each rider now
//  chooses to share their own rides, and the Worker reads their activity feed
//  on their behalf.
//
//  Token ownership matters here. Strava issues one refresh token per rider and
//  rotates it on every use, so once a rider has opted in the Worker owns that
//  token — if the app kept refreshing independently the two would invalidate
//  each other and the rider would be signed out. An enrolled rider therefore
//  gets access tokens from the Worker, authenticated with the member key issued
//  at enrolment. `accessToken()` below handles both cases.
//

import Foundation
import Observation

@MainActor
@Observable
final class LeaderboardMembership {
    static let shared = LeaderboardMembership()

    private enum Keys {
        static let memberKey = "dcc.leaderboard.memberKey"
        static let athleteID = "dcc.leaderboard.athleteID"
    }

    private let keychain: KeychainServiceProtocol
    private let workerURL: String

    /// True once this rider has chosen to share their rides with the club board.
    private(set) var isEnrolled: Bool = false
    private(set) var lastError: String?

    init(
        keychain: KeychainServiceProtocol = KeychainService.shared,
        workerURL: String = StravaConfig.workerURL
    ) {
        self.keychain = keychain
        self.workerURL = workerURL
        self.isEnrolled = keychain.load(key: Keys.memberKey) != nil
    }

    // MARK: - Opting in and out

    /// Share this rider's activities with the club leaderboard.
    ///
    /// Call this only from an explicit choice by the rider — it grants the
    /// Worker ongoing read access to their Strava activities. It must never be
    /// a side effect of signing in.
    @discardableResult
    func enrol(refreshToken: String) async -> Bool {
        lastError = nil
        do {
            let response: EnrolResponse = try await post("/enrol", ["refresh_token": refreshToken])
            keychain.save(key: Keys.memberKey, value: response.member_key)
            keychain.save(key: Keys.athleteID, value: String(response.athlete_id))
            isEnrolled = true
            return true
        } catch {
            lastError = "Could not join the leaderboard. Please try again."
            return false
        }
    }

    /// Stop sharing. The Worker deletes this rider's stored token and rides.
    @discardableResult
    func leave(accessToken: String) async -> Bool {
        lastError = nil
        do {
            let _: LeaveResponse = try await post("/leave", ["access_token": accessToken])
            clearLocalMembership()
            return true
        } catch {
            lastError = "Could not leave the leaderboard. Please try again."
            return false
        }
    }

    /// Forget membership locally, e.g. on logout. Does not tell the Worker, so
    /// use `leave(accessToken:)` when the rider is actually opting out.
    func clearLocalMembership() {
        keychain.delete(key: Keys.memberKey)
        keychain.delete(key: Keys.athleteID)
        isEnrolled = false
    }

    // MARK: - Access tokens

    /// A usable Strava access token.
    ///
    /// Enrolled riders get one from the Worker, which holds the only live
    /// refresh token. Everyone else refreshes with their own, as before.
    /// Returns nil if neither route is available.
    func accessToken(fallbackRefreshToken: String?) async -> String? {
        if let memberKey = keychain.load(key: Keys.memberKey),
           let athleteIDString = keychain.load(key: Keys.athleteID),
           let athleteID = Int(athleteIDString) {
            do {
                let token: TokenResponse = try await post("/refresh", [
                    "athlete_id": athleteID,
                    "member_key": memberKey
                ])
                return token.access_token
            } catch let error as MembershipError where error == .unauthorized {
                // The Worker no longer recognises this rider — most likely they
                // opted out on another device. Drop the stale key and fall back
                // rather than leaving the app unable to refresh at all.
                clearLocalMembership()
            } catch {
                return nil
            }
        }

        guard let refreshToken = fallbackRefreshToken else { return nil }
        let token: TokenResponse? = try? await post("/refresh", ["refresh_token": refreshToken])
        return token?.access_token
    }

    // MARK: - Transport

    private enum MembershipError: Error, Equatable {
        case badURL
        case unauthorized
        case server(Int)
    }

    private func post<T: Decodable>(_ path: String, _ body: [String: Any]) async throws -> T {
        guard let url = URL(string: workerURL + path) else { throw MembershipError.badURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await AppNetwork.session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            throw status == 401 ? MembershipError.unauthorized : MembershipError.server(status)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Worker responses

    private struct EnrolResponse: Decodable {
        let enrolled: Bool
        let athlete_id: Int
        let name: String
        let member_key: String
    }

    private struct LeaveResponse: Decodable {
        let enrolled: Bool
        let athlete_id: Int
    }

    private struct TokenResponse: Decodable {
        let access_token: String
        let expires_at: Int?
    }
}

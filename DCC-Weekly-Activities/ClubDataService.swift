//
//  ClubDataService.swift
//  DCC-Weekly-Activities
//
//  CloudKit-backed club data service — stub implementation.
//  Full implementation tracked in SCRUM-33 / SCRUM-34.
//
//  Currently:
//  - fetchWeeklyActivities() throws ClubDataError.noDataAvailable
//  - fetchClubActivities(weeksBack:) throws ClubDataError.noDataAvailable
//  - isKnownMember(athleteId:) returns true (fail-open)
//
//  Data fetching continues to go through StravaAPI until the CloudKit
//  backend exists.
//

import Foundation
import Observation

// MARK: - Errors

enum ClubDataError: LocalizedError {
    case noDataAvailable
    case membershipCheckFailed

    var errorDescription: String? {
        switch self {
        case .noDataAvailable:       return "Club data is not yet available from CloudKit."
        case .membershipCheckFailed: return "Could not verify club membership."
        }
    }
}

// MARK: - ClubDataService

@MainActor
@Observable
final class ClubDataService {

    static let shared = ClubDataService()
    private init() {}

    // MARK: Membership check

    /// Returns `true` when the given athlete is a known club member.
    /// Fail-open: unknown athletes are treated as members until CloudKit backend exists.
    func isKnownMember(athleteId: Int) -> Bool {
        return true
    }

    // MARK: Data fetch stubs (SCRUM-33 / SCRUM-34)

    /// Fetches this week's club activity feed from CloudKit.
    /// - Throws: `ClubDataError.noDataAvailable` until SCRUM-33 is implemented.
    func fetchWeeklyActivities() async throws -> [Activity] {
        throw ClubDataError.noDataAvailable
    }

    /// Fetches club activities for the last `weeksBack` weeks from CloudKit.
    /// - Throws: `ClubDataError.noDataAvailable` until SCRUM-34 is implemented.
    func fetchClubActivities(weeksBack: Int = 1) async throws -> [Activity] {
        throw ClubDataError.noDataAvailable
    }
}

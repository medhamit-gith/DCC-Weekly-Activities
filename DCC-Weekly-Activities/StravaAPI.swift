//  StravaAPI.swift
//  DCC-Weekly-Activities
//
//  Handles Strava OAuth login and fetching club/member activities.
//

import Foundation
import SwiftUI

// MARK: - Strava Constants (Replace with your club's details)
struct StravaConfig {
    static let clientID = "YOUR_CLIENT_ID"
    static let clientSecret = "YOUR_CLIENT_SECRET"
    static let redirectURI = "dccweeklyactivities://strava-callback"
    static let clubID = "YOUR_CLUB_ID" // Numeric club ID
    static let authorizeURL = "https://www.strava.com/oauth/mobile/authorize"
    static let tokenURL = "https://www.strava.com/oauth/token"
}

// MARK: - Strava OAuth & API Manager
@MainActor
class StravaAPI: ObservableObject {
    @Published var accessToken: String?
    
    static let shared = StravaAPI()
    private init() {}

    // MARK: - Begin OAuth Flow
    func beginOAuth() {
        // Compose OAuth URL
        let urlStr =
        "https://www.strava.com/oauth/mobile/authorize?client_id=\(StravaConfig.clientID)&response_type=code&redirect_uri=\(StravaConfig.redirectURI)&approval_prompt=auto&scope=read,activity:read_all,club:read&state=xyz"
        guard let url = URL(string: urlStr) else { return }
        // Open in browser (use ASWebAuthenticationSession in production)
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #endif
    }

    // MARK: - Handle Redirect (AppDelegate/SceneDelegate will call this)
    func handleRedirect(url: URL) async -> Bool {
        // Parse out the authorization code from the URL
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else { return false }
        return await exchangeCodeForToken(code: code)
    }

    // MARK: - Exchange Code for Token
    func exchangeCodeForToken(code: String) async -> Bool {
        guard let url = URL(string: StravaConfig.tokenURL) else { return false }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let params = "client_id=\(StravaConfig.clientID)&client_secret=\(StravaConfig.clientSecret)&code=\(code)&grant_type=authorization_code"
        req.httpBody = params.data(using: .utf8)
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let token = dict["access_token"] as? String {
                self.accessToken = token
                return true
            }
        } catch {
            print("Token exchange error: \(error)")
        }
        return false
    }

    // MARK: - Fetch Club Activities (Last 7 Days)
    func fetchLastWeeksClubActivities() async throws -> [Activity] {
        guard let token = accessToken else { throw URLError(.userAuthenticationRequired) }
        // Calculate date one week ago
        let oneWeekAgo = Int(Date().addingTimeInterval(-7*24*60*60).timeIntervalSince1970)
        let urlStr = "https://www.strava.com/api/v3/clubs/\(StravaConfig.clubID)/activities?per_page=50&after=\(oneWeekAgo)"
        guard let url = URL(string: urlStr) else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: req)
        let stravaActivities = try JSONDecoder().decode([StravaActivityResponse].self, from: data)
        // Convert to Activity models
        return stravaActivities.map { $0.toActivity() }
    }
}

// MARK: - Strava Activity Response (Decoding)
struct StravaActivityResponse: Codable {
    let id: Int
    let name: String
    let distance: Double // in meters
    let start_date: String
    let athlete: Athlete

    struct Athlete: Codable {
        let firstname: String
        let lastname: String
    }

    func toActivity() -> Activity {
        // Parse ISO8601 date
        let formatter = ISO8601DateFormatter()
        let dateVal = formatter.date(from: start_date) ?? Date()
        let km = distance / 1000.0
        let member = "\(athlete.firstname) \(athlete.lastname)"
        return Activity(id: String(id), memberName: member, activityName: name, distance: km, date: dateVal)
    }
}

// Note: You must set up your app's redirect URI with Strava and replace client ID/secret/club ID.
// You must also handle the OAuth redirect in your AppDelegate/SceneDelegate or via .onOpenURL in SwiftUI.

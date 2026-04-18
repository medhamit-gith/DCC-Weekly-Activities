//
//  CloudDataFetcher.swift
//  DCC-Weekly-Activities
//
//  Fetches club activity data from the Cloudflare Worker's /club-data endpoint.
//  This replaces direct Strava API calls from the iOS client.
//

import Foundation
import Observation

@MainActor
@Observable
final class CloudDataFetcher {
    static let shared = CloudDataFetcher()

    var members: [CloudMemberData] = []
    var previousWeekMembers: [CloudMemberData] = []
    var lastFetchedAt: Date?
    var weekStart: Date?
    var weekEnd: Date?
    var isLoading = false
    var errorMessage: String?

    private let baseURL = "https://dcc-strava.amit-r-kamat.workers.dev/club-data"

    private init() {}

    /// Fetches the current (or offset) week's club data and the previous week
    /// in parallel so dashboard stats can show week-over-week trends without
    /// needing the Strava OAuth two-week fetch.
    func fetchData(weekOffset: Int = 0) async {
        isLoading = true
        errorMessage = nil

        async let current  = fetchWeek(offset: weekOffset)
        async let previous = fetchWeek(offset: weekOffset - 1)

        do {
            let (currentResp, previousResp) = try await (current, previous)
            members             = currentResp.members
            previousWeekMembers = previousResp.members

            let formatter = ISO8601DateFormatter()
            if let dateStr = currentResp.lastFetchedAt {
                lastFetchedAt = formatter.date(from: dateStr)
            }
            weekStart = currentResp.weekStart.flatMap { Self.parseDayString($0) }
            weekEnd   = currentResp.weekEnd.flatMap   { Self.parseDayString($0) }

            errorMessage = nil
        } catch {
            errorMessage = "Could not load club data. Pull to refresh."
        }

        isLoading = false
    }

    private func fetchWeek(offset: Int) async throws -> CloudDataResponse {
        var components = URLComponents(string: baseURL)!
        if offset != 0 {
            components.queryItems = [URLQueryItem(name: "weekOffset", value: String(offset))]
        }
        guard let url = components.url else { throw URLError(.badURL) }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(CloudDataResponse.self, from: data)
    }

    private static func parseDayString(_ s: String) -> Date? {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: s)
    }

    /// Convert cloud data to the existing Activity model format for compatibility
    /// with existing chart/table/leaderboard views.
    func toActivities() -> [Activity] {
        Self.toActivities(members: members, weekStart: weekStart)
    }

    func toPreviousWeekActivities() -> [Activity] {
        let prevStart = weekStart.map { Calendar(identifier: .iso8601).date(byAdding: .day, value: -7, to: $0) ?? $0 }
        return Self.toActivities(members: previousWeekMembers, weekStart: prevStart)
    }

    private static func toActivities(members: [CloudMemberData], weekStart: Date?) -> [Activity] {
        let formatter = ISO8601DateFormatter()
        let fallback  = weekStart ?? Date()
        var activities: [Activity] = []
        for member in members {
            for act in (member.activities ?? []) {
                let date = act.startDate.flatMap { formatter.date(from: $0) } ?? fallback
                activities.append(Activity(
                    memberName: member.name,
                    activityName: act.name,
                    distance: act.distance,
                    date: date,
                    averageSpeed: act.averageSpeed,
                    elevationGain: Double(act.elevationGain),
                    movingTime: act.movingTime,
                    type: act.type
                ))
            }
        }
        return activities
    }
}

// MARK: - Response models matching Cloudflare Worker /club-data JSON

struct CloudDataResponse: Codable {
    let lastFetchedAt: String?
    let weekLabel: String?
    let weekStart: String?
    let weekEnd: String?
    let memberCount: Int?
    let totalActivities: Int?
    let members: [CloudMemberData]
}

struct CloudMemberData: Codable, Identifiable {
    var id: String { name }
    let name: String
    let totalDistance: Double
    let totalElevation: Int
    let totalMovingTime: Int
    let rideCount: Int
    let avgSpeed: Double
    let movingTimeFormatted: String?
    let activities: [CloudActivityData]?
}

struct CloudActivityData: Codable {
    let name: String
    let distance: Double
    let movingTime: Int
    let elevationGain: Int
    let averageSpeed: Double
    let type: String
    let startDate: String?
}

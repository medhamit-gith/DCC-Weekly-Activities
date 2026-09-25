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
    var lastFetchedAt: Date?
    var weekLabel: String?
    /// "observed" when the worker dated activities by first sighting rather than
    /// by their real start time. Surface this before presenting week totals as exact.
    var dateSource: String?
    var isLoading = false
    var errorMessage: String?

    private let baseURL = "https://dcc-strava.amit-r-kamat.workers.dev/club-data"

    private init() {}

    /// - Parameter weekOffset: 0 = current week, -1 = last week, etc.
    ///   Previously this was ignored and every call returned the current week,
    ///   so the week picker silently showed the same data for every selection.
    func fetchData(weekOffset: Int = 0) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        var components = URLComponents(string: baseURL)
        if weekOffset != 0 {
            components?.queryItems = [URLQueryItem(name: "weekOffset", value: String(weekOffset))]
        }

        guard let url = components?.url else {
            errorMessage = "Invalid data URL"
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Could not load club data. Pull to refresh."
                return
            }

            // The worker returns 422 when the requested week predates the
            // activity registry, with an explanation worth showing.
            guard httpResponse.statusCode == 200 else {
                if let decoded = try? JSONDecoder().decode(CloudDataError.self, from: data) {
                    errorMessage = decoded.error
                } else {
                    errorMessage = "Server returned an error. Pull to refresh."
                }
                return
            }

            let decoded = try JSONDecoder().decode(CloudDataResponse.self, from: data)
            members = decoded.members
            weekLabel = decoded.weekLabel
            dateSource = decoded.dateSource

            if let dateStr = decoded.lastFetchedAt {
                lastFetchedAt = CloudDataFetcher.isoFormatter.date(from: dateStr)
            }

            errorMessage = nil
        } catch {
            errorMessage = "Could not load club data. Pull to refresh."
        }
    }

    /// Shared parser. `.withFractionalSeconds` is required: the worker emits
    /// JavaScript `toISOString()` output, which always carries milliseconds.
    static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static func parseDate(_ raw: String?) -> Date? {
        guard let raw else { return nil }
        if let d = isoFormatter.date(from: raw) { return d }
        // Fall back for timestamps without fractional seconds.
        return ISO8601DateFormatter().date(from: raw)
    }

    /// Convert cloud data to the existing Activity model format for compatibility
    /// with existing chart/table/leaderboard views.
    func toActivities() -> [Activity] {
        var activities: [Activity] = []
        for member in members {
            for act in (member.activities ?? []) {
                // Previously this passed Date(), stamping every activity with the
                // moment of the fetch, which flattened all date-based charting.
                activities.append(Activity(
                    memberName: member.name,
                    activityName: act.name,
                    distance: act.distance,
                    date: CloudDataFetcher.parseDate(act.startDate) ?? lastFetchedAt ?? Date(),
                    averageSpeed: act.averageSpeed,
                    elevationGain: Double(act.elevationGain),
                    movingTime: act.movingTime,
                    type: act.sportType ?? act.type
                ))
            }
        }
        return activities
    }
}

// MARK: - Response models matching Cloudflare Worker /club-data JSON

struct CloudDataError: Codable {
    let error: String
}

struct CloudDataResponse: Codable {
    let lastFetchedAt: String?
    let weekLabel: String?
    let weekStart: String?
    let weekEnd: String?
    let memberCount: Int?
    let totalActivities: Int?
    /// "strava" | "observed" | "mixed" — see the worker's header comment.
    let dateSource: String?
    let registryRetentionDays: Int?
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
    /// Present since the worker began emitting sport_type; optional for
    /// compatibility with payloads cached by the previous version.
    let sportType: String?
    /// First-seen timestamp from the worker's registry, not the ride's start time.
    let startDate: String?
}

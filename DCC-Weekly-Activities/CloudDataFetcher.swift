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
    var isLoading = false
    var errorMessage: String?

    private let dataURL = "https://dcc-strava.amit-r-kamat.workers.dev/club-data"

    private init() {}

    func fetchData() async {
        isLoading = true
        errorMessage = nil

        do {
            guard let url = URL(string: dataURL) else {
                errorMessage = "Invalid data URL"
                isLoading = false
                return
            }

            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                errorMessage = "Server returned an error. Pull to refresh."
                isLoading = false
                return
            }

            let decoded = try JSONDecoder().decode(CloudDataResponse.self, from: data)
            members = decoded.members

            if let dateStr = decoded.lastFetchedAt {
                let formatter = ISO8601DateFormatter()
                lastFetchedAt = formatter.date(from: dateStr)
            }

            errorMessage = nil
        } catch {
            errorMessage = "Could not load club data. Pull to refresh."
        }

        isLoading = false
    }

    /// Convert cloud data to the existing Activity model format for compatibility
    /// with existing chart/table/leaderboard views.
    func toActivities() -> [Activity] {
        var activities: [Activity] = []
        for member in members {
            for act in (member.activities ?? []) {
                activities.append(Activity(
                    memberName: member.name,
                    activityName: act.name,
                    distance: act.distance,
                    date: Date(),
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
}

//
//  Models.swift
//  DCC-Weekly-Activities
//
//  Shared data models for Activity and MemberStats
//

import Foundation


// MARK: - Authenticated Athlete Profile

struct AthleteProfile: Codable, Identifiable {
    let id: Int
    let firstname: String
    let lastname: String
    let profile: String?
    let city: String?
    let state: String?
    let country: String?
}

// MARK: - Strava Activity Response (Decoding)
// NOTE: The /clubs/{id}/activities endpoint intentionally omits `id` and
// athlete identifiers for privacy. All numeric fields are made optional
// to handle activities where Strava returns 0 or null.
struct StravaActivityResponse: Codable {
    let name: String
    let distance: Double?          // in meters — may be 0 or missing
    let moving_time: Int?          // in seconds — may be missing
    let total_elevation_gain: Double? // in meters — may be missing
    let average_speed: Double?     // in meters/second — may be missing
    let start_date: String?        // ISO 8601 UTC datetime
    let start_date_local: String?  // ISO 8601 local datetime
    let type: String?
    let sport_type: String?        // newer Strava field, preferred over `type`
    let athlete: Athlete

    struct Athlete: Codable {
        let firstname: String
        let lastname: String
    }

    func toActivity() -> Activity {
        let formatter = ISO8601DateFormatter()
        // CRITICAL FIX: Try start_date first (UTC), then start_date_local as fallback
        // Some club activities may only have start_date_local
        // Use distantPast as final fallback to detect and skip invalid activities
        let dateVal: Date
        if let startDateStr = start_date, let parsed = formatter.date(from: startDateStr) {
            dateVal = parsed
        } else if let startDateLocalStr = start_date_local, let parsed = formatter.date(from: startDateLocalStr) {
            dateVal = parsed
        } else {
            dateVal = Date.distantPast
        }

        let km        = (distance ?? 0) / 1000.0
        let movingTimeSec = moving_time ?? 0

        // Calculate average speed from distance and time if Strava doesn't provide it
        var speedKMH  = (average_speed ?? 0) * 3.6  // m/s → km/h
        if speedKMH == 0 && movingTimeSec > 0 && km > 0 {
            // Calculate: speed = distance / time
            // km / seconds * 3600 = km/h
            speedKMH = (km / Double(movingTimeSec)) * 3600
        }

        let member    = "\(athlete.firstname) \(athlete.lastname)"
        // Prefer `sport_type` (newer) over legacy `type`
        let actType   = sport_type ?? type ?? "Ride"
        return Activity(
            memberName:    member,
            activityName:  name,
            distance:      km,
            date:          dateVal,
            averageSpeed:  speedKMH,
            elevationGain: total_elevation_gain ?? 0,
            movingTime:    movingTimeSec,
            type:          actType
        )
    }
}

// MARK: - Club Totals Model
struct ClubTotals {
    let totalCurrentWeekKM: Double
    let totalPreviousWeekKM: Double
    let totalCurrentWeekRides: Int
    let totalPreviousWeekRides: Int
    
    init(from stats: [MemberStats]) {
        self.totalCurrentWeekKM = stats.reduce(0) { $0 + $1.totalKM }
        self.totalPreviousWeekKM = stats.reduce(0) { $0 + $1.previousWeekKM }
        self.totalCurrentWeekRides = stats.reduce(0) { $0 + $1.totalRides }
        self.totalPreviousWeekRides = stats.reduce(0) { $0 + $1.previousWeekRides }
    }
}





//  StravaAPI.swift
//  StravaAPI.swift
//  DCC-Weekly-Activities
//
//  Handles Strava OAuth login and fetching club/member activities.
//
//  VERSION HISTORY:
//  2026-02-24: [HOTFIX] Removed broken in-code date filter for club activities.
//              Strava /v3/clubs/{id}/activities returns no start_date field.
//              All activities decoded with Date.distantPast causing filter rejection.
//              Server-side "after=" parameter handles date range filtering.
//  2026-02-27: [SMART-DATE] Added 14-day rolling window fallback when current week has no data.
//              When filtered activities return empty, automatically extends date
//              range to last 14 days (rolling window from today) and re-fetches. 
//              Prevents empty screens during slow weeks. Added isShowingExtendedRange 
//              flag for UI updates.
//  2026-02-24: [HOTFIX] Removed "before" parameter from club activities URL.
//              Strava /clubs/{id}/activities endpoint does not support both
//              "after" and "before" parameters simultaneously. Activities are
//              now filtered in-code using the week end date.
//

import Foundation
import Observation
import SwiftUI

// MARK: - Errors

enum StravaError: LocalizedError {
    case notAuthenticated
    case tokenExpired
    case badURL
    case decodingFailed
    case proxyError(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:   return "You are not logged in. Please connect with Strava."
        case .tokenExpired:       return "Your session has expired. Please log in again."
        case .badURL:             return "The request URL was invalid."
        case .decodingFailed:     return "The response from Strava could not be read."
        case .proxyError(let d):  return "Token exchange failed: \(d)"
        }
    }
}

// MARK: - Structured OAuth diagnostic logger
// All messages are prefixed with [OAuth] and a severity symbol so they are easy
// to filter in the Xcode console with the search term "[OAuth]".

enum OAuthLog {
    static func step(_ msg: String)  {
        #if DEBUG
        print("🔵 [OAuth] \(msg)")
        #endif
    }
    static func warn(_ msg: String)  {
        #if DEBUG
        print("🟡 [OAuth] \(msg)")
        #endif
    }
    static func fail(_ msg: String)  {
        #if DEBUG
        print("🔴 [OAuth] \(msg)")
        #endif
    }
}

// MARK: - StravaAPI  (data-only layer)
//
// Auth responsibilities have been extracted to UserAuthService.
// This class now only handles Strava API data fetching.
// Auth state is read from UserAuthService.shared at call time.
//
@MainActor
@Observable
final class StravaAPI {

    static let shared = StravaAPI()
    private init() {}

    /// UI flag: true when the 14-day extended range fallback is active.
    var isShowingExtendedRange: Bool = false

    // MARK: Auth state forwarding
    // These computed properties read from UserAuthService so existing
    // call-sites in views that haven't yet been migrated continue to work.
    // Views should prefer to observe UserAuthService.shared directly.

    var accessToken: String? {
        get { UserAuthService.shared.accessToken }
        set { UserAuthService.shared.accessToken = newValue }
    }

    var isAuthenticating: Bool {
        UserAuthService.shared.isAuthenticating
    }

    var lastError: AppError? {
        get { UserAuthService.shared.lastError }
        set { UserAuthService.shared.lastError = newValue }
    }

    var isDemoMode: Bool { UserAuthService.shared.isDemoMode }

    var currentRefreshToken:   String? { UserAuthService.shared.currentRefreshToken }
    var currentTokenExpiresAt: Int     { UserAuthService.shared.currentTokenExpiresAt }
    var isTokenFresh:          Bool    { UserAuthService.shared.isTokenFresh }

    // MARK: Auth delegation (legacy call-sites)

    func restoreDemoMode()              { UserAuthService.shared.restoreDemoMode() }
    func restoreRefreshToken(_ t: String) { UserAuthService.shared.restoreRefreshToken(t) }
    func logout()                       { UserAuthService.shared.logout() }

#if os(iOS)
    func beginOAuth()                   { UserAuthService.shared.beginOAuth() }
    func beginRealOAuth()               { UserAuthService.shared.beginRealOAuth() }
    @discardableResult
    func handleRedirect(url: URL) async -> Bool { await UserAuthService.shared.handleRedirect(url: url) }
    func fetchAuthenticatedAthlete() async throws -> AthleteProfile {
        try await UserAuthService.shared.fetchAuthenticatedAthlete()
    }
#endif

    // MARK: Token freshness (data methods use this internally)

    private func ensureFreshToken() async throws {
        try await UserAuthService.shared.ensureFreshToken()
    }

    // MARK: Fetch last week's club activities

    func fetchLastWeeksClubActivities(isExtendedFetch: Bool = false) async throws -> [Activity] {
        // Demo mode: return realistic mock activities so all charts and tables render
        if isDemoMode {
            OAuthLog.step("fetchLastWeeksClubActivities — demo mode, returning mock activities")
            return Self.mockActivities()
        }

        try await ensureFreshToken()
        guard let token = accessToken else { throw StravaError.notAuthenticated }

        // Use ISO week calculation for consistent Monday-Sunday boundaries
        let timestamps: (after: Int, before: Int)
        let interval: DateInterval
        
        if isExtendedFetch {
            // Fetch 2-week extended range
            timestamps = DateRangeProvider.getExtendedWeekTimestamps()
            interval = DateRangeProvider.getExtendedWeekRange()
        } else {
            // Fetch CURRENT week (not last completed week)
            // This ensures we show this week's data (Monday to today)
            timestamps = DateRangeProvider.getCurrentWeekTimestamps()
            interval = DateRangeProvider.getCurrentWeek()
        }
        
        // STRAVA CLUBS ENDPOINT CONSTRAINT — 2026-02-24
        // The /v3/clubs/{id}/activities endpoint does NOT support both
        // "after" and "before" query parameters in the same request.
        // Strava returns: {"message":"Bad Request","errors":[{"field":"before after","code":"both provided"}]}
        // Fix: send only "after" (start of week as Unix timestamp).
        // Filter the decoded response array in code using weekEnd date
        // to exclude any activities beyond the target week boundary.
        // Do not add "before" back to this URL under any circumstances.
        let urlStr = "https://www.strava.com/api/v3/clubs/\(StravaConfig.clubID)/activities?per_page=200&after=\(timestamps.after)"
        
        // Debug logging for date range verification
        let formatter = ISO8601DateFormatter()
        #if DEBUG
        print("📅 Fetching activities from \(formatter.string(from: interval.start)) to \(formatter.string(from: interval.end))")
        if isExtendedFetch {
            print("🔄 Extended 2-week range active due to empty current week")
        }
        print("📡 API URL: \(urlStr)")
        #endif
        
        guard let url = URL(string: urlStr) else { throw StravaError.badURL }

        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode == 401 { throw StravaError.tokenExpired }

        do {
            let decodedActivities = try JSONDecoder().decode([StravaActivityResponse].self, from: data).map { $0.toActivity() }
            
            // ─────────────────────────────────────────────────────
            // STRAVA CLUB ENDPOINT — NO DATE FIELD IN RESPONSE
            // The /v3/clubs/{id}/activities endpoint does not return
            // start_date or start_date_local in its response payload.
            // Date filtering is handled entirely server-side via the
            // "after" Unix timestamp query parameter.
            // DO NOT add a date-based filter here — it will reject
            // all activities as Date.distantPast.
            // Verified: 2026-02-24 — raw response confirmed no dates.
            // ─────────────────────────────────────────────────────
            let activities = decodedActivities
            // No date filter needed — Strava club endpoint does not 
            // return date fields. The API "after=" parameter handles
            // server-side filtering. All returned activities are 
            // within the requested date range by definition.
            
            #if DEBUG
            print("[Filter] Using all \(activities.count) activities returned by Strava API")
            #endif
            
            // SMART 2-WEEK FALLBACK — 2026-02-24
            // If Strava returned 0 activities for the week,
            // extend the range — no in-code filter to check
            if activities.count == 0 && !isExtendedFetch {
                #if DEBUG
                print("⚠️ No activities found for current week, extending to 2-week range...")
                #endif
                isShowingExtendedRange = true
                return try await fetchLastWeeksClubActivities(isExtendedFetch: true)
            } else if isExtendedFetch {
                // Already in extended mode
                isShowingExtendedRange = true
                if activities.count == 0 {
                    #if DEBUG
                    print("⚠️ No activities found in extended 2-week range")
                    #endif
                }
            } else {
                // Standard week with data
                isShowingExtendedRange = false
            }
            
            // Debug logging for fetched data
            let totalKM = activities.reduce(0.0) { $0 + $1.distance }
            #if DEBUG
            print("📊 Fetched \(activities.count) activities, total distance: \(String(format: "%.1f", totalKM)) km")
            #endif
            
            return activities
        } catch {
            AppLogger.error("Decoding club activities error: \(error)", error: error)
            OAuthLog.fail("Raw Strava club response: \(String(data: data, encoding: .utf8) ?? "<unreadable>")")
            throw StravaError.decodingFailed
        }
    }
    
    // MARK: Fetch activities for a specific week + its previous week

    /// Fetches club activities for the requested week AND the week before it.
    ///
    /// Because the Strava clubs endpoint does NOT return date fields in its response,
    /// we cannot split a single response reliably by date. Instead we make TWO
    /// sequential API calls — one for each week — using only the `after=` parameter
    /// (Strava rejects requests that include both `after=` and `before=`).
    ///
    /// Call 1: after = Monday of selected week  → selected week's activities
    /// Call 2: after = Monday of previous week  → both weeks combined; we subtract
    ///         the selected week count to isolate the previous week's activities.
    ///
    /// - Parameter weekOffset: 0 = this week, -1 = last week, -2 = two weeks ago, etc.
    /// - Returns: A tuple of (selectedWeekActivities, previousWeekActivities, selectedWeekInterval)
    func fetchActivitiesForWeek(
        offset weekOffset: Int
    ) async throws -> (current: [Activity], previous: [Activity], interval: DateInterval) {
        if isDemoMode {
            OAuthLog.step("fetchActivitiesForWeek — demo mode, returning mock activities")
            let mockAll = Self.mockActivities()
            let interval = DateRangeProvider.weekRange(offset: weekOffset)
            return (current: mockAll, previous: mockAll, interval: interval)
        }

        try await ensureFreshToken()
        guard let token = accessToken else { throw StravaError.notAuthenticated }

        let selectedWeek = DateRangeProvider.weekRange(offset: weekOffset)
        let previousWeek = DateRangeProvider.previousWeekRange(before: selectedWeek)

        let formatter = ISO8601DateFormatter()
        #if DEBUG
        print("📅 [WeekFetch] Selected: \(formatter.string(from: selectedWeek.start)) – \(formatter.string(from: selectedWeek.end))")
        print("📅 [WeekFetch] Previous: \(formatter.string(from: previousWeek.start)) – \(formatter.string(from: previousWeek.end))")
        #endif

        // ── Call 1: activities from start of SELECTED week onwards ────────────
        let currentTimestamp = Int(selectedWeek.start.timeIntervalSince1970)
        let currentURL = "https://www.strava.com/api/v3/clubs/\(StravaConfig.clubID)/activities?per_page=200&after=\(currentTimestamp)"
        #if DEBUG
        print("📡 [WeekFetch] Current week URL: \(currentURL)")
        #endif

        let currentActivities = try await fetchRawActivities(urlString: currentURL, token: token)
        #if DEBUG
        print("[WeekFetch] Selected week: \(currentActivities.count) activities")
        #endif

        // ── Call 2: activities from start of PREVIOUS week onwards ─────────────
        // This returns selected week + previous week combined.
        // We subtract the selected week activities to isolate the previous week.
        let previousTimestamp = Int(previousWeek.start.timeIntervalSince1970)
        let previousURL = "https://www.strava.com/api/v3/clubs/\(StravaConfig.clubID)/activities?per_page=200&after=\(previousTimestamp)"
        #if DEBUG
        print("📡 [WeekFetch] Two-week URL: \(previousURL)")
        #endif

        let twoWeekActivities = try await fetchRawActivities(urlString: previousURL, token: token)
        #if DEBUG
        print("[WeekFetch] Two-week combined: \(twoWeekActivities.count) activities")
        #endif

        // The previous week activities are the EXTRA ones returned by the wider call.
        // Strava returns newest-first, so the last (twoWeekCount - selectedWeekCount)
        // entries are the older (previous week) ones.
        let previousCount = max(0, twoWeekActivities.count - currentActivities.count)
        let previousActivities = Array(twoWeekActivities.suffix(previousCount))
        #if DEBUG
        print("[WeekFetch] Isolated previous week: \(previousActivities.count) activities")
        #endif

        isShowingExtendedRange = false
        return (current: currentActivities, previous: previousActivities, interval: selectedWeek)
    }

    /// Internal helper: performs a single GET to the clubs activities endpoint.
    private func fetchRawActivities(urlString: String, token: String) async throws -> [Activity] {
        guard let url = URL(string: urlString) else { throw StravaError.badURL }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode == 401 { throw StravaError.tokenExpired }

        do {
            return try JSONDecoder().decode([StravaActivityResponse].self, from: data).map { $0.toActivity() }
        } catch {
            AppLogger.error("[fetchRawActivities] Decoding error: \(error)", error: error)
            OAuthLog.fail("[fetchRawActivities] Raw response: \(String(data: data, encoding: .utf8) ?? "<unreadable>")")
            throw StravaError.decodingFailed
        }
    }

    // MARK: Fetch club activities for custom date range (legacy)

    func fetchClubActivities(weeksBack: Int = 3) async throws -> [Activity] {
        try await ensureFreshToken()
        guard let token = accessToken else { throw StravaError.notAuthenticated }

        let after  = Int(Date().addingTimeInterval(-Double(weeksBack) * 7 * 24 * 60 * 60).timeIntervalSince1970)
        let urlStr = "https://www.strava.com/api/v3/clubs/\(StravaConfig.clubID)/activities?per_page=200&after=\(after)"
        guard let url = URL(string: urlStr) else { throw StravaError.badURL }

        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode == 401 { throw StravaError.tokenExpired }

        do {
            return try JSONDecoder().decode([StravaActivityResponse].self, from: data).map { $0.toActivity() }
        } catch {
            AppLogger.error("[fetchClubActivities] Decoding error: \(error)", error: error)
            OAuthLog.fail("[fetchClubActivities] Raw response: \(String(data: data, encoding: .utf8) ?? "<unreadable>")")
            throw StravaError.decodingFailed
        }
    }
}

// MARK: - Simulator / Demo Mock Data

extension StravaAPI {
    /// Generates a realistic week of club activity data for Simulator demo mode.
    /// All rides are placed within the current ISO week so date-range filtering passes.
    static func mockActivities() -> [Activity] {
        let calendar = Calendar(identifier: .iso8601)
        let today = Date()
        // Anchor rides to Mon–today of the current ISO week
        func weekday(_ offset: Int) -> Date {
            // Use optional binding instead of force-unwrap; fall back to today if calendar fails
            guard let monday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
                AppLogger.warning("mockActivities: calendar week anchor calculation failed, using today")
                return calendar.date(byAdding: .day, value: offset, to: today) ?? today
            }
            return calendar.date(byAdding: .day, value: offset, to: monday) ?? today
        }

        let riders: [(name: String, rides: [(km: Double, speed: Double, elev: Double, day: Int, type: String)])] = [
            ("Amit Kamat",    [(42.5, 28.3, 320, 0, "Ride"), (28.1, 26.4, 180, 2, "Ride")]),
            ("Priya Sharma",  [(55.0, 30.1, 450, 1, "Ride"), (18.3, 24.0, 90,  3, "Ride")]),
            ("Rajesh Patel",  [(38.7, 27.5, 210, 0, "Ride")]),
            ("Neha Gupta",    [(61.2, 31.8, 520, 1, "Ride"), (35.4, 29.0, 280, 4, "Ride")]),
            ("Vikram Singh",  [(47.0, 29.2, 380, 2, "Ride"), (22.0, 25.5, 140, 5, "Ride")]),
            ("Sunita Mehta",  [(33.5, 26.8, 170, 3, "Ride")]),
            ("Arjun Nair",    [(70.1, 32.5, 610, 0, "Ride"), (40.0, 30.0, 350, 4, "Ride")]),
            ("Deepa Verma",   [(25.8, 23.9, 130, 1, "Ride")]),
            ("Karan Khanna",  [(52.3, 29.7, 430, 2, "Ride"), (30.0, 27.0, 200, 5, "Ride")]),
            ("Meera Joshi",   [(44.6, 28.0, 290, 3, "Ride")])
        ]

        var activities: [Activity] = []
        for rider in riders {
            for ride in rider.rides {
                let movingSec = Int((ride.km / ride.speed) * 3600)
                activities.append(Activity(
                    memberName:    rider.name,
                    activityName:  "Morning Ride",
                    distance:      ride.km,
                    date:          weekday(ride.day),
                    averageSpeed:  ride.speed,
                    elevationGain: ride.elev,
                    movingTime:    movingSec,
                    type:          ride.type
                ))
            }
        }
        return activities
    }
}

// Note: AthleteProfile and StravaActivityResponse are defined in Models.swift
// Note: OAuthPresentationContextProvider is defined in UserAuthService.swift

//
//  LaunchCache.swift
//  DCC-Weekly-Activities
//
//  Last known dashboard state, so a cold launch shows something immediately.
//
//  The app previously had nothing to draw until the network answered: it
//  fetched the athlete profile, then the club data, and showed a loading screen
//  until both returned. On a slow connection that was a long stare at a screen
//  with nothing on it, and offline it never resolved at all.
//
//  WeeklyCache already wrote a snapshot after every load, but nothing ever read
//  it back, and its MemberSnapshot is lossy — MemberStats can only be built
//  from the activities it was derived from. So this stores the activities
//  themselves, which rebuild through the real initialiser, plus the profile the
//  dashboard needs before it will render at all.
//

import Foundation

enum LaunchCache {

    /// Everything the dashboard needs to draw a week without the network.
    struct Snapshot: Codable {
        let savedAt: Date
        let weekOffset: Int
        let weekStart: Date
        let weekEnd: Date
        let profile: AthleteProfile
        let current: [Activity]
        let previous: [Activity]
    }

    /// How stale a snapshot may be and still be shown while fresh data loads.
    /// Beyond this it is likelier to mislead than to help, so the loading state
    /// is honest instead.
    static let maxAge: TimeInterval = 7 * 24 * 60 * 60

    private static var cacheURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("dcc_launch_cache.json")
    }

    static func save(
        profile: AthleteProfile,
        weekOffset: Int,
        weekStart: Date,
        weekEnd: Date,
        current: [Activity],
        previous: [Activity]
    ) {
        let snapshot = Snapshot(
            savedAt: Date(),
            weekOffset: weekOffset,
            weekStart: weekStart,
            weekEnd: weekEnd,
            profile: profile,
            current: current,
            previous: previous
        )
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: cacheURL, options: .atomic)
        } catch {
            // Never fatal: the cache is an optimisation, and a launch that
            // cannot write one still works, it is just slower next time.
            AppLogger.warning("[LaunchCache] Could not save: \(error.localizedDescription)")
        }
    }

    /// The cached snapshot, if it is for the requested week and still fresh.
    static func load(weekOffset: Int) -> Snapshot? {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: cacheURL)
            let snapshot = try JSONDecoder().decode(Snapshot.self, from: data)

            guard snapshot.weekOffset == weekOffset else { return nil }
            guard Date().timeIntervalSince(snapshot.savedAt) < maxAge else { return nil }

            // A snapshot for week 0 taken before this week started is last
            // week's data wearing the current week's label, which would be
            // worse than showing nothing.
            if weekOffset == 0 {
                let thisWeek = DateRangeProvider.weekRange(offset: 0)
                guard snapshot.weekStart >= thisWeek.start else { return nil }
            }
            return snapshot
        } catch {
            AppLogger.warning("[LaunchCache] Could not read: \(error.localizedDescription)")
            return nil
        }
    }

    static func clear() {
        try? FileManager.default.removeItem(at: cacheURL)
    }
}

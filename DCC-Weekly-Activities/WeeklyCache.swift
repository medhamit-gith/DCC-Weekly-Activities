//
//  WeeklyCache.swift
//  DCC-Weekly-Activities
//
//  Persists current week MemberStats to disk for use as previous week data.
//  On next app launch, yesterday's saved data becomes "previous week".
//

import Foundation

/// Persists current week MemberStats to disk.
/// On next app launch, yesterday's saved data becomes "previous week".
struct WeeklyCache {
    
    // MARK: - Codable snapshot
    
    /// Lightweight snapshot stored to disk — only what the table needs
    struct MemberSnapshot: Codable {
        let memberName: String
        let weekKM: Double
        let weekRides: Int
        let avgSpeed: Double
        let elevation: Double
        let savedAt: Date        // when this snapshot was taken
        let weekNumber: Int      // ISO week number
    }
    
    // MARK: - Storage key and file
    
    private static var cacheURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("dcc_weekly_cache.json")
    }
    
    // MARK: - Save (call after each successful Strava fetch)
    
    /// Save current week stats to disk.
    /// Replace ONLY if the current week number differs from what is saved,
    /// or if forced (e.g. first save ever).
    static func save(_ stats: [MemberStats]) {
        let currentWeek = Calendar.current.component(.weekOfYear, from: Date())
        
        // Load existing cache to check week number
        if let existing = load(), existing.first?.weekNumber == currentWeek {
            // Same week — update in place (stats may have grown during the week)
            writeSnapshots(from: stats, weekNumber: currentWeek)
        } else {
            // New week — existing cache becomes "previous week" automatically
            // on next load. Write new current week data.
            writeSnapshots(from: stats, weekNumber: currentWeek)
        }
    }
    
    @discardableResult
    private static func writeSnapshots(from stats: [MemberStats], weekNumber: Int) -> Bool {
        let snapshots = stats.map { s in
            MemberSnapshot(
                memberName: s.memberName,
                weekKM: s.totalKM,
                weekRides: s.totalRides,
                avgSpeed: s.avgSpeed,
                elevation: s.totalElevation,
                savedAt: Date(),
                weekNumber: weekNumber
            )
        }
        
        do {
            let data = try JSONEncoder().encode(snapshots)
            try data.write(to: cacheURL, options: .atomic)
            AppLogger.success("[WeeklyCache] Saved \(snapshots.count) snapshots for week \(weekNumber)")
            return true
        } catch {
            AppLogger.error("[WeeklyCache] Save failed", error: error)
            return false
        }
    }
    
    // MARK: - Load (call on app launch to get previous week data)
    
    /// Load snapshots from disk.
    /// Returns nil if no cache exists or cache is too old (> 14 days).
    static func load() -> [MemberSnapshot]? {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            AppLogger.warning("[WeeklyCache] No cache file exists")
            return nil
        }
        do {
            let data = try Data(contentsOf: cacheURL)
            let snapshots = try JSONDecoder().decode([MemberSnapshot].self, from: data)
            
            // Discard cache older than 14 days — too stale to be useful
            let cutoff = Date().addingTimeInterval(-14 * 24 * 3600)
            guard let newest = snapshots.first, newest.savedAt > cutoff else {
                AppLogger.warning("[WeeklyCache] Cache too old (> 14 days), discarding")
                return nil
            }
            
            AppLogger.success("[WeeklyCache] Loaded \(snapshots.count) snapshots from week \(newest.weekNumber)")
            return snapshots
        } catch {
            AppLogger.error("[WeeklyCache] Load failed", error: error)
            return nil
        }
    }
    
    // MARK: - Previous week lookup
    
    /// Returns a dictionary of memberName → previous week snapshot.
    /// Only returns data if the cached week number differs from current week.
    /// This prevents same-week cache from appearing as "previous week".
    static func previousWeekLookup() -> [String: MemberSnapshot] {
        let currentWeek = Calendar.current.component(.weekOfYear, from: Date())
        
        guard let snapshots = load() else {
            #if DEBUG
            print("[WeeklyCache] No previous week data available")
            #endif
            return [:]
        }
        
        // Only use as previous week if it was saved in a different week
        guard let firstSnap = snapshots.first,
              firstSnap.weekNumber != currentWeek else {
            // Cache is from this week — not useful as previous week yet
            #if DEBUG
            print("[WeeklyCache] Cache is from current week (\(currentWeek)), not using as previous week")
            #endif
            return [:]
        }
        
        let lookup = Dictionary(uniqueKeysWithValues: snapshots.map { ($0.memberName, $0) })
        AppLogger.success("[WeeklyCache] Previous week lookup ready: \(lookup.count) members from week \(firstSnap.weekNumber)")
        return lookup
    }
    
    // MARK: - Clear
    
    static func clear() {
        try? FileManager.default.removeItem(at: cacheURL)
        #if DEBUG
        print("[WeeklyCache] Cache cleared")
        #endif
    }
}

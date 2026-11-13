//
//  LaunchCacheTests.swift
//  DCC-Weekly-Activities Tests
//
//  SCRUM-85: the launch cache must not outlive a sign-out.
//
//  These tests read and write the real cache file in the test host's
//  Documents directory, so the suite is serialized and cleans up after itself.
//

import Testing
import Foundation
@testable import DCC_Weekly_Activities

@MainActor
@Suite("Launch Cache Tests", .serialized)
struct LaunchCacheTests {

    // A past week, so load() does not apply its "saved before this week
    // started" check and the test does not depend on today's date.
    private let weekOffset = -1

    private func saveSampleSnapshot() {
        let profile = AthleteProfile(
            id: 1,
            firstname: "Test",
            lastname: "Rider",
            profile: nil,
            city: nil,
            state: nil,
            country: nil
        )
        let ride = Activity(
            memberName: "Test R.",
            activityName: "Morning Ride",
            distance: 25.0,
            date: Date(),
            averageSpeed: 24.0,
            elevationGain: 150.0,
            movingTime: 3600
        )
        LaunchCache.save(
            profile: profile,
            weekOffset: weekOffset,
            weekStart: Date().addingTimeInterval(-7 * 24 * 60 * 60),
            weekEnd: Date(),
            current: [ride],
            previous: []
        )
    }

    @Test("A saved snapshot is returned for the same week")
    func savedSnapshotLoads() async throws {
        saveSampleSnapshot()
        defer { LaunchCache.clear() }

        let snapshot = LaunchCache.load(weekOffset: weekOffset)
        #expect(snapshot?.profile.id == 1)
        #expect(snapshot?.current.count == 1)
    }

    @Test("clear() removes the snapshot, so nothing is restored afterwards")
    func clearRemovesSnapshot() async throws {
        saveSampleSnapshot()
        LaunchCache.clear()

        #expect(LaunchCache.load(weekOffset: weekOffset) == nil)
    }
}

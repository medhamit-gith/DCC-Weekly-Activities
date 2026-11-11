//
//  ClubDataServiceTests.swift
//  DCC-Weekly-Activities Tests
//
//  Unit tests for ClubDataService (SCRUM-37, AC-2).
//
//  Scope note: as of this writing, ClubDataService.swift's own header says
//  it is "a stub implementation" — fetchWeeklyActivities() and
//  fetchClubActivities(weeksBack:) both unconditionally throw
//  ClubDataError.noDataAvailable, and isKnownMember(athleteId:) always
//  returns true ("fail-open ... until CloudKit backend exists"), pending
//  SCRUM-33/SCRUM-34. AC-2's "Fetch from CloudKit returns parsed
//  activities", "Offline fallback returns SwiftData cached data", and
//  "Malformed CloudKit data is handled gracefully" scenarios describe the
//  target design, not the current code, and can't be tested against a real
//  CloudKit response until that work lands. These tests instead pin down
//  the actual current stub contract, so a regression (e.g. a change that
//  silently starts returning data, or that breaks the fail-open behavior)
//  is caught.
//

import Testing
@testable import DCC_Weekly_Activities

@Suite("ClubDataService Tests")
@MainActor
struct ClubDataServiceTests {

    @Test("isKnownMember is fail-open and returns true for any athlete ID")
    func isKnownMemberIsFailOpen() async throws {
        let service = ClubDataService.shared
        #expect(service.isKnownMember(athleteId: 12345) == true)
        #expect(service.isKnownMember(athleteId: 0) == true)
        #expect(service.isKnownMember(athleteId: -1) == true)
    }

    @Test("fetchWeeklyActivities throws noDataAvailable until the CloudKit backend (SCRUM-33) exists")
    func fetchWeeklyActivitiesThrowsUntilImplemented() async throws {
        let service = ClubDataService.shared
        var caughtNoDataAvailable = false
        do {
            _ = try await service.fetchWeeklyActivities()
        } catch let error as ClubDataError {
            if case .noDataAvailable = error {
                caughtNoDataAvailable = true
            }
        }
        #expect(caughtNoDataAvailable, "fetchWeeklyActivities() should throw .noDataAvailable while SCRUM-33 is unimplemented")
    }

    @Test("fetchClubActivities throws noDataAvailable regardless of weeksBack until the CloudKit backend (SCRUM-34) exists")
    func fetchClubActivitiesThrowsUntilImplemented() async throws {
        let service = ClubDataService.shared
        for weeksBack in [1, 4, 12] {
            var caughtNoDataAvailable = false
            do {
                _ = try await service.fetchClubActivities(weeksBack: weeksBack)
            } catch let error as ClubDataError {
                if case .noDataAvailable = error {
                    caughtNoDataAvailable = true
                }
            }
            #expect(caughtNoDataAvailable, "fetchClubActivities(weeksBack: \(weeksBack)) should throw .noDataAvailable while SCRUM-34 is unimplemented")
        }
    }

    @Test("fetchClubActivities defaults weeksBack to 1 and still throws noDataAvailable")
    func fetchClubActivitiesDefaultsWeeksBackToOne() async throws {
        let service = ClubDataService.shared
        var caughtNoDataAvailable = false
        do {
            _ = try await service.fetchClubActivities()
        } catch let error as ClubDataError {
            if case .noDataAvailable = error {
                caughtNoDataAvailable = true
            }
        }
        #expect(caughtNoDataAvailable)
    }
}

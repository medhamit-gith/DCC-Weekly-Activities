//
//  SampleTests.swift
//  DCC-Weekly-Activities Tests
//
//  Example tests showing best practices and common patterns
//  USE THIS AS A REFERENCE when writing new tests
//

import Testing
import SwiftUI
@testable import DCC_Weekly_Activities

// MARK: - Basic Test Example

/// This is the simplest possible test
@Suite("Sample Basic Tests")
struct SampleBasicTests {
    
    @Test("Adding two numbers works correctly")
    func addingTwoNumbers() async throws {
        let result = 2 + 2
        #expect(result == 4, "Two plus two should equal four")
    }
    
    @Test("String concatenation works")
    func stringConcatenation() async throws {
        let greeting = "Hello, " + "World!"
        #expect(greeting == "Hello, World!")
    }
}

// MARK: - Testing Views

/// Shows how to test SwiftUI views
@Suite("Sample View Tests")
struct SampleViewTests {
    
    @Test("ActivityRow can be created with valid data")
    func activityRowCreation() async throws {
        // Arrange - Set up test data
        let activity = Activity(
            memberName: "John Doe",
            activityName: "Morning Run",
            distance: 5.0,
            date: Date(),
            averageSpeed: 10.0,
            elevationGain: 50.0,
            movingTime: 1800,
            type: "Run"
        )
        
        // Act - Create the view
        let view = ActivityRow(activity: activity)
        
        // Assert - Verify the view has correct data
        #expect(view.activity.memberName == "John Doe")
        #expect(view.activity.distance == 5.0)
        #expect(view.activity.type == "Run")
    }
    
    @Test("View displays with empty string name")
    func viewWithEmptyName() async throws {
        let activity = Activity(
            memberName: "", // Empty name - edge case!
            activityName: "Test",
            distance: 5.0,
            date: Date(),
            averageSpeed: 10.0,
            elevationGain: 50.0,
            movingTime: 1800
        )
        
        let view = ActivityRow(activity: activity)
        #expect(view.activity.memberName == "")
    }
}

// MARK: - Testing Data Models

/// Shows how to test model calculations
@Suite("Sample Model Tests")
struct SampleModelTests {
    
    @Test("Activity calculates pace correctly")
    func activityPaceCalculation() async throws {
        let activity = Activity(
            memberName: "Test User",
            activityName: "Test Run",
            distance: 10.0, // 10 km
            date: Date(),
            averageSpeed: 12.0, // 12 km/h
            elevationGain: 100.0,
            movingTime: 3000, // 50 minutes
            type: "Run"
        )
        
        // Calculate pace in min/km
        let paceInSeconds = Double(activity.movingTime) / activity.distance
        let paceMinutes = Int(paceInSeconds / 60)
        
        #expect(paceMinutes == 5, "Pace should be 5 min/km")
    }
    
    @Test("MemberStats aggregates multiple activities")
    func memberStatsAggregation() async throws {
        let activities = [
            Activity(memberName: "Alice", activityName: "Run 1", distance: 5.0, date: Date(), averageSpeed: 10.0, elevationGain: 50.0, movingTime: 1800, type: "Run"),
            Activity(memberName: "Alice", activityName: "Run 2", distance: 8.0, date: Date(), averageSpeed: 12.0, elevationGain: 75.0, movingTime: 2400, type: "Run")
        ]
        
        let stats = MemberStats(memberName: "Alice", activities: activities)
        
        #expect(stats.totalKM == 13.0, "Total distance should be 5 + 8 = 13")
        #expect(stats.totalRides == 2, "Should count 2 activities")
        #expect(stats.totalElevation == 125.0, "Total elevation should be 50 + 75")
    }
}

// MARK: - Testing Collections

/// Shows how to test array operations
@Suite("Sample Collection Tests")
struct SampleCollectionTests {
    
    @Test("Filtering activities by member name")
    func filteringByMember() async throws {
        let activities = [
            Activity(memberName: "Alice", activityName: "Run", distance: 5.0, date: Date(), averageSpeed: 10.0, elevationGain: 50.0, movingTime: 1800, type: "Run"),
            Activity(memberName: "Bob", activityName: "Ride", distance: 20.0, date: Date(), averageSpeed: 25.0, elevationGain: 200.0, movingTime: 2880, type: "Ride"),
            Activity(memberName: "Alice", activityName: "Run 2", distance: 8.0, date: Date(), averageSpeed: 12.0, elevationGain: 75.0, movingTime: 2400, type: "Run")
        ]
        
        let aliceActivities = activities.filter { $0.memberName == "Alice" }
        
        #expect(aliceActivities.count == 2, "Alice should have 2 activities")
        #expect(aliceActivities.allSatisfy { $0.memberName == "Alice" })
    }
    
    @Test("Sorting activities by distance")
    func sortingByDistance() async throws {
        let activities = [
            Activity(memberName: "User", activityName: "Short", distance: 5.0, date: Date(), averageSpeed: 10.0, elevationGain: 50.0, movingTime: 1800, type: "Run"),
            Activity(memberName: "User", activityName: "Long", distance: 20.0, date: Date(), averageSpeed: 15.0, elevationGain: 200.0, movingTime: 4800, type: "Run"),
            Activity(memberName: "User", activityName: "Medium", distance: 10.0, date: Date(), averageSpeed: 12.0, elevationGain: 100.0, movingTime: 3000, type: "Run")
        ]
        
        let sorted = activities.sorted { $0.distance > $1.distance }
        
        #expect(sorted[0].distance == 20.0, "Longest should be first")
        #expect(sorted[1].distance == 10.0, "Medium should be second")
        #expect(sorted[2].distance == 5.0, "Shortest should be last")
    }
    
    @Test("Grouping activities by member")
    func groupingByMember() async throws {
        let activities = [
            Activity(memberName: "Alice", activityName: "Run", distance: 5.0, date: Date(), averageSpeed: 10.0, elevationGain: 50.0, movingTime: 1800, type: "Run"),
            Activity(memberName: "Bob", activityName: "Ride", distance: 20.0, date: Date(), averageSpeed: 25.0, elevationGain: 200.0, movingTime: 2880, type: "Ride"),
            Activity(memberName: "Alice", activityName: "Run 2", distance: 8.0, date: Date(), averageSpeed: 12.0, elevationGain: 75.0, movingTime: 2400, type: "Run")
        ]
        
        let grouped = Dictionary(grouping: activities, by: \.memberName)
        
        #expect(grouped.keys.count == 2, "Should have 2 unique members")
        #expect(grouped["Alice"]?.count == 2, "Alice should have 2 activities")
        #expect(grouped["Bob"]?.count == 1, "Bob should have 1 activity")
    }
}

// MARK: - Testing Edge Cases

/// Shows how to test edge cases and boundary conditions
@Suite("Sample Edge Case Tests")
struct SampleEdgeCaseTests {
    
    @Test("Activity with zero distance")
    func zeroDistance() async throws {
        let activity = Activity(
            memberName: "Test",
            activityName: "Rest Day",
            distance: 0.0,
            date: Date(),
            averageSpeed: 0.0,
            elevationGain: 0.0,
            movingTime: 0
        )
        
        #expect(activity.distance == 0.0)
        #expect(activity.averageSpeed == 0.0)
    }
    
    @Test("Activity with very large distance")
    func veryLargeDistance() async throws {
        let activity = Activity(
            memberName: "Ultra Runner",
            activityName: "Ultra Marathon",
            distance: 250.0,
            date: Date(),
            averageSpeed: 8.0,
            elevationGain: 5000.0,
            movingTime: 112500
        )
        
        #expect(activity.distance == 250.0)
        #expect(activity.elevationGain == 5000.0)
    }
    
    @Test("Activity with emoji in name")
    func activityWithEmoji() async throws {
        let activity = Activity(
            memberName: "🏃‍♂️ Runner",
            activityName: "Morning Run 🌅",
            distance: 5.0,
            date: Date(),
            averageSpeed: 10.0,
            elevationGain: 50.0,
            movingTime: 1800
        )
        
        #expect(activity.memberName.contains("🏃‍♂️"))
        #expect(activity.activityName.contains("🌅"))
    }
    
    @Test("Empty activities list")
    func emptyActivitiesList() async throws {
        let activities: [Activity] = []
        
        let grouped = Dictionary(grouping: activities, by: \.memberName)
        let stats = grouped.map { name, acts in
            MemberStats(memberName: name, activities: acts)
        }
        
        #expect(stats.isEmpty, "Stats should be empty for empty activities")
    }
}

// MARK: - Testing with Test Data Factory

/// Shows how to use TestDataFactory for cleaner tests
@Suite("Sample Tests Using Test Factory")
struct SampleTestFactoryTests {
    
    @Test("Creating test data with factory")
    func usingTestFactory() async throws {
        // Instead of creating activity manually, use factory
        let activity = TestDataFactory.sampleRunActivity
        
        #expect(activity.type == "Run")
        #expect(activity.distance > 0)
    }
    
    @Test("Creating multiple test members")
    func creatingMultipleMembers() async throws {
        let activities = TestDataFactory.multipleActivitiesForMultipleMembers
        
        #expect(activities.count > 0)
        
        let uniqueMembers = Set(activities.map { $0.memberName })
        #expect(uniqueMembers.count > 1, "Should have multiple unique members")
    }
}

// MARK: - Testing Async Operations

/// Shows how to test async code
@Suite("Sample Async Tests")
struct SampleAsyncTests {
    
    @Test("Async data loading simulation")
    func asyncDataLoading() async throws {
        // Simulate async operation
        let activities = await fetchMockActivities()
        
        #expect(!activities.isEmpty, "Should fetch some activities")
    }
    
    // Mock async function
    private func fetchMockActivities() async -> [Activity] {
        // Simulate network delay
        try? await Task.sleep(for: .milliseconds(10))
        
        return [
            TestDataFactory.sampleRunActivity,
            TestDataFactory.sampleRideActivity
        ]
    }
}

// MARK: - Testing Error Handling

/// Shows how to test error conditions
@Suite("Sample Error Handling Tests")
struct SampleErrorTests {
    
    @Test("Division by zero handling")
    func divisionByZero() async throws {
        let activities: [Activity] = []
        let stats = MemberStats(memberName: "Nobody", activities: activities)
        
        // avgSpeed should be 0 when there are no activities
        #expect(stats.avgSpeed == 0.0, "Average speed should be 0 for empty activities")
    }
}

// MARK: - Testing Calculations

/// Shows how to test mathematical calculations
@Suite("Sample Calculation Tests")
struct SampleCalculationTests {
    
    @Test("Average speed calculation")
    func averageSpeedCalculation() async throws {
        let activities = [
            Activity(memberName: "Test", activityName: "A1", distance: 10.0, date: Date(), averageSpeed: 10.0, elevationGain: 0, movingTime: 3600, type: "Run"),
            Activity(memberName: "Test", activityName: "A2", distance: 10.0, date: Date(), averageSpeed: 12.0, elevationGain: 0, movingTime: 3000, type: "Run"),
            Activity(memberName: "Test", activityName: "A3", distance: 10.0, date: Date(), averageSpeed: 11.0, elevationGain: 0, movingTime: 3272, type: "Run")
        ]
        
        let stats = MemberStats(memberName: "Test", activities: activities)
        
        // Average of 10, 12, 11 = 11.0
        let expectedAvg = 11.0
        #expect(abs(stats.avgSpeed - expectedAvg) < 0.01, "Average should be approximately 11.0")
    }
    
    @Test("Total distance calculation")
    func totalDistanceCalculation() async throws {
        let activities = [
            TestDataFactory.createSampleActivity(distance: 5.5),
            TestDataFactory.createSampleActivity(distance: 10.25),
            TestDataFactory.createSampleActivity(distance: 7.75)
        ]
        
        let total = activities.reduce(0.0) { $0 + $1.distance }
        
        #expect(abs(total - 23.5) < 0.01, "Total should be 5.5 + 10.25 + 7.75 = 23.5")
    }
}

// MARK: - Real-World Example

/// Shows a complete real-world test scenario
@Suite("Sample Real-World Scenario")
struct SampleRealWorldScenario {
    
    @Test("Weekly leaderboard calculation")
    func weeklyLeaderboardCalculation() async throws {
        // Arrange - Create a week's worth of activities for multiple members
        let activities = [
            // Alice - 3 runs totaling 23 km
            Activity(memberName: "Alice", activityName: "Mon Run", distance: 8.0, date: Date(), averageSpeed: 11.0, elevationGain: 80, movingTime: 2618, type: "Run"),
            Activity(memberName: "Alice", activityName: "Wed Run", distance: 5.0, date: Date(), averageSpeed: 10.0, elevationGain: 50, movingTime: 1800, type: "Run"),
            Activity(memberName: "Alice", activityName: "Fri Run", distance: 10.0, date: Date(), averageSpeed: 12.0, elevationGain: 100, movingTime: 3000, type: "Run"),
            
            // Bob - 2 rides totaling 60 km
            Activity(memberName: "Bob", activityName: "Tue Ride", distance: 35.0, date: Date(), averageSpeed: 28.0, elevationGain: 350, movingTime: 4500, type: "Ride"),
            Activity(memberName: "Bob", activityName: "Sat Ride", distance: 25.0, date: Date(), averageSpeed: 25.0, elevationGain: 250, movingTime: 3600, type: "Ride"),
            
            // Charlie - 1 walk totaling 3 km
            Activity(memberName: "Charlie", activityName: "Sun Walk", distance: 3.0, date: Date(), averageSpeed: 5.0, elevationGain: 10, movingTime: 2160, type: "Walk")
        ]
        
        // Act - Build leaderboard
        let grouped = Dictionary(grouping: activities, by: \.memberName)
        let leaderboard = grouped.map { name, acts in
            MemberStats(memberName: name, activities: acts)
        }
        .sorted { $0.totalKM > $1.totalKM }
        
        // Assert - Verify leaderboard order
        #expect(leaderboard.count == 3, "Should have 3 members")
        
        #expect(leaderboard[0].memberName == "Bob", "Bob should be 1st")
        #expect(leaderboard[0].totalKM == 60.0, "Bob's total should be 60 km")
        
        #expect(leaderboard[1].memberName == "Alice", "Alice should be 2nd")
        #expect(leaderboard[1].totalKM == 23.0, "Alice's total should be 23 km")
        
        #expect(leaderboard[2].memberName == "Charlie", "Charlie should be 3rd")
        #expect(leaderboard[2].totalKM == 3.0, "Charlie's total should be 3 km")
    }
}

// MARK: - Test Documentation

/*
 
 HOW TO USE THIS FILE
 ====================
 
 1. Copy any test pattern you need
 2. Modify for your specific use case
 3. Run with ⌘U
 4. Check results in Test Navigator (⌘6)
 
 COMMON PATTERNS
 ===============
 
 Basic Test:
 -----------
 @Test("Description")
 func testName() async throws {
     let result = doSomething()
     #expect(result == expected)
 }
 
 Test with Setup:
 ---------------
 @Test("Description")
 func testWithSetup() async throws {
     // Arrange
     let data = createTestData()
     
     // Act
     let result = process(data)
     
     // Assert
     #expect(result.isValid)
 }
 
 Test Collections:
 ----------------
 @Test("Description")
 func testCollection() async throws {
     let items = [1, 2, 3]
     #expect(items.count == 3)
     #expect(items.first == 1)
     #expect(items.allSatisfy { $0 > 0 })
 }
 
 Test Edge Cases:
 ---------------
 @Test("Description")
 func testEdgeCase() async throws {
     let edge = createEdgeCaseData()
     #expect(edge != nil) // Shouldn't crash
 }
 
 BEST PRACTICES
 ==============
 
 ✅ DO:
 - Use descriptive test names
 - Test one thing per test
 - Use test data factories
 - Test edge cases
 - Keep tests fast (<1 second)
 
 ❌ DON'T:
 - Test multiple things in one test
 - Use hardcoded dates/UUIDs
 - Rely on test execution order
 - Test implementation details
 - Skip edge cases
 
 */

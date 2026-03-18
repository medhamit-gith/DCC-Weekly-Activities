//
//  TestConfiguration.swift
//  DCC-Weekly-Activities Tests
//
//  Shared test utilities and helpers
//

import Foundation
import Testing
@testable import DCC_Weekly_Activities

// MARK: - Test Data Factory

/// Factory for creating consistent test data across all tests
enum TestDataFactory {
    
    // MARK: Sample Activities
    
    static func createSampleActivity(
        memberName: String = "Test User",
        activityName: String = "Test Activity",
        distance: Double = 10.0,
        date: Date = Date(),
        averageSpeed: Double = 12.0,
        elevationGain: Double = 100.0,
        movingTime: Int = 3000,
        type: String = "Run"
    ) -> Activity {
        Activity(
            memberName: memberName,
            activityName: activityName,
            distance: distance,
            date: date,
            averageSpeed: averageSpeed,
            elevationGain: elevationGain,
            movingTime: movingTime,
            type: type
        )
    }
    
    static var sampleRunActivity: Activity {
        createSampleActivity(
            memberName: "Runner Joe",
            activityName: "Morning Run",
            distance: 5.0,
            averageSpeed: 10.0,
            elevationGain: 50.0,
            movingTime: 1800,
            type: "Run"
        )
    }
    
    static var sampleRideActivity: Activity {
        createSampleActivity(
            memberName: "Cyclist Jane",
            activityName: "Evening Ride",
            distance: 25.0,
            averageSpeed: 25.0,
            elevationGain: 300.0,
            movingTime: 3600,
            type: "Ride"
        )
    }
    
    static var sampleWalkActivity: Activity {
        createSampleActivity(
            memberName: "Walker Bob",
            activityName: "Lunch Walk",
            distance: 2.0,
            averageSpeed: 5.0,
            elevationGain: 10.0,
            movingTime: 1440,
            type: "Walk"
        )
    }
    
    // MARK: Activity Collections
    
    static var multipleActivitiesForOneMember: [Activity] {
        [
            createSampleActivity(memberName: "Alice", activityName: "Run 1", distance: 5.0, type: "Run"),
            createSampleActivity(memberName: "Alice", activityName: "Run 2", distance: 8.0, date: Date().addingTimeInterval(-3600), type: "Run"),
            createSampleActivity(memberName: "Alice", activityName: "Run 3", distance: 10.0, date: Date().addingTimeInterval(-7200), type: "Run")
        ]
    }
    
    static var multipleActivitiesForMultipleMembers: [Activity] {
        [
            createSampleActivity(memberName: "Alice", activityName: "Run 1", distance: 5.0, type: "Run"),
            createSampleActivity(memberName: "Bob", activityName: "Ride 1", distance: 20.0, type: "Ride"),
            createSampleActivity(memberName: "Alice", activityName: "Run 2", distance: 8.0, type: "Run"),
            createSampleActivity(memberName: "Charlie", activityName: "Walk 1", distance: 3.0, type: "Walk"),
            createSampleActivity(memberName: "Bob", activityName: "Ride 2", distance: 15.0, type: "Ride")
        ]
    }
    
    static func createActivitiesWithDateRange(
        memberName: String = "Test User",
        count: Int = 5,
        startDate: Date = Date(),
        dayInterval: Int = 1
    ) -> [Activity] {
        (0..<count).map { index in
            createSampleActivity(
                memberName: memberName,
                activityName: "Activity \(index + 1)",
                distance: Double.random(in: 5.0...20.0),
                date: startDate.addingTimeInterval(Double(-index * dayInterval * 86400)),
                type: ["Run", "Ride", "Walk"].randomElement()!
            )
        }
    }
    
    // MARK: Edge Case Data
    
    static var activityWithZeroValues: Activity {
        createSampleActivity(
            memberName: "Resting",
            activityName: "Rest Day",
            distance: 0.0,
            averageSpeed: 0.0,
            elevationGain: 0.0,
            movingTime: 0
        )
    }
    
    static var activityWithExtremeValues: Activity {
        createSampleActivity(
            memberName: "Ultra Athlete",
            activityName: "Ultra Marathon",
            distance: 250.0,
            averageSpeed: 8.0,
            elevationGain: 5000.0,
            movingTime: 112500 // ~31 hours
        )
    }
    
    static var activityWithSpecialCharacters: Activity {
        createSampleActivity(
            memberName: "José García-López 🏃‍♂️",
            activityName: "🌅 Morning Run @ Park #fitness 💪",
            distance: 5.0
        )
    }
    
    static var activityWithNegativeElevation: Activity {
        createSampleActivity(
            memberName: "Downhill Runner",
            activityName: "Descent",
            distance: 10.0,
            elevationGain: -200.0
        )
    }
    
    // MARK: Member Stats
    
    static func createMemberStats(
        memberName: String = "Test Member",
        activityCount: Int = 3,
        previousWeekActivityCount: Int = 0
    ) -> MemberStats {
        let currentWeekActivities = (0..<activityCount).map { index in
            createSampleActivity(
                memberName: memberName,
                activityName: "Current Week Activity \(index + 1)",
                distance: Double.random(in: 5.0...20.0)
            )
        }
        
        let previousWeekActivities = (0..<previousWeekActivityCount).map { index in
            createSampleActivity(
                memberName: memberName,
                activityName: "Previous Week Activity \(index + 1)",
                distance: Double.random(in: 5.0...20.0),
                date: Date().addingTimeInterval(-604800) // 1 week ago
            )
        }
        
        return MemberStats(
            memberName: memberName,
            activities: currentWeekActivities,
            previousWeekActivities: previousWeekActivities
        )
    }
}

// MARK: - Test Assertions

/// Custom assertions for common test scenarios
enum TestAssertions {
    
    /// Asserts that two Double values are approximately equal (within tolerance)
    static func assertApproximatelyEqual(
        _ value: Double,
        _ expected: Double,
        tolerance: Double = 0.01,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Bool {
        abs(value - expected) < tolerance
    }
    
    /// Asserts that an array is sorted in descending order by a given keypath
    static func assertSortedDescending<T, V: Comparable>(
        _ array: [T],
        by keyPath: KeyPath<T, V>
    ) -> Bool {
        guard array.count > 1 else { return true }
        
        for i in 0..<(array.count - 1) {
            if array[i][keyPath: keyPath] < array[i + 1][keyPath: keyPath] {
                return false
            }
        }
        return true
    }
    
    /// Asserts that an array is sorted in ascending order by a given keypath
    static func assertSortedAscending<T, V: Comparable>(
        _ array: [T],
        by keyPath: KeyPath<T, V>
    ) -> Bool {
        guard array.count > 1 else { return true }
        
        for i in 0..<(array.count - 1) {
            if array[i][keyPath: keyPath] > array[i + 1][keyPath: keyPath] {
                return false
            }
        }
        return true
    }
}

// MARK: - Test Utilities

enum TestUtilities {
    
    /// Creates a fixed date for consistent testing
    static var fixedDate: Date {
        // February 21, 2026, 12:00 PM UTC
        Date(timeIntervalSince1970: 1771689600)
    }
    
    /// Creates a date relative to the fixed date
    static func dateRelativeToFixed(daysOffset: Int = 0, hoursOffset: Int = 0) -> Date {
        fixedDate
            .addingTimeInterval(Double(daysOffset * 86400))
            .addingTimeInterval(Double(hoursOffset * 3600))
    }
    
    /// Formats duration in seconds to readable string
    static func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
    
    /// Calculates percentage change between two values
    static func percentageChange(from old: Double, to new: Double) -> Double {
        guard old != 0 else { return 0 }
        return ((new - old) / old) * 100
    }
}

// MARK: - Mock Data Generators

enum MockDataGenerator {
    
    /// Generates a large dataset of activities for performance testing
    static func generateLargeActivityDataset(
        memberCount: Int = 50,
        activitiesPerMember: Int = 20
    ) -> [Activity] {
        var activities: [Activity] = []
        
        for memberIndex in 0..<memberCount {
            let memberName = "Member \(memberIndex + 1)"
            
            for activityIndex in 0..<activitiesPerMember {
                activities.append(
                    TestDataFactory.createSampleActivity(
                        memberName: memberName,
                        activityName: "Activity \(activityIndex + 1)",
                        distance: Double.random(in: 1.0...50.0),
                        date: Date().addingTimeInterval(Double(-activityIndex * 3600)),
                        averageSpeed: Double.random(in: 8.0...25.0),
                        elevationGain: Double.random(in: 0.0...500.0),
                        movingTime: Int.random(in: 600...10800),
                        type: ["Run", "Ride", "Walk", "Swim"].randomElement()!
                    )
                )
            }
        }
        
        return activities
    }
    
    /// Generates activities for a specific week
    static func generateWeekOfActivities(
        memberName: String = "Test User",
        weekStartDate: Date = Date()
    ) -> [Activity] {
        // Generate 3-7 random activities throughout the week
        let activityCount = Int.random(in: 3...7)
        
        return (0..<activityCount).map { index in
            TestDataFactory.createSampleActivity(
                memberName: memberName,
                activityName: "Week Activity \(index + 1)",
                distance: Double.random(in: 5.0...25.0),
                date: weekStartDate.addingTimeInterval(Double.random(in: 0...604800)),
                averageSpeed: Double.random(in: 10.0...20.0),
                elevationGain: Double.random(in: 0.0...300.0),
                movingTime: Int.random(in: 1800...7200),
                type: ["Run", "Ride"].randomElement()!
            )
        }
    }
}

// MARK: - Test Configuration

/// Global test configuration and constants
enum TestConfig {
    static let defaultTestTimeout: Duration = .seconds(5)
    static let performanceTestTimeout: Duration = .seconds(30)
    static let networkTestTimeout: Duration = .seconds(10)
    
    static let sampleClubID = "12345"
    static let sampleAccessToken = "test_access_token_123456"
    
    // Test user names
    static let testUserNames = [
        "Alice Johnson",
        "Bob Smith",
        "Charlie Brown",
        "Diana Prince",
        "Evan Williams"
    ]
    
    // Activity types
    static let activityTypes = ["Run", "Ride", "Walk", "Swim", "Other"]
}

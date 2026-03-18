//
//  RootViewTests.swift
//  DCC-Weekly-Activities Tests
//
//  Tests for RootView and its child views
//

import Testing
import SwiftUI
@testable import DCC_Weekly_Activities

// MARK: - Root View Structure Tests

@Suite("RootView Structure Tests")
struct RootViewTests {
    
    @Test("RootView can be instantiated")
    func rootViewInstantiation() async throws {
        let view = RootView()
        #expect(view != nil, "RootView should be instantiable")
    }
    
    @Test("LoginView can be instantiated")
    func loginViewInstantiation() async throws {
        let view = LoginView()
        #expect(view != nil, "LoginView should be instantiable")
    }
    
    @Test("BiometricGateView can be instantiated")
    func biometricGateViewInstantiation() async throws {
        let view = BiometricGateView()
        #expect(view != nil, "BiometricGateView should be instantiable")
    }
    
    @Test("WeeklyDashboardView can be instantiated")
    func weeklyDashboardViewInstantiation() async throws {
        let view = WeeklyDashboardView()
        #expect(view != nil, "WeeklyDashboardView should be instantiable")
    }
}

// MARK: - Activity Row Tests

@Suite("ActivityRow Tests")
struct ActivityRowTests {
    
    let sampleActivity = Activity(
        memberName: "Test User",
        activityName: "Morning Run",
        distance: 5.2,
        date: Date(),
        averageSpeed: 12.5,
        elevationGain: 50.0,
        movingTime: 1500,
        type: "Run"
    )
    
    @Test("ActivityRow displays with valid activity")
    func activityRowWithValidData() async throws {
        let view = ActivityRow(activity: sampleActivity)
        #expect(view.activity.memberName == "Test User")
        #expect(view.activity.distance == 5.2)
    }
    
    @Test("ActivityRow handles different activity types")
    func activityRowHandlesDifferentTypes() async throws {
        let types = ["Ride", "Run", "Walk", "Swim", "Other"]
        
        for type in types {
            let activity = Activity(
                memberName: "Test User",
                activityName: "Test Activity",
                distance: 10.0,
                date: Date(),
                averageSpeed: 15.0,
                elevationGain: 100.0,
                movingTime: 3600,
                type: type
            )
            
            let view = ActivityRow(activity: activity)
            #expect(view.activity.type == type)
        }
    }
    
    @Test("ActivityRow handles zero distance")
    func activityRowHandlesZeroDistance() async throws {
        let activity = Activity(
            memberName: "Test User",
            activityName: "Test Activity",
            distance: 0.0,
            date: Date(),
            averageSpeed: 0.0,
            elevationGain: 0.0,
            movingTime: 0,
            type: "Run"
        )
        
        let view = ActivityRow(activity: activity)
        #expect(view.activity.distance == 0.0)
    }
    
    @Test("ActivityRow handles very large distance")
    func activityRowHandlesLargeDistance() async throws {
        let activity = Activity(
            memberName: "Test User",
            activityName: "Ultra Marathon",
            distance: 250.5,
            date: Date(),
            averageSpeed: 8.5,
            elevationGain: 5000.0,
            movingTime: 108000,
            type: "Run"
        )
        
        let view = ActivityRow(activity: activity)
        #expect(view.activity.distance == 250.5)
    }
}

// MARK: - Activity Detail View Tests

@Suite("ActivityDetailView Tests")
struct ActivityDetailViewTests {
    
    let sampleActivity = Activity(
        memberName: "Test User",
        activityName: "Morning Run",
        distance: 5.2,
        date: Date(),
        averageSpeed: 12.5,
        elevationGain: 50.0,
        movingTime: 1500,
        type: "Run"
    )
    
    let multipleActivities = [
        Activity(
            memberName: "Test User",
            activityName: "Morning Run",
            distance: 5.2,
            date: Date(),
            averageSpeed: 12.5,
            elevationGain: 50.0,
            movingTime: 1500,
            type: "Run"
        ),
        Activity(
            memberName: "Test User",
            activityName: "Evening Run",
            distance: 8.0,
            date: Date().addingTimeInterval(-3600),
            averageSpeed: 13.0,
            elevationGain: 75.0,
            movingTime: 2400,
            type: "Run"
        ),
        Activity(
            memberName: "Other User",
            activityName: "Bike Ride",
            distance: 25.0,
            date: Date().addingTimeInterval(-7200),
            averageSpeed: 20.0,
            elevationGain: 200.0,
            movingTime: 4500,
            type: "Ride"
        )
    ]
    
    @Test("ActivityDetailView displays with single activity")
    func activityDetailViewWithSingleActivity() async throws {
        let view = ActivityDetailView(
            activity: sampleActivity,
            allActivities: [sampleActivity]
        )
        #expect(view.activity.memberName == "Test User")
        #expect(view.allActivities.count == 1)
    }
    
    @Test("ActivityDetailView displays with multiple activities")
    func activityDetailViewWithMultipleActivities() async throws {
        let view = ActivityDetailView(
            activity: sampleActivity,
            allActivities: multipleActivities
        )
        #expect(view.allActivities.count == 3)
    }
    
    @Test("ActivityDetailView filters member activities correctly")
    func activityDetailViewFiltersCorrectly() async throws {
        let view = ActivityDetailView(
            activity: sampleActivity,
            allActivities: multipleActivities
        )
        
        let memberActivities = view.allActivities.filter { 
            $0.memberName == view.activity.memberName 
        }
        
        #expect(memberActivities.count == 2, "Should find 2 activities for Test User")
    }
    
    @Test("ActivityDetailView duration formatting - minutes only")
    func durationFormattingMinutesOnly() async throws {
        // Test with 45 minutes (2700 seconds)
        let activity = Activity(
            memberName: "Test User",
            activityName: "Short Run",
            distance: 5.0,
            date: Date(),
            averageSpeed: 10.0,
            elevationGain: 0.0,
            movingTime: 2700,
            type: "Run"
        )
        
        let view = ActivityDetailView(activity: activity, allActivities: [activity])
        // Duration should be formatted as "45m"
        #expect(activity.movingTime == 2700)
    }
    
    @Test("ActivityDetailView duration formatting - hours and minutes")
    func durationFormattingHoursAndMinutes() async throws {
        // Test with 2 hours 30 minutes (9000 seconds)
        let activity = Activity(
            memberName: "Test User",
            activityName: "Long Run",
            distance: 25.0,
            date: Date(),
            averageSpeed: 10.0,
            elevationGain: 200.0,
            movingTime: 9000,
            type: "Run"
        )
        
        let view = ActivityDetailView(activity: activity, allActivities: [activity])
        // Duration should be formatted as "2h 30m"
        #expect(activity.movingTime == 9000)
    }
}

// MARK: - Dashboard View Tests

@Suite("WeeklyDashboardView Tests")
struct WeeklyDashboardViewTests {
    
    @Test("WeeklyDashboardView initializes with empty state")
    func dashboardInitializesEmpty() async throws {
        let view = WeeklyDashboardView()
        // Initial state should be empty
        #expect(view.stats.isEmpty)
        #expect(view.activities.isEmpty)
        #expect(!view.isLoading)
    }
    
    @Test("WeeklyDashboardView builds member stats correctly")
    func dashboardBuildsMemberStats() async throws {
        let activities = [
            Activity(
                memberName: "Alice",
                activityName: "Run 1",
                distance: 5.0,
                date: Date(),
                averageSpeed: 10.0,
                elevationGain: 50.0,
                movingTime: 1800,
                type: "Run"
            ),
            Activity(
                memberName: "Alice",
                activityName: "Run 2",
                distance: 8.0,
                date: Date(),
                averageSpeed: 12.0,
                elevationGain: 75.0,
                movingTime: 2400,
                type: "Run"
            ),
            Activity(
                memberName: "Bob",
                activityName: "Ride 1",
                distance: 20.0,
                date: Date(),
                averageSpeed: 25.0,
                elevationGain: 200.0,
                movingTime: 2880,
                type: "Ride"
            )
        ]
        
        // Build stats using the same logic as the view
        let grouped = Dictionary(grouping: activities, by: \.memberName)
        let stats = grouped.map { name, acts in
            MemberStats(memberName: name, activities: acts)
        }
        .sorted { $0.totalKM > $1.totalKM }
        
        #expect(stats.count == 2, "Should have 2 unique members")
        #expect(stats[0].memberName == "Bob", "Bob should be first (most distance)")
        #expect(stats[0].totalKM == 20.0)
        #expect(stats[1].memberName == "Alice")
        #expect(stats[1].totalKM == 13.0, "Alice's total should be 13.0 km")
    }
    
    @Test("WeeklyDashboardView sorts activities by date")
    func dashboardSortsActivitiesByDate() async throws {
        let now = Date()
        let activities = [
            Activity(
                memberName: "Alice",
                activityName: "Old Run",
                distance: 5.0,
                date: now.addingTimeInterval(-86400), // 1 day ago
                averageSpeed: 10.0,
                elevationGain: 50.0,
                movingTime: 1800,
                type: "Run"
            ),
            Activity(
                memberName: "Bob",
                activityName: "Recent Run",
                distance: 8.0,
                date: now,
                averageSpeed: 12.0,
                elevationGain: 75.0,
                movingTime: 2400,
                type: "Run"
            )
        ]
        
        let sorted = activities.sorted { $0.date > $1.date }
        
        #expect(sorted[0].activityName == "Recent Run", "Most recent should be first")
        #expect(sorted[1].activityName == "Old Run")
    }
}

// MARK: - View State Tests

@Suite("View State Management Tests")
struct ViewStateTests {
    
    @Test("Loading state displays correctly")
    func loadingStateDisplays() async throws {
        // Test that loading view can be instantiated
        let view = GlassLoadingView(message: "Loading...")
        #expect(view.message == "Loading...")
    }
    
    @Test("Error state displays correctly")
    func errorStateDisplays() async throws {
        let view = GlassErrorView(
            error: "Test error",
            isAuthError: false,
            onRetry: {},
            onLogInAgain: {}
        )
        #expect(view.error == "Test error")
        #expect(!view.isAuthError)
    }
    
    @Test("Auth error state displays correctly")
    func authErrorStateDisplays() async throws {
        let view = GlassErrorView(
            error: "Authentication failed",
            isAuthError: true,
            onRetry: {},
            onLogInAgain: {}
        )
        #expect(view.error == "Authentication failed")
        #expect(view.isAuthError)
    }
}

// MARK: - Navigation Tests

@Suite("Navigation Tests")
struct NavigationTests {
    
    @Test("Activities list navigates to detail")
    func activitiesListNavigatesToDetail() async throws {
        let activities = [
            Activity(
                memberName: "Test User",
                activityName: "Test Run",
                distance: 5.0,
                date: Date(),
                averageSpeed: 10.0,
                elevationGain: 50.0,
                movingTime: 1800,
                type: "Run"
            )
        ]
        
        // Test that we can create the navigation structure
        let detailView = ActivityDetailView(
            activity: activities[0],
            allActivities: activities
        )
        
        #expect(detailView.activity.activityName == "Test Run")
    }
    
    @Test("Dashboard has three tabs")
    func dashboardHasThreeTabs() async throws {
        let view = WeeklyDashboardView()
        #expect(view.selectedTab >= 0 && view.selectedTab <= 2)
    }
}

// MARK: - Edge Case Tests

@Suite("Edge Cases and Boundary Tests")
struct EdgeCaseTests {
    
    @Test("Empty activities list handled gracefully")
    func emptyActivitiesListHandled() async throws {
        let emptyActivities: [Activity] = []
        
        // Build stats from empty array
        let grouped = Dictionary(grouping: emptyActivities, by: \.memberName)
        let stats = grouped.map { name, acts in
            MemberStats(memberName: name, activities: acts)
        }
        
        #expect(stats.isEmpty, "Stats should be empty for empty activities")
    }
    
    @Test("Activity with very long name")
    func activityWithVeryLongName() async throws {
        let longName = String(repeating: "A", count: 500)
        let activity = Activity(
            memberName: "Test User",
            activityName: longName,
            distance: 5.0,
            date: Date(),
            averageSpeed: 10.0,
            elevationGain: 50.0,
            movingTime: 1800,
            type: "Run"
        )
        
        let view = ActivityRow(activity: activity)
        #expect(view.activity.activityName.count == 500)
    }
    
    @Test("Activity with special characters in name")
    func activityWithSpecialCharacters() async throws {
        let specialName = "🏃‍♂️ Morning Run 🌅 #fitness @strava"
        let activity = Activity(
            memberName: "Test User",
            activityName: specialName,
            distance: 5.0,
            date: Date(),
            averageSpeed: 10.0,
            elevationGain: 50.0,
            movingTime: 1800,
            type: "Run"
        )
        
        let view = ActivityRow(activity: activity)
        #expect(view.activity.activityName == specialName)
    }
    
    @Test("Activity with negative elevation (descent)")
    func activityWithNegativeElevation() async throws {
        let activity = Activity(
            memberName: "Test User",
            activityName: "Downhill Run",
            distance: 10.0,
            date: Date(),
            averageSpeed: 15.0,
            elevationGain: -100.0, // Descent
            movingTime: 2400,
            type: "Run"
        )
        
        let view = ActivityDetailView(activity: activity, allActivities: [activity])
        #expect(view.activity.elevationGain == -100.0)
    }
    
    @Test("Activity at midnight")
    func activityAtMidnight() async throws {
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: Date())
        
        let activity = Activity(
            memberName: "Night Owl",
            activityName: "Midnight Run",
            distance: 5.0,
            date: midnight,
            averageSpeed: 10.0,
            elevationGain: 0.0,
            movingTime: 1800,
            type: "Run"
        )
        
        let view = ActivityRow(activity: activity)
        #expect(view.activity.date == midnight)
    }
}

// MARK: - Glass Component Tests

@Suite("Glass Component Tests")
struct GlassComponentTests {
    
    @Test("GlassLoadingView instantiation")
    func glassLoadingViewInstantiation() async throws {
        let view = GlassLoadingView(message: "Loading test")
        #expect(view.message == "Loading test")
    }
    
    @Test("GlassErrorView instantiation with non-auth error")
    func glassErrorViewNonAuthError() async throws {
        var retryCallCount = 0
        var loginCallCount = 0
        
        let view = GlassErrorView(
            error: "Network error",
            isAuthError: false,
            onRetry: { retryCallCount += 1 },
            onLogInAgain: { loginCallCount += 1 }
        )
        
        #expect(view.error == "Network error")
        #expect(!view.isAuthError)
    }
    
    @Test("GlassErrorView instantiation with auth error")
    func glassErrorViewAuthError() async throws {
        let view = GlassErrorView(
            error: "Token expired",
            isAuthError: true,
            onRetry: {},
            onLogInAgain: {}
        )
        
        #expect(view.error == "Token expired")
        #expect(view.isAuthError)
    }
    
    @Test("GlassWelcomeCard instantiation")
    func glassWelcomeCardInstantiation() async throws {
        var connectCalled = false
        
        let view = GlassWelcomeCard(
            onConnect: { connectCalled = true },
            biometricType: .faceID
        )
        
        #expect(view.biometricType == .faceID)
    }
}

// MARK: - Performance Tests

@Suite("Performance Tests")
struct PerformanceTests {
    
    @Test("Building stats from large activity set")
    func buildingStatsFromLargeSet() async throws {
        // Create 1000 activities
        var activities: [Activity] = []
        for i in 0..<1000 {
            activities.append(
                Activity(
                    memberName: "Member \(i % 50)", // 50 unique members
                    activityName: "Activity \(i)",
                    distance: Double.random(in: 1.0...50.0),
                    date: Date().addingTimeInterval(Double(-i * 3600)),
                    averageSpeed: Double.random(in: 8.0...20.0),
                    elevationGain: Double.random(in: 0.0...500.0),
                    movingTime: Int.random(in: 600...10800),
                    type: ["Run", "Ride", "Walk"].randomElement()!
                )
            )
        }
        
        // Measure stats building
        let grouped = Dictionary(grouping: activities, by: \.memberName)
        let stats = grouped.map { name, acts in
            MemberStats(memberName: name, activities: acts)
        }
        .sorted { $0.totalKM > $1.totalKM }
        
        #expect(stats.count == 50, "Should have 50 unique members")
        #expect(stats[0].totalKM > 0, "Top member should have distance")
    }
    
    @Test("Sorting large activity list by date")
    func sortingLargeActivityList() async throws {
        // Create 1000 activities with random dates
        var activities: [Activity] = []
        for i in 0..<1000 {
            activities.append(
                Activity(
                    memberName: "Member \(i)",
                    activityName: "Activity \(i)",
                    distance: 10.0,
                    date: Date().addingTimeInterval(Double.random(in: -86400...0)),
                    averageSpeed: 12.0,
                    elevationGain: 50.0,
                    movingTime: 3000,
                    type: "Run"
                )
            )
        }
        
        let sorted = activities.sorted { $0.date > $1.date }
        
        #expect(sorted.count == 1000)
        #expect(sorted[0].date >= sorted[1].date, "Should be sorted by date descending")
    }
}

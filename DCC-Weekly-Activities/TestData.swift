//
//  TestData.swift
//  DCC-Weekly-Activities
//
//  Mock data for testing, especially useful for tvOS simulator
//

import Foundation

#if DEBUG
struct TestData {
    /// Set this to `true` to enable mock data for tvOS testing
    static var useMockData = false
    
    static var mockActivities: [Activity] {
        let calendar = Calendar.current
        let now = Date()
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now)!
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: now)!
        let sixDaysAgo = calendar.date(byAdding: .day, value: -6, to: now)!
        
        return [
            // Amit K - Top performer
            Activity(
                memberName: "Amit K",
                activityName: "Morning Ride",
                distance: 45.2,
                date: threeDaysAgo,
                averageSpeed: 28.5,
                elevationGain: 320,
                movingTime: 5700
            ),
            Activity(
                memberName: "Amit K",
                activityName: "Evening Loop",
                distance: 38.7,
                date: fiveDaysAgo,
                averageSpeed: 26.3,
                elevationGain: 180,
                movingTime: 5280
            ),
            Activity(
                memberName: "Amit K",
                activityName: "Weekend Long Ride",
                distance: 62.5,
                date: sixDaysAgo,
                averageSpeed: 27.8,
                elevationGain: 450,
                movingTime: 8100
            ),
            
            // Priya S
            Activity(
                memberName: "Priya S",
                activityName: "Hill Training",
                distance: 32.4,
                date: threeDaysAgo,
                averageSpeed: 24.2,
                elevationGain: 520,
                movingTime: 4800
            ),
            Activity(
                memberName: "Priya S",
                activityName: "Recovery Ride",
                distance: 25.6,
                date: fiveDaysAgo,
                averageSpeed: 22.0,
                elevationGain: 120,
                movingTime: 4200
            ),
            
            // Raj M
            Activity(
                memberName: "Raj M",
                activityName: "Commute to Work",
                distance: 18.3,
                date: threeDaysAgo,
                averageSpeed: 23.5,
                elevationGain: 85,
                movingTime: 2800
            ),
            Activity(
                memberName: "Raj M",
                activityName: "Lunch Ride",
                distance: 22.1,
                date: fiveDaysAgo,
                averageSpeed: 25.1,
                elevationGain: 140,
                movingTime: 3180
            ),
            Activity(
                memberName: "Raj M",
                activityName: "Evening Cruise",
                distance: 28.9,
                date: sixDaysAgo,
                averageSpeed: 24.8,
                elevationGain: 95,
                movingTime: 4200
            ),
            
            // Neha D
            Activity(
                memberName: "Neha D",
                activityName: "Park Loop",
                distance: 35.2,
                date: threeDaysAgo,
                averageSpeed: 26.7,
                elevationGain: 210,
                movingTime: 4740
            ),
            Activity(
                memberName: "Neha D",
                activityName: "Lakeside Ride",
                distance: 41.8,
                date: sixDaysAgo,
                averageSpeed: 27.2,
                elevationGain: 165,
                movingTime: 5520
            ),
            
            // Vikram B
            Activity(
                memberName: "Vikram B",
                activityName: "Speed Training",
                distance: 30.5,
                date: fiveDaysAgo,
                averageSpeed: 29.3,
                elevationGain: 90,
                movingTime: 3750
            ),
            
            // Anita P
            Activity(
                memberName: "Anita P",
                activityName: "Group Ride",
                distance: 48.6,
                date: threeDaysAgo,
                averageSpeed: 25.9,
                elevationGain: 380,
                movingTime: 6750
            ),
            Activity(
                memberName: "Anita P",
                activityName: "Solo Adventure",
                distance: 55.3,
                date: sixDaysAgo,
                averageSpeed: 26.5,
                elevationGain: 420,
                movingTime: 7500
            ),
            
            // Karan L
            Activity(
                memberName: "Karan L",
                activityName: "Mountain Route",
                distance: 42.1,
                date: fiveDaysAgo,
                averageSpeed: 21.8,
                elevationGain: 680,
                movingTime: 6960
            ),
            
            // Simran K
            Activity(
                memberName: "Simran K",
                activityName: "Coastal Ride",
                distance: 38.4,
                date: threeDaysAgo,
                averageSpeed: 27.1,
                elevationGain: 155,
                movingTime: 5100
            )
        ]
    }
}
#endif

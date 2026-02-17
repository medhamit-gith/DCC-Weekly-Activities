//
//  Models.swift
//  DCC-Weekly-Activities
//
//  Shared data models for Activity and MemberStats
//

import Foundation

// MARK: - Activity Model
struct Activity: Identifiable {
    let id: UUID
    let memberName: String
    let activityName: String
    let distance: Double // in km
    let date: Date
    let averageSpeed: Double // in km/h
    let elevationGain: Double // in meters
    let movingTime: Int // in seconds
    let type: String
    
    init(
        id: UUID = UUID(),
        memberName: String,
        activityName: String,
        distance: Double,
        date: Date,
        averageSpeed: Double,
        elevationGain: Double,
        movingTime: Int,
        type: String = "Ride"
    ) {
        self.id = id
        self.memberName = memberName
        self.activityName = activityName
        self.distance = distance
        self.date = date
        self.averageSpeed = averageSpeed
        self.elevationGain = elevationGain
        self.movingTime = movingTime
        self.type = type
    }
}

// MARK: - MemberStats Model
struct MemberStats: Identifiable {
    let id: UUID
    let memberName: String
    let activities: [Activity]
    
    // Computed properties
    var totalKM: Double {
        activities.reduce(0.0) { $0 + $1.distance }
    }
    
    var totalRides: Int {
        activities.count
    }
    
    var totalElevation: Double {
        activities.reduce(0.0) { $0 + $1.elevationGain }
    }
    
    var avgSpeed: Double {
        guard !activities.isEmpty else { return 0.0 }
        let sum = activities.reduce(0.0) { $0 + $1.averageSpeed }
        return sum / Double(activities.count)
    }
    
    var totalMovingTime: Int {
        activities.reduce(0) { $0 + $1.movingTime }
    }
    
    // For trend indication (placeholder - would need historical data)
    var trendEmoji: String {
        // Could compare to previous week's data when available
        return "📈" // For now, always show upward trend
    }
    
    init(memberName: String, activities: [Activity]) {
        self.id = UUID()
        self.memberName = memberName
        self.activities = activities
    }
}

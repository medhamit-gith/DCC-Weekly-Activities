//
//  MemberStats.swift
//  DCC-Weekly-Activities
//
//  Aggregate statistics per member
//

import Foundation

struct MemberStats: Identifiable, Sendable {
    let id = UUID()
    let memberName: String
    let totalRides: Int
    let totalKM: Double
    let avgSpeed: Double
    let totalElevation: Double
    let currentWeekTrend: TrendDirection
    let rides: [Activity] // Individual rides for this member
    
    enum TrendDirection: String, Codable {
        case up = "↑"
        case down = "↓"
        case stable = "→"
        case new = "★"
    }
    
    init(memberName: String, activities: [Activity], previousWeekActivities: [Activity] = []) {
        self.memberName = memberName
        self.rides = activities.sorted { $0.date > $1.date }
        self.totalRides = activities.count
        self.totalKM = activities.reduce(0) { $0 + $1.distance }
        self.avgSpeed = activities.isEmpty ? 0 : activities.reduce(0) { $0 + $1.averageSpeed } / Double(activities.count)
        self.totalElevation = activities.reduce(0) { $0 + $1.elevationGain }
        
        // Calculate trend based on previous week comparison
        let previousTotal = previousWeekActivities.reduce(0.0) { $0 + $1.distance }
        if previousWeekActivities.isEmpty && !activities.isEmpty {
            self.currentWeekTrend = .new
        } else if previousTotal == 0 {
            self.currentWeekTrend = .stable
        } else {
            let percentChange = ((totalKM - previousTotal) / previousTotal) * 100
            if percentChange > 10 {
                self.currentWeekTrend = .up
            } else if percentChange < -10 {
                self.currentWeekTrend = .down
            } else {
                self.currentWeekTrend = .stable
            }
        }
    }
    
    /// Convenience method to get formatted trend with color
    var trendEmoji: String {
        currentWeekTrend.rawValue
    }
}

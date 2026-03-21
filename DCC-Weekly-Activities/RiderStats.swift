//
//  RiderStats.swift
//  DCC-Weekly-Activities
//
//  Rich aggregate statistics per rider for deep analytics, radar charts, and what-if scenarios.
//  This model decodes EVERY available field from Strava's club activities endpoint.
//

import Foundation

struct RiderStats: Identifiable {
    let id: String               // Composite: firstname_lastname
    let displayName: String      // "Amit K."
    let firstname: String
    let lastname: String
    let activities: [Activity]   // ALL raw activities for this rider
    
    // MARK: - Distance Metrics
    
    var totalDistanceKm: Double {
        activities.map(\.distance).reduce(0, +).safeValue
    }
    
    var averageDistanceKm: Double {
        guard !activities.isEmpty else { return 0 }
        return (totalDistanceKm / Double(activities.count)).safeValue
    }
    
    var longestRideKm: Double {
        (activities.map(\.distance).max() ?? 0).safeValue
    }
    
    var shortestRideKm: Double {
        (activities.map(\.distance).min() ?? 0).safeValue
    }
    
    var distanceVariance: Double {
        guard !activities.isEmpty else { return 0 }
        let mean = averageDistanceKm
        let squaredDiffs = activities.map { pow($0.distance - mean, 2).safeValue }
        return (squaredDiffs.reduce(0, +) / Double(max(activities.count, 1))).safeValue
    }
    
    // MARK: - Speed Metrics
    
    var averageSpeedKmh: Double {
        guard !activities.isEmpty else { return 0 }
        return (activities.map(\.averageSpeed).reduce(0, +) / Double(activities.count)).safeValue
    }
    
    var maxSpeedKmh: Double {
        (activities.map(\.averageSpeed).max() ?? 0).safeValue
    }
    
    var speedConsistency: Double {
        guard !activities.isEmpty else { return 0 }
        // Lower variance = more consistent speed
        // Return standard deviation in km/h
        let mean = averageSpeedKmh
        let variance = activities.map { pow($0.averageSpeed - mean, 2).safeValue }
            .reduce(0, +) / Double(max(activities.count, 1))
        return sqrt(variance.safeValue).safeValue
    }
    
    // MARK: - Elevation Metrics
    
    var totalElevationM: Double {
        activities.map(\.elevationGain).reduce(0, +).safeValue
    }
    
    var averageElevationPerRide: Double {
        guard !activities.isEmpty else { return 0 }
        return (totalElevationM / Double(activities.count)).safeValue
    }
    
    var averageElevationPerKm: Double {
        guard totalDistanceKm > 0 else { return 0 }
        return (totalElevationM / totalDistanceKm).safeValue
    }
    
    /// Climbing focus metric: m/km — higher = mountain rider
    var climbingFocus: Double {
        averageElevationPerKm
    }
    
    // MARK: - Time Metrics
    
    var totalMovingTimeHours: Double {
        let totalSeconds = activities.map(\.movingTime).reduce(0, +)
        return (Double(totalSeconds) / 3600.0).safeValue
    }
    
    var averageRideDurationMinutes: Double {
        guard !activities.isEmpty else { return 0 }
        let totalMinutes = activities.map { Double($0.movingTime) / 60.0 }.reduce(0, +)
        return (totalMinutes / Double(activities.count)).safeValue
    }
    
    // MARK: - Ride Count and Categorization
    
    var rideCount: Int {
        activities.count
    }
    
    var virtualRideCount: Int {
        activities.filter { $0.type.lowercased().contains("virtual") }.count
    }
    
    var ebikeCount: Int {
        activities.filter { $0.type.lowercased().contains("ebike") }.count
    }
    
    var gravelCount: Int {
        activities.filter { $0.type.lowercased().contains("gravel") }.count
    }
    
    var mtbCount: Int {
        activities.filter { $0.type.lowercased().contains("mountain") }.count
    }
    
    /// Sport type breakdown for pie chart
    var sportTypeBreakdown: [String: Int] {
        Dictionary(grouping: activities, by: \.type)
            .mapValues(\.count)
    }
    
    // MARK: - Performance Scores (0.0–1.0 normalized within club)
    // These are computed by InsightsViewModel after normalization
    var normalizedDistance: Double = 0
    var normalizedSpeed: Double = 0
    var normalizedElevation: Double = 0
    var normalizedConsistency: Double = 0
    var normalizedEfficiency: Double = 0
    
    // MARK: - Overall Efficiency
    
    /// Speed-to-elevation ratio — higher = faster per metre climbed
    /// Efficiency score separates fit riders from simply high-volume riders
    var averageEfficiencyScore: Double {
        guard !activities.isEmpty else { return 0 }
        let scores = activities.map { activity -> Double in
            guard activity.elevationGain > 0 else { return activity.averageSpeed }
            return (activity.averageSpeed / (activity.elevationGain / 100.0)).safeValue
        }
        return (scores.reduce(0, +) / Double(activities.count)).safeValue
    }
    
    // MARK: - What-If Helpers
    
    /// Projects total distance if rider completes N extra rides at their average distance
    func projectedDistanceWith(extraRides: Int) -> Double {
        (totalDistanceKm + (Double(extraRides) * averageDistanceKm)).safeValue
    }
    
    /// Distance gap to close to match leader
    func distanceGapTo(leader: RiderStats) -> Double {
        max(0, leader.totalDistanceKm - totalDistanceKm).safeValue
    }
    
    /// Number of rides needed (at current average distance) to match leader's total distance
    func ridesNeededToMatch(leader: RiderStats) -> Int {
        guard averageDistanceKm > 0 else { return 0 }
        let gap = distanceGapTo(leader: leader)
        return Int(ceil(gap / averageDistanceKm))
    }
    
    /// Speed gap to close to match leader's average speed
    func speedGapTo(leader: RiderStats) -> Double {
        max(0, leader.averageSpeedKmh - averageSpeedKmh).safeValue
    }
    
    /// Elevation gap to close to match leader's total elevation
    func elevationGapTo(leader: RiderStats) -> Double {
        max(0, leader.totalElevationM - totalElevationM).safeValue
    }
}

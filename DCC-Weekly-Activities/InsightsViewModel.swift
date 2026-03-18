//
//  InsightsViewModel.swift
//  DCC-Weekly-Activities
//
//  Logic for gap analysis and tip generation
//  Updated 2026-03-02: Added RiderStats support and WhatIfEngine integration
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class InsightsViewModel {
    
    // MARK: - Properties
    
    var selectedRiderName: String?
    var stats: [MemberStats] = []
    var riderStats: [RiderStats] = []  // NEW: Rich analytics model
    
    var selectedRider: MemberStats? {
        guard let name = selectedRiderName else { return nil }
        return stats.first { $0.memberName == name }
    }
    
    var sortedStats: [MemberStats] {
        stats.sorted { $0.totalKM > $1.totalKM }
    }
    
    var leader: MemberStats? {
        sortedStats.first
    }
    
    var leaderStats: RiderStats? {
        riderStats.sorted { $0.totalDistanceKm > $1.totalDistanceKm }.first
    }
    
    // MARK: - Rank Calculation
    
    func rank(for rider: MemberStats) -> Int {
        sortedStats.firstIndex { $0.id == rider.id }.map { $0 + 1 } ?? 0
    }
    
    func rankEmoji(for rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(rank)"
        }
    }
    
    // MARK: - Achievement Analysis
    
    func topAchievement(for rider: MemberStats) -> String {
        let currentRank = rank(for: rider)
        
        // Check if they're #1 in any category
        let isDistanceLeader = rider.id == sortedStats.first?.id
        let isSpeedLeader = rider.id == stats.max(by: { $0.avgSpeed < $1.avgSpeed })?.id
        let isElevationLeader = rider.id == stats.max(by: { $0.totalElevation < $1.totalElevation })?.id
        let isRideCountLeader = rider.id == stats.max(by: { $0.totalRides < $1.totalRides })?.id
        
        if isDistanceLeader {
            return "Most Distance: \(String(format: "%.1f", rider.totalKM))km"
        } else if isSpeedLeader {
            return "Fastest Rider: \(String(format: "%.1f", rider.avgSpeed)) km/h"
        } else if isElevationLeader {
            return "Most Climbing: \(String(format: "%.0f", rider.totalElevation))m"
        } else if isRideCountLeader {
            return "Most Active: \(rider.totalRides) rides"
        } else {
            // Find their best metric relative to the club
            return "Logged \(rider.totalRides) ride\(rider.totalRides == 1 ? "" : "s")"
        }
    }
    
    func motivationalMessage(for rank: Int) -> String {
        switch rank {
        case 1:
            return "You're leading the pack. Defend your crown! 👑"
        case 2...3:
            return "Podium rider! You're so close to the top."
        default:
            return "Every km counts. Here's how to climb higher ↑"
        }
    }
    
    // MARK: - Normalized Values (0-1 scale for radar chart)
    
    func normalizedDistance(for rider: MemberStats) -> Double {
        let max = stats.map(\.totalKM).max() ?? 1
        return max > 0 ? rider.totalKM / max : 0
    }
    
    func normalizedSpeed(for rider: MemberStats) -> Double {
        let max = stats.map(\.avgSpeed).max() ?? 1
        return max > 0 ? rider.avgSpeed / max : 0
    }
    
    func normalizedElevation(for rider: MemberStats) -> Double {
        let max = stats.map(\.totalElevation).max() ?? 1
        return max > 0 ? rider.totalElevation / max : 0
    }
    
    func normalizedRides(for rider: MemberStats) -> Double {
        let max = Double(stats.map(\.totalRides).max() ?? 1)
        return max > 0 ? Double(rider.totalRides) / max : 0
    }
    
    func normalizedConsistency(for rider: MemberStats) -> Double {
        // Consistency = average distance per ride
        let avgPerRide = rider.totalRides > 0 ? rider.totalKM / Double(rider.totalRides) : 0
        let maxAvg = stats.map { stat in
            stat.totalRides > 0 ? stat.totalKM / Double(stat.totalRides) : 0
        }.max() ?? 1
        return maxAvg > 0 ? avgPerRide / maxAvg : 0
    }
    
    // MARK: - Club Averages
    
    var clubAverageDistance: Double {
        stats.isEmpty ? 0 : stats.reduce(0) { $0 + $1.totalKM } / Double(stats.count)
    }
    
    var clubAverageSpeed: Double {
        stats.isEmpty ? 0 : stats.reduce(0) { $0 + $1.avgSpeed } / Double(stats.count)
    }
    
    var clubAverageElevation: Double {
        stats.isEmpty ? 0 : stats.reduce(0) { $0 + $1.totalElevation } / Double(stats.count)
    }
    
    var clubAverageRides: Double {
        stats.isEmpty ? 0 : Double(stats.reduce(0) { $0 + $1.totalRides }) / Double(stats.count)
    }
    
    var clubAverageConsistency: Double {
        let consistencyValues = stats.map { stat in
            stat.totalRides > 0 ? stat.totalKM / Double(stat.totalRides) : 0.0
        }
        return consistencyValues.isEmpty ? 0 : consistencyValues.reduce(0, +) / Double(consistencyValues.count)
    }
    
    // MARK: - RiderStats Building (NEW)
    
    /// Builds RiderStats from Activities for rich analytics
    func buildRiderStats(from activities: [Activity]) {
        // Group activities by rider (firstname + lastname initial as key)
        let grouped = Dictionary(grouping: activities) { activity in
            activity.memberName
        }
        
        riderStats = grouped.map { memberName, acts in
            // Extract first and last name from "Firstname L." format
            let components = memberName.split(separator: " ")
            let firstname = components.first.map(String.init) ?? memberName
            let lastname = components.dropFirst().joined(separator: " ")
            
            return RiderStats(
                id: memberName.replacingOccurrences(of: " ", with: "_"),
                displayName: memberName,
                firstname: firstname,
                lastname: lastname,
                activities: acts
            )
        }
        .sorted { $0.totalDistanceKm > $1.totalDistanceKm }
        
        normalizeRiderStats()
    }
    
    /// Normalizes all RiderStats metrics to 0-1 scale for radar chart
    private func normalizeRiderStats() {
        guard !riderStats.isEmpty else { return }
        
        let maxDist = riderStats.map(\.totalDistanceKm).max() ?? 1
        let maxSpeed = riderStats.map(\.averageSpeedKmh).max() ?? 1
        let maxElev = riderStats.map(\.totalElevationM).max() ?? 1
        let maxRides = Double(riderStats.map(\.rideCount).max() ?? 1)
        let maxEff = riderStats.map(\.averageEfficiencyScore).max() ?? 1
        
        for i in riderStats.indices {
            riderStats[i].normalizedDistance   = maxDist  > 0 ? riderStats[i].totalDistanceKm / maxDist   : 0
            riderStats[i].normalizedSpeed      = maxSpeed > 0 ? riderStats[i].averageSpeedKmh / maxSpeed   : 0
            riderStats[i].normalizedElevation  = maxElev  > 0 ? riderStats[i].totalElevationM / maxElev    : 0
            riderStats[i].normalizedConsistency = maxRides > 0 ? Double(riderStats[i].rideCount) / maxRides : 0
            riderStats[i].normalizedEfficiency = maxEff   > 0 ? riderStats[i].averageEfficiencyScore / maxEff : 0
        }
    }
    
    // MARK: - Coaching Tips Generation
    
    func generateCoachingTips(for rider: MemberStats) -> [CoachingTip] {
        guard let leader = leader, leader.id != rider.id else {
            // They are the leader
            return [
                CoachingTip(
                    icon: "👑",
                    type: .strength,
                    headline: "Maintain Your Lead",
                    detail: "You're at the top! Keep up the great work to stay ahead.",
                    gapBadge: nil,
                    whatIf: nil
                )
            ]
        }
        
        var tips: [CoachingTip] = []
        
        // Calculate gaps
        let distanceGap = leader.totalKM - rider.totalKM
        let speedGap = leader.avgSpeed - rider.avgSpeed
        let elevationGap = leader.totalElevation - rider.totalElevation
        let rideCountGap = leader.totalRides - rider.totalRides
        
        // Find the largest gap
        let gaps: [(type: String, value: Double, metric: String)] = [
            ("distance", distanceGap, "km"),
            ("speed", speedGap, "km/h"),
            ("elevation", elevationGap, "m"),
            ("rides", Double(rideCountGap), "rides")
        ]
        
        let sortedGaps = gaps.sorted { abs($0.value) > abs($1.value) }
        
        // Generate tip for the biggest gap
        if let primaryGap = sortedGaps.first, primaryGap.value > 0 {
            switch primaryGap.type {
            case "distance":
                tips.append(CoachingTip(
                    icon: "📏",
                    type: .distance,
                    headline: "Close the Distance Gap",
                    detail: "Add one longer ride to close the \(String(format: "%.1f", distanceGap))km gap with \(leader.memberName)",
                    gapBadge: "-\(String(format: "%.1f", distanceGap))km",
                    whatIf: nil
                ))
                
            case "speed":
                tips.append(CoachingTip(
                    icon: "⚡",
                    type: .speed,
                    headline: "Boost Your Pace",
                    detail: "Maintain \(String(format: "%.1f", speedGap)) km/h faster to match \(leader.memberName)'s speed",
                    gapBadge: "-\(String(format: "%.1f", speedGap)) km/h",
                    whatIf: nil
                ))
                
            case "elevation":
                tips.append(CoachingTip(
                    icon: "⛰",
                    type: .elevation,
                    headline: "Target Hillier Routes",
                    detail: "You're \(String(format: "%.0f", elevationGap))m behind \(leader.memberName) on elevation",
                    gapBadge: "-\(String(format: "%.0f", elevationGap))m",
                    whatIf: nil
                ))
                
            case "rides":
                tips.append(CoachingTip(
                    icon: "🗓",
                    type: .consistency,
                    headline: "Ride More Often",
                    detail: "\(leader.memberName) leads with \(leader.totalRides) rides vs your \(rider.totalRides)",
                    gapBadge: "-\(rideCountGap) rides",
                    whatIf: nil
                ))
                
            default:
                break
            }
        }
        
        // Add a secondary tip based on next biggest gap
        if sortedGaps.count > 1 {
            let secondaryGap = sortedGaps[1]
            if secondaryGap.value > 0 {
            switch secondaryGap.type {
            case "distance" where !tips.contains(where: { $0.icon == "📏" }):
                tips.append(CoachingTip(
                    icon: "📏",
                    type: .distance,
                    headline: "Increase Weekly Volume",
                    detail: "One extra \(String(format: "%.0f", distanceGap / Double(max(1, rideCountGap + 1))))km ride would help close the gap",
                    gapBadge: nil,
                    whatIf: nil
                ))
                
            case "rides" where !tips.contains(where: { $0.icon == "🗓" }):
                tips.append(CoachingTip(
                    icon: "🗓",
                    type: .consistency,
                    headline: "Add Consistency",
                    detail: "One extra ride this week moves you up the leaderboard",
                    gapBadge: nil,
                    whatIf: nil
                ))
                
            default:
                break
            }
            }
        }
        
        // If no tips generated, give encouragement
        if tips.isEmpty {
            tips.append(CoachingTip(
                icon: "🚀",
                type: .strength,
                headline: "Keep Pushing!",
                detail: "You're making great progress. Stay consistent!",
                gapBadge: nil,
                whatIf: nil
            ))
        }
        
        return Array(tips.prefix(2))
    }
}

// MARK: - Coaching Tip Model
// NOTE: CoachingTip is now defined in WhatIfEngine.swift with enhanced properties


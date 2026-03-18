//
//  WhatIfEngine.swift
//  DCC-Weekly-Activities
//
//  Powers coaching tips and "what-if" scenario analysis
//

import Foundation
import SwiftUI

struct WhatIfEngine {
    
    // MARK: - Gap Analysis
    
    /// Analyzes performance gaps between rider and leader across all metrics
    static func analyzeGaps(rider: RiderStats, leader: RiderStats, allRiders: [RiderStats]) -> GapAnalysis {
        GapAnalysis(
            distanceGap: rider.distanceGapTo(leader: leader),
            speedGap: rider.speedGapTo(leader: leader),
            elevationGap: rider.elevationGapTo(leader: leader),
            rideCountGap: max(0, leader.rideCount - rider.rideCount),
            ridesNeededToClose: rider.ridesNeededToMatch(leader: leader),
            weakestMetric: weakestMetric(rider: rider, allRiders: allRiders),
            strongestMetric: strongestMetric(rider: rider, allRiders: allRiders),
            clubRank: allRiders.sorted { $0.totalDistanceKm > $1.totalDistanceKm }
                              .firstIndex(where: { $0.id == rider.id })
                              .map { $0 + 1 } ?? 0
        )
    }
    
    // MARK: - What-If Scenarios
    
    /// Projects impact of riding N additional times this week
    static func whatIfExtraRides(_ count: Int, rider: RiderStats) -> WhatIfResult {
        return WhatIfResult(
            scenario: "If you ride \(count) more time\(count == 1 ? "" : "s") this week",
            projectedDistance: rider.projectedDistanceWith(extraRides: count),
            distanceGain: Double(count) * rider.averageDistanceKm,
            newRank: nil  // Computed by ViewModel with full club context
        )
    }
    
    /// Projects impact of increasing average speed by X km/h
    static func whatIfFasterPace(extraKmh: Double, rider: RiderStats) -> WhatIfResult {
        let currentTime = rider.totalMovingTimeHours
        let projectedDistance = ((rider.averageSpeedKmh + extraKmh) * currentTime).safeValue
        return WhatIfResult(
            scenario: "Riding \(String(format: "%.1f", extraKmh)) km/h faster",
            projectedDistance: projectedDistance,
            distanceGain: (projectedDistance - rider.totalDistanceKm).safeValue,
            newRank: nil
        )
    }
    
    /// Projects impact of adding X km to each ride
    static func whatIfLongerRides(extraKmPerRide: Double, rider: RiderStats) -> WhatIfResult {
        let bonusDistance = (Double(rider.rideCount) * extraKmPerRide).safeValue
        return WhatIfResult(
            scenario: "Adding \(Int(extraKmPerRide))km to each ride",
            projectedDistance: (rider.totalDistanceKm + bonusDistance).safeValue,
            distanceGain: bonusDistance,
            newRank: nil
        )
    }
    
    // MARK: - Generate Coaching Tips
    
    /// Generates personalized coaching tips based on gap analysis
    static func generateTips(gap: GapAnalysis, rider: RiderStats, leader: RiderStats) -> [CoachingTip] {
        var tips: [CoachingTip] = []
        
        // Generate tip based on weakest metric
        switch gap.weakestMetric {
        case .distance:
            if gap.ridesNeededToClose <= 2 {
                tips.append(CoachingTip(
                    icon: "📏",
                    type: .distance,
                    headline: "So close! Just \(gap.ridesNeededToClose) more ride\(gap.ridesNeededToClose == 1 ? "" : "s")",
                    detail: "You're \(String(format: "%.1f", gap.distanceGap))km behind \(leader.displayName). One \(String(format: "%.0f", gap.distanceGap + 5))km ride would do it.",
                    gapBadge: "-\(String(format: "%.0f", gap.distanceGap))km",
                    whatIf: whatIfExtraRides(gap.ridesNeededToClose, rider: rider)
                ))
            } else {
                tips.append(CoachingTip(
                    icon: "📏",
                    type: .distance,
                    headline: "Ride more to close the gap",
                    detail: "Add \(String(format: "%.0f", rider.averageDistanceKm))km (your average ride) each extra session to close the \(String(format: "%.0f", gap.distanceGap))km gap to \(leader.displayName).",
                    gapBadge: "-\(String(format: "%.0f", gap.distanceGap))km",
                    whatIf: whatIfExtraRides(1, rider: rider)
                ))
            }
            
        case .speed:
            tips.append(CoachingTip(
                icon: "⚡",
                type: .speed,
                headline: "Push your average pace",
                detail: "You're \(String(format: "%.1f", gap.speedGap))km/h slower than \(leader.displayName). Targeting a faster pace on your next \(String(format: "%.0f", rider.totalMovingTimeHours))hrs of riding would add significant distance.",
                gapBadge: "-\(String(format: "%.1f", gap.speedGap))km/h",
                whatIf: whatIfFasterPace(extraKmh: min(gap.speedGap, 2.0), rider: rider)
            ))
            
        case .elevation:
            tips.append(CoachingTip(
                icon: "⛰",
                type: .elevation,
                headline: "Seek out hillier routes",
                detail: "You're \(String(format: "%.0f", gap.elevationGap))m behind \(leader.displayName) on climbing. Hillier routes also build strength for faster flat riding.",
                gapBadge: "-\(String(format: "%.0f", gap.elevationGap))m",
                whatIf: nil
            ))
            
        case .consistency:
            tips.append(CoachingTip(
                icon: "🗓",
                type: .consistency,
                headline: "More frequent rides wins",
                detail: "\(leader.displayName) has \(gap.rideCountGap) more ride\(gap.rideCountGap == 1 ? "" : "s") this period. Consistency compounds — \(gap.rideCountGap) extra ride\(gap.rideCountGap == 1 ? "" : "s") at your average \(String(format: "%.0f", rider.averageDistanceKm))km each would close the gap.",
                gapBadge: "-\(gap.rideCountGap) rides",
                whatIf: whatIfExtraRides(gap.rideCountGap, rider: rider)
            ))
            
        case .efficiency:
            tips.append(CoachingTip(
                icon: "🎯",
                type: .efficiency,
                headline: "Maximise your time on the bike",
                detail: "Your efficiency score shows room to improve speed relative to effort. Try shorter, higher-intensity sessions to build pace.",
                gapBadge: nil,
                whatIf: nil
            ))
        }
        
        // Always add a positive reinforcement tip
        tips.append(CoachingTip(
            icon: "💪",
            type: .strength,
            headline: "Your strength: \(gap.strongestMetric.displayName)",
            detail: "You rank highly on \(gap.strongestMetric.displayName.lowercased()) in the club. Build your training plan around this strength.",
            gapBadge: nil,
            whatIf: nil
        ))
        
        return Array(tips.prefix(2))
    }
    
    // MARK: - Private Helpers
    
    /// Identifies rider's weakest performance metric relative to club
    private static func weakestMetric(rider: RiderStats, allRiders: [RiderStats]) -> PerformanceMetric {
        let normalized = [
            (PerformanceMetric.distance, rider.normalizedDistance),
            (PerformanceMetric.speed, rider.normalizedSpeed),
            (PerformanceMetric.elevation, rider.normalizedElevation),
            (PerformanceMetric.consistency, rider.normalizedConsistency),
            (PerformanceMetric.efficiency, rider.normalizedEfficiency)
        ]
        return normalized.min(by: { $0.1 < $1.1 })?.0 ?? .distance
    }
    
    /// Identifies rider's strongest performance metric relative to club
    private static func strongestMetric(rider: RiderStats, allRiders: [RiderStats]) -> PerformanceMetric {
        let normalized = [
            (PerformanceMetric.distance, rider.normalizedDistance),
            (PerformanceMetric.speed, rider.normalizedSpeed),
            (PerformanceMetric.elevation, rider.normalizedElevation),
            (PerformanceMetric.consistency, rider.normalizedConsistency),
            (PerformanceMetric.efficiency, rider.normalizedEfficiency)
        ]
        return normalized.max(by: { $0.1 < $1.1 })?.0 ?? .distance
    }
}

// MARK: - Supporting Types

/// Gap analysis result comparing rider to leader
struct GapAnalysis {
    let distanceGap: Double          // km
    let speedGap: Double             // km/h
    let elevationGap: Double         // meters
    let rideCountGap: Int            // number of rides
    let ridesNeededToClose: Int      // at current average distance
    let weakestMetric: PerformanceMetric
    let strongestMetric: PerformanceMetric
    let clubRank: Int                // 1-indexed position
}

/// What-if scenario projection result
struct WhatIfResult {
    let scenario: String             // Human-readable description
    let projectedDistance: Double    // Projected total km
    let distanceGain: Double         // Delta from current
    let newRank: Int?                // Projected rank (computed by VM)
}

/// Performance metric categories
enum PerformanceMetric {
    case distance
    case speed
    case elevation
    case consistency
    case efficiency
    
    var displayName: String {
        switch self {
        case .distance: return "Distance"
        case .speed: return "Speed"
        case .elevation: return "Elevation"
        case .consistency: return "Consistency"
        case .efficiency: return "Efficiency"
        }
    }
}

/// Enhanced coaching tip with optional what-if projection
struct CoachingTip: Identifiable {
    let id = UUID()
    let icon: String
    let type: TipType
    let headline: String
    let detail: String
    let gapBadge: String?
    let whatIf: WhatIfResult?
    
    enum TipType {
        case distance
        case speed
        case elevation
        case consistency
        case efficiency
        case strength
    }
}

//
//  RiderInsightEngine.swift
//  DCC-Weekly-Activities
//
//  Rule-based insight engine that generates personalized performance insights
//  from MemberStats data. Used by Just My Stats and Me vs Top 3 screens.
//
//  VERSION HISTORY:
//  2026-02-24: Initial implementation with 7 insight rules
//

import SwiftUI

/// Generates intelligent, data-driven insights about a rider's performance
struct RiderInsightEngine {
    
    /// Generates an array of insights based on the rider's data and comparison context
    /// - Parameters:
    ///   - member: The MemberStats for the rider being analyzed
    ///   - allMembers: All club members for comparison calculations
    ///   - mode: The insight mode (personal stats vs competitive comparison)
    /// - Returns: Array of RiderInsight objects sorted by sentiment priority
    static func insights(
        for member: MemberStats,
        against allMembers: [MemberStats],
        mode: InsightMode
    ) -> [RiderInsight] {
        var insights: [RiderInsight] = []
        
        // RULE 1: Week-on-week distance trend
        if let trendInsight = weekOnWeekTrend(for: member) {
            insights.append(trendInsight)
        }
        
        // RULE 2: Club ranking this week
        if let rankingInsight = clubRanking(for: member, in: allMembers) {
            insights.append(rankingInsight)
        }
        
        // RULE 3: Rides frequency comparison
        if let frequencyInsight = ridesFrequency(for: member, in: allMembers) {
            insights.append(frequencyInsight)
        }
        
        // RULE 4: Elevation analysis
        if let elevationInsight = elevationAnalysis(for: member, in: allMembers) {
            insights.append(elevationInsight)
        }
        
        // RULE 5: Speed comparison
        if let speedInsight = speedAnalysis(for: member, in: allMembers) {
            insights.append(speedInsight)
        }
        
        // RULE 6: Cumulative milestones
        if let milestoneInsight = cumulativeMilestone(for: member) {
            insights.append(milestoneInsight)
        }
        
        // RULE 7: Consistency streak
        if let consistencyInsight = consistencyStreak(for: member) {
            insights.append(consistencyInsight)
        }
        
        // COMPARISON-SPECIFIC RULES (only for vsTop3 mode)
        if mode == .vsTop3 {
            // RULE A: Gap to top
            if let gapInsight = gapToTop(for: member, in: allMembers) {
                insights.append(gapInsight)
            }
            
            // RULE B: Strongest metric
            if let strongestInsight = strongestMetric(for: member, in: allMembers) {
                insights.append(strongestInsight)
            }
            
            // RULE C: Improvement target
            if let improvementInsight = improvementTarget(for: member, in: allMembers) {
                insights.append(improvementInsight)
            }
        }
        
        // Sort by sentiment priority: remarkable > positive > neutral > negative
        return insights.sorted { lhs, rhs in
            lhs.sentiment.priority > rhs.sentiment.priority
        }
    }
    
    // MARK: - RULE 1: Week-on-Week Distance Trend
    
    private static func weekOnWeekTrend(for member: MemberStats) -> RiderInsight? {
        let change = member.totalKM - member.previousWeekKM
        let pct = abs(change) / max(1, member.previousWeekKM) * 100
        
        if change > 0 {
            return RiderInsight(
                icon: "arrow.up.circle.fill",
                iconColor: .green,
                headline: "Strong week 💪",
                detail: "You rode \(formatDistance(member.totalKM)) this week — \(formatPercent(pct)) more than last week's \(formatDistance(member.previousWeekKM)). Keep it up.",
                sentiment: .positive
            )
        } else if change < 0 {
            return RiderInsight(
                icon: "arrow.down.circle.fill",
                iconColor: .red,
                headline: "Quieter week this time",
                detail: "Down to \(formatDistance(member.totalKM)) from \(formatDistance(member.previousWeekKM)) last week — a \(formatPercent(pct)) dip. Easy week or missed sessions?",
                sentiment: .negative
            )
        } else if change == 0 && member.totalKM > 0 {
            return RiderInsight(
                icon: "equal.circle.fill",
                iconColor: .orange,
                headline: "Perfectly consistent",
                detail: "Exactly \(formatDistance(member.totalKM)) — identical to last week. Creature of habit!",
                sentiment: .neutral
            )
        }
        
        return nil
    }
    
    // MARK: - RULE 2: Club Ranking This Week
    
    private static func clubRanking(for member: MemberStats, in allMembers: [MemberStats]) -> RiderInsight? {
        let sortedMembers = allMembers.sorted { $0.totalKM > $1.totalKM }
        let activeMembers = allMembers.filter { $0.totalKM > 0 }
        
        guard let rank = sortedMembers.firstIndex(where: { $0.memberName == member.memberName }) else {
            return nil
        }
        
        let position = rank + 1
        let total = activeMembers.count
        
        if position == 1 {
            return RiderInsight(
                icon: "trophy.fill",
                iconColor: .yellow,
                headline: "Top of the club this week 🏆",
                detail: "You led the club with \(formatDistance(member.totalKM)) — ahead of all \(total) active riders.",
                sentiment: .remarkable
            )
        } else if position == 2 || position == 3 {
            return RiderInsight(
                icon: "medal.fill",
                iconColor: .orange,
                headline: "Podium finish 🥈",
                detail: "Ranked \(position) of \(total) active riders this week with \(formatDistance(member.totalKM)).",
                sentiment: .positive
            )
        } else if position > total / 2 && total > 0 {
            let topRider = sortedMembers.first
            let topKM = topRider?.totalKM ?? 0
            let gap = topKM - member.totalKM
            
            return RiderInsight(
                icon: "figure.outdoor.cycle",
                iconColor: .red,
                headline: "Room to push harder",
                detail: "Ranked \(position) of \(total) active riders this week. The top rider covered \(formatDistance(topKM)) — \(formatDistance(gap)) more than you.",
                sentiment: .negative
            )
        }
        
        return nil
    }
    
    // MARK: - RULE 3: Rides Frequency
    
    private static func ridesFrequency(for member: MemberStats, in allMembers: [MemberStats]) -> RiderInsight? {
        let activeMembers = allMembers.filter { $0.totalRides > 0 }
        guard !activeMembers.isEmpty else { return nil }
        
        let totalRides = activeMembers.reduce(0) { $0 + $1.totalRides }
        let clubAvgRides = Double(totalRides) / max(1, Double(activeMembers.count))
        
        if member.totalRides > Int(clubAvgRides) + 1 {
            let diff = member.totalRides - Int(clubAvgRides)
            return RiderInsight(
                icon: "flag.checkered",
                iconColor: .green,
                headline: "Most active rider",
                detail: "\(member.totalRides) rides this week — \(diff) more than the club average of \(formatRides(clubAvgRides)) rides.",
                sentiment: .positive
            )
        } else if member.totalRides < Int(clubAvgRides) && member.totalRides > 0 {
            return RiderInsight(
                icon: "flag",
                iconColor: .red,
                headline: "Below average ride count",
                detail: "Only \(member.totalRides) rides this week vs the club average of \(formatRides(clubAvgRides)). More short rides would boost your weekly total.",
                sentiment: .negative
            )
        }
        
        return nil
    }
    
    // MARK: - RULE 4: Elevation Analysis
    
    private static func elevationAnalysis(for member: MemberStats, in allMembers: [MemberStats]) -> RiderInsight? {
        guard !allMembers.isEmpty else { return nil }
        
        let totalElevation = allMembers.reduce(0.0) { $0 + $1.totalElevation }
        let clubAvgElev = totalElevation / max(1, Double(allMembers.count))
        
        if member.totalElevation > clubAvgElev * 1.5 && member.totalElevation > 0 {
            let pct = ((member.totalElevation - clubAvgElev) / max(1, clubAvgElev)) * 100
            return RiderInsight(
                icon: "mountain.2.fill",
                iconColor: .purple,
                headline: "Climbing machine 🏔",
                detail: "\(formatElevation(member.totalElevation)) of climbing this week — \(formatPercent(pct)) more than the club average of \(formatElevation(clubAvgElev)). Your legs must be feeling it.",
                sentiment: .remarkable
            )
        } else if member.totalElevation < clubAvgElev * 0.5 && member.totalKM > 0 {
            return RiderInsight(
                icon: "road.lanes",
                iconColor: .orange,
                headline: "Keeping it flat",
                detail: "Only \(formatElevation(member.totalElevation)) elevation this week vs club average of \(formatElevation(clubAvgElev)). All flat routes or saving energy?",
                sentiment: .neutral
            )
        }
        
        return nil
    }
    
    // MARK: - RULE 5: Speed Analysis
    
    private static func speedAnalysis(for member: MemberStats, in allMembers: [MemberStats]) -> RiderInsight? {
        let membersWithSpeed = allMembers.filter { $0.avgSpeed > 0 }
        guard !membersWithSpeed.isEmpty else { return nil }
        
        let totalSpeed = membersWithSpeed.reduce(0.0) { $0 + $1.avgSpeed }
        let clubAvgSpeed = totalSpeed / max(1, Double(membersWithSpeed.count))
        
        if member.avgSpeed > clubAvgSpeed * 1.1 && member.avgSpeed > 0 {
            let diff = member.avgSpeed - clubAvgSpeed
            return RiderInsight(
                icon: "gauge.with.needles.1",
                iconColor: .purple,
                headline: "Fastest in the club ⚡",
                detail: "Averaging \(formatSpeed(member.avgSpeed)) — \(formatSpeed(diff)) faster than the club average of \(formatSpeed(clubAvgSpeed)).",
                sentiment: .remarkable
            )
        } else if member.avgSpeed < clubAvgSpeed * 0.9 && member.avgSpeed > 0 {
            let diff = clubAvgSpeed - member.avgSpeed
            return RiderInsight(
                icon: "speedometer",
                iconColor: .orange,
                headline: "Taking it steady",
                detail: "\(formatSpeed(member.avgSpeed)) average — \(formatSpeed(diff)) below the club average. More endurance focused or hilly routes?",
                sentiment: .neutral
            )
        }
        
        return nil
    }
    
    // MARK: - RULE 6: Cumulative Milestones
    
    private static func cumulativeMilestone(for member: MemberStats) -> RiderInsight? {
        let milestones: [Double] = [500, 1000, 1500, 2000, 2500, 3000, 5000]
        
        // Check if rider just crossed a milestone
        for milestone in milestones {
            if member.totalKM >= milestone && member.totalKM < milestone + member.totalKM - member.previousWeekKM {
                return RiderInsight(
                    icon: "star.circle.fill",
                    iconColor: .purple,
                    headline: "Milestone unlocked 🎉",
                    detail: "You just crossed \(formatDistance(milestone)) total in the club. \(formatDistance(member.totalKM)) and counting!",
                    sentiment: .remarkable
                )
            }
        }
        
        // Always show current total
        if member.totalKM > 0 {
            return RiderInsight(
                icon: "road.lanes",
                iconColor: .blue,
                headline: "Total distance tracked",
                detail: "\(formatDistance(member.totalKM)) ridden in total across \(member.totalRides) club rides.",
                sentiment: .neutral
            )
        }
        
        return nil
    }
    
    // MARK: - RULE 7: Consistency Streak
    
    private static func consistencyStreak(for member: MemberStats) -> RiderInsight? {
        if member.totalKM > 0 && member.previousWeekKM > 0 {
            return RiderInsight(
                icon: "checkmark.seal.fill",
                iconColor: .green,
                headline: "Two weeks running ✅",
                detail: "Active both this week (\(formatDistance(member.totalKM))) and last (\(formatDistance(member.previousWeekKM))). Consistency is everything.",
                sentiment: .positive
            )
        } else if member.totalKM > 0 && member.previousWeekKM == 0 {
            return RiderInsight(
                icon: "arrow.counterclockwise.circle.fill",
                iconColor: .green,
                headline: "Back on the bike",
                detail: "Good to see you back after a quiet week last time. \(formatDistance(member.totalKM)) is a solid return.",
                sentiment: .positive
            )
        } else if member.totalKM == 0 && member.previousWeekKM > 0 {
            return RiderInsight(
                icon: "questionmark.circle.fill",
                iconColor: .red,
                headline: "Missing in action",
                detail: "No rides recorded this week after \(formatDistance(member.previousWeekKM)) last week. Everything okay?",
                sentiment: .negative
            )
        }
        
        return nil
    }
    
    // MARK: - COMPARISON RULE A: Gap to Top
    
    private static func gapToTop(for member: MemberStats, in allMembers: [MemberStats]) -> RiderInsight? {
        let sortedMembers = allMembers.sorted { $0.totalKM > $1.totalKM }
        guard let topRider = sortedMembers.first else { return nil }
        
        let gap = topRider.totalKM - member.totalKM
        
        if gap > 0 {
            let avgKMPerRide = member.totalRides > 0 ? member.totalKM / Double(member.totalRides) : 0
            let ridesNeeded = avgKMPerRide > 0 ? Int(ceil(gap / avgKMPerRide)) : 0
            let topName = topRider.memberName.components(separatedBy: " ").first ?? topRider.memberName
            
            return RiderInsight(
                icon: "arrow.up.forward.circle",
                iconColor: .orange,
                headline: "\(formatDistance(gap)) behind the leader",
                detail: "\(topName) led with \(formatDistance(topRider.totalKM)) this week. At your current pace of \(formatDistance(avgKMPerRide)) per ride, that's \(ridesNeeded) more rides to close the gap.",
                sentiment: .neutral
            )
        } else if gap <= 0 && member.totalKM > 0 {
            let secondPlace = sortedMembers.count > 1 ? sortedMembers[1] : nil
            let closestGap = secondPlace != nil ? abs(member.totalKM - secondPlace!.totalKM) : 0
            
            return RiderInsight(
                icon: "trophy.fill",
                iconColor: .yellow,
                headline: "You're leading the pack 🏆",
                detail: "Ahead of the top 3 this week with \(formatDistance(member.totalKM)). \(formatDistance(closestGap)) clear of second place.",
                sentiment: .remarkable
            )
        }
        
        return nil
    }
    
    // MARK: - COMPARISON RULE B: Strongest Metric
    
    private static func strongestMetric(for member: MemberStats, in allMembers: [MemberStats]) -> RiderInsight? {
        guard !allMembers.isEmpty else { return nil }
        
        // Calculate rankings for each metric
        let distanceRank = allMembers.sorted { $0.totalKM > $1.totalKM }.firstIndex(where: { $0.memberName == member.memberName }) ?? allMembers.count
        let ridesRank = allMembers.sorted { $0.totalRides > $1.totalRides }.firstIndex(where: { $0.memberName == member.memberName }) ?? allMembers.count
        let speedRank = allMembers.sorted { $0.avgSpeed > $1.avgSpeed }.firstIndex(where: { $0.memberName == member.memberName }) ?? allMembers.count
        let elevationRank = allMembers.sorted { $0.totalElevation > $1.totalElevation }.firstIndex(where: { $0.memberName == member.memberName }) ?? allMembers.count
        
        // Find the best ranking
        let rankings = [
            ("distance", distanceRank + 1, formatDistance(member.totalKM), "road.lanes"),
            ("ride count", ridesRank + 1, "\(member.totalRides) rides", "flag.checkered"),
            ("average speed", speedRank + 1, formatSpeed(member.avgSpeed), "speedometer"),
            ("elevation gain", elevationRank + 1, formatElevation(member.totalElevation), "mountain.2.fill")
        ]
        
        guard let bestMetric = rankings.min(by: { $0.1 < $1.1 }), bestMetric.1 <= 3 else {
            return nil
        }
        
        let ordinal = ["", "1st", "2nd", "3rd"][min(bestMetric.1, 3)]
        
        return RiderInsight(
            icon: bestMetric.3,
            iconColor: .green,
            headline: "Your strongest stat vs top 3",
            detail: "Your \(bestMetric.0) of \(bestMetric.2) ranks you \(ordinal) among the top performers this week.",
            sentiment: .positive
        )
    }
    
    // MARK: - COMPARISON RULE C: Improvement Target
    
    private static func improvementTarget(for member: MemberStats, in allMembers: [MemberStats]) -> RiderInsight? {
        guard allMembers.count >= 3 else { return nil }
        
        let top3 = Array(allMembers.sorted { $0.totalKM > $1.totalKM }.prefix(3))
        
        // Calculate gaps for each metric
        let distanceAvg = top3.reduce(0.0) { $0 + $1.totalKM } / 3.0
        let ridesAvg = top3.reduce(0.0) { $0 + Double($1.totalRides) } / 3.0
        let speedAvg = top3.reduce(0.0) { $0 + $1.avgSpeed } / 3.0
        let elevationAvg = top3.reduce(0.0) { $0 + $1.totalElevation } / 3.0
        
        let distanceGap = distanceAvg - member.totalKM
        let ridesGap = ridesAvg - Double(member.totalRides)
        let speedGap = speedAvg - member.avgSpeed
        let elevationGap = elevationAvg - member.totalElevation
        
        // Calculate percentage gaps (how far behind)
        let distancePctGap = distanceAvg > 0 ? (distanceGap / distanceAvg) * 100 : 0
        let ridesPctGap = ridesAvg > 0 ? (ridesGap / ridesAvg) * 100 : 0
        let speedPctGap = speedAvg > 0 ? (speedGap / speedAvg) * 100 : 0
        let elevationPctGap = elevationAvg > 0 ? (elevationGap / elevationAvg) * 100 : 0
        
        // Find the biggest gap
        let gaps = [
            ("distance", distanceGap, distancePctGap, formatDistance(member.totalKM), formatDistance(distanceAvg), "road.lanes"),
            ("ride count", ridesGap, ridesPctGap, "\(member.totalRides)", formatRides(ridesAvg), "flag.checkered"),
            ("average speed", speedGap, speedPctGap, formatSpeed(member.avgSpeed), formatSpeed(speedAvg), "speedometer"),
            ("elevation gain", elevationGap, elevationPctGap, formatElevation(member.totalElevation), formatElevation(elevationAvg), "mountain.2.fill")
        ]
        
        guard let biggestGap = gaps.filter({ $0.1 > 0 }).max(by: { $0.2 < $1.2 }) else {
            return nil
        }
        
        return RiderInsight(
            icon: "target",
            iconColor: .orange,
            headline: "Biggest opportunity 🎯",
            detail: "Your \(biggestGap.0) of \(biggestGap.3) is \(formatDistance(biggestGap.1)) behind the top 3 average of \(biggestGap.4). Focus here for the biggest weekly improvement.",
            sentiment: .neutral
        )
    }
    
    // MARK: - Formatting Helpers
    
    private static func formatDistance(_ km: Double) -> String {
        String(format: "%.1f", km) + "km"
    }
    
    private static func formatSpeed(_ speed: Double) -> String {
        String(format: "%.1f", speed) + "km/h"
    }
    
    private static func formatElevation(_ meters: Double) -> String {
        String(format: "%.0f", meters) + "m"
    }
    
    private static func formatRides(_ rides: Double) -> String {
        String(format: "%.1f", rides)
    }
    
    private static func formatPercent(_ pct: Double) -> String {
        String(format: "%.0f", pct) + "%"
    }
}

// MARK: - Insight Mode

extension RiderInsightEngine {
    enum InsightMode {
        case personalStats   // Just My Stats screen
        case vsTop3          // Me vs Top 3 screen
    }
}

// MARK: - Rider Insight Model

struct RiderInsight: Identifiable {
    let id = UUID()
    let icon: String           // SF Symbol name
    let iconColor: Color       // Icon tint color
    let headline: String       // Short bold line
    let detail: String         // 1-2 sentence analysis
    let sentiment: Sentiment
    
    enum Sentiment {
        case positive      // Green highlight - good performance
        case negative      // Red highlight - needs improvement
        case neutral       // Orange highlight - informational
        case remarkable    // Purple highlight - standout achievement
        
        var priority: Int {
            switch self {
            case .remarkable: return 4
            case .positive: return 3
            case .neutral: return 2
            case .negative: return 1
            }
        }
        
        var color: Color {
            switch self {
            case .positive: return .green
            case .negative: return .red
            case .neutral: return .orange
            case .remarkable: return .purple
            }
        }
    }
}

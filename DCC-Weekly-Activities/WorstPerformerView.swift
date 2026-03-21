//
//  WorstPerformerView.swift
//  DCC-Weekly-Activities
//
//  Identifies the worst performer using weighted composite scoring
//  and provides detailed analysis with actionable insights
//

import SwiftUI
import Charts

struct WorstPerformerView: View {
    let stats: [MemberStats]
    let activities: [Activity]
    let dateRange: (start: Date, end: Date)?
    
    @State private var selectedMember: MemberStats?
    
    // MARK: - Helper Computed Properties
    
    private var dateInterval: DateInterval? {
        guard let range = dateRange else { return nil }
        return DateInterval(start: range.start, end: range.end)
    }
    
    private var avgRidesPerMember: Double {
        guard !stats.isEmpty else { return 0 }
        let totalRides = stats.reduce(0) { $0 + $1.totalRides }
        return Double(totalRides) / Double(stats.count)
    }
    
    private var avgSpeedClub: Double {
        let validSpeedStats = stats.filter { $0.avgSpeed > 0 }
        guard !validSpeedStats.isEmpty else { return 0 }
        return validSpeedStats.reduce(0.0) { $0 + $1.avgSpeed } / Double(validSpeedStats.count)
    }
    
    private var clubAverageDistance: Double {
        guard !stats.isEmpty else { return 0 }
        return stats.reduce(0.0) { $0 + $1.totalKM } / Double(stats.count)
    }
    
    /// Calculates worst performer using weighted composite scoring across all available parameters.
    ///
    /// Scoring weights (normalized 0-1 scale):
    /// - Total distance:   0.35 (highest priority for cycling club)
    /// - Number of rides:  0.20 (consistency matters)
    /// - Elevation gain:   0.20 (climb difficulty)
    /// - Moving time:      0.10 (time on bike)
    /// - Average speed:    0.10 (performance quality)
    /// - Suffer score:     0.05 (if available, currently not in data)
    ///
    /// Returns the member with the LOWEST composite score (worst performer).
    private var worstPerformer: MemberStats? {
        guard !stats.isEmpty else { return nil }
        
        // Get max values for normalization
        let maxDistance = stats.map { $0.totalKM }.max() ?? 1.0
        let maxRides = Double(stats.map { $0.totalRides }.max() ?? 1)
        let maxElevation = stats.map { $0.totalElevation }.max() ?? 1.0
        let maxSpeed = stats.map { $0.avgSpeed }.max() ?? 1.0
        
        // Calculate total moving time for each member
        let movingTimes = stats.map { stat in
            (stat: stat, movingTime: Double(stat.rides.reduce(0) { $0 + $1.movingTime }))
        }
        let maxMovingTime = movingTimes.map { $0.movingTime }.max() ?? 1.0
        
        // Calculate weighted composite score for each member
        let scored = stats.map { stat -> (stat: MemberStats, score: Double) in
            // Normalize each parameter (0-1 scale)
            let normalizedDistance = stat.totalKM / maxDistance
            let normalizedRides = Double(stat.totalRides) / maxRides
            let normalizedElevation = stat.totalElevation / maxElevation
            let normalizedSpeed = stat.avgSpeed / maxSpeed
            
            let memberMovingTime = Double(stat.rides.reduce(0) { $0 + $1.movingTime })
            let normalizedMovingTime = memberMovingTime / maxMovingTime
            
            // Apply weights and sum
            let compositeScore =
                (normalizedDistance * 0.35) +
                (normalizedRides * 0.20) +
                (normalizedElevation * 0.20) +
                (normalizedMovingTime * 0.10) +
                (normalizedSpeed * 0.10)
                // Suffer score would be 0.05 if available
            
            return (stat: stat, score: compositeScore)
        }
        
        // Return member with lowest score
        return scored.min { $0.score < $1.score }?.stat
    }
    
    private var clubAverage: (distance: Double, rides: Double, elevation: Double, speed: Double, movingTime: Double) {
        guard !stats.isEmpty else {
            return (0, 0, 0, 0, 0)
        }
        
        let totalDistance = stats.reduce(0.0) { $0 + $1.totalKM }
        let totalRides = stats.reduce(0) { $0 + $1.totalRides }
        let totalElevation = stats.reduce(0.0) { $0 + $1.totalElevation }
        
        let validSpeedStats = stats.filter { $0.avgSpeed > 0 }
        let avgSpeed = validSpeedStats.isEmpty ? 0 : validSpeedStats.reduce(0.0) { $0 + $1.avgSpeed } / Double(validSpeedStats.count)
        
        let totalMovingTime = stats.flatMap { $0.rides }.reduce(0) { $0 + $1.movingTime }
        let avgMovingTime = activities.isEmpty ? 0 : Double(totalMovingTime) / Double(activities.count)
        
        return (
            distance: totalDistance / Double(stats.count),
            rides: Double(totalRides) / Double(stats.count),
            elevation: totalElevation / Double(stats.count),
            speed: avgSpeed,
            movingTime: avgMovingTime
        )
    }
    
    private var top3Average: (distance: Double, rides: Double, elevation: Double, speed: Double) {
        let top3 = stats.sorted { $0.totalKM > $1.totalKM }.prefix(3)
        guard !top3.isEmpty else {
            return (0, 0, 0, 0)
        }
        
        let count = Double(top3.count)
        return (
            distance: top3.reduce(0.0) { $0 + $1.totalKM } / count,
            rides: top3.reduce(0.0) { $0 + Double($1.totalRides) } / count,
            elevation: top3.reduce(0.0) { $0 + $1.totalElevation } / count,
            speed: top3.reduce(0.0) { $0 + $1.avgSpeed } / count
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Date Range Header
                DateRangeHeaderView(dateRange: dateInterval, showWeekLabel: false)
                    .padding(.top, 8)
                
                Divider()
                    .padding(.horizontal)
                
                // Header
                headerSection
                
                if let worst = worstPerformer {
                    // Worst performer card with navigation
                    NavigationLink {
                        MemberDetailView(memberStats: worst, allStats: stats)
                    } label: {
                        worstPerformerCard(stats: worst)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Detailed verdict
                    verdictSection(stats: worst)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Comparison with club average and top 3
                    comparisonSection(stats: worst)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Motivational suggestions
                    motivationalSection(stats: worst)
                } else {
                    emptyStateView
                }
            }
            .padding(.vertical, 24)
        }
        .background(
            LinearGradient(
                colors: [Color.dccBlue.opacity(0.15), Color.dccSaffron.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.orange, Color.red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Needs Motivation")
                .font(.title2)
                .fontWeight(.bold)
        }
    }
    
    // MARK: - Worst Performer Card
    
    private func worstPerformerCard(stats: MemberStats) -> some View {
        VStack(spacing: 20) {
            // Member info
            HStack {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.orange.gradient)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(stats.memberName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Lowest Composite Score")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Divider()
            
            // Stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                miniStat(
                    label: "Distance",
                    value: String(format: "%.1f km", stats.totalKM),
                    icon: "road.lanes",
                    color: .orange
                )
                
                miniStat(
                    label: "Rides",
                    value: "\(stats.totalRides)",
                    icon: "bicycle",
                    color: .red
                )
                
                miniStat(
                    label: "Avg Speed",
                    value: String(format: "%.1f km/h", stats.avgSpeed),
                    icon: "speedometer",
                    color: .purple
                )
                
                miniStat(
                    label: "Elevation",
                    value: String(format: "%.0f m", stats.totalElevation),
                    icon: "mountain.2.fill",
                    color: .blue
                )
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .orange.opacity(0.2), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stats.memberName), lowest performer")
        .accessibilityHint("Tap to view member details")
    }
    
    private func miniStat(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Verdict Section
    
    private func verdictSection(stats: MemberStats) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Analysis")
                .font(.headline)
                .padding(.horizontal, 24)
            
            Text(generateVerdict(for: stats))
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 24)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }
    
    /// Generates a rule-based verdict with specific numbers and percentages
    private func generateVerdict(for stats: MemberStats) -> String {
        var verdict: [String] = []
        
        let firstName = stats.memberName.components(separatedBy: " ").first ?? stats.memberName
        
        // Distance analysis
        let distancePercent = clubAverageDistance > 0 ? ((clubAverageDistance - stats.totalKM) / clubAverageDistance) * 100 : 0
        let top1Distance = self.stats.sorted { $0.totalKM > $1.totalKM }.first?.totalKM ?? 0
        let top1Percent = top1Distance > 0 ? ((top1Distance - stats.totalKM) / top1Distance) * 100 : 0
        
        verdict.append("\(firstName) had the shortest total distance this week at \(String(format: "%.1f", stats.totalKM))km")
        
        if distancePercent > 0 {
            verdict.append("— \(String(format: "%.0f", distancePercent))% below the club average of \(String(format: "%.1f", clubAverageDistance))km")
        }
        
        if top1Percent > 0 {
            verdict.append("and \(String(format: "%.0f", top1Percent))% behind the top rider")
        }
        
        // Ride count analysis
        if stats.totalRides == 0 {
            verdict.append(". No rides were recorded this week")
        } else if stats.totalRides == 1 {
            verdict.append(". Only 1 ride was completed")
        } else {
            let ridePercent = avgRidesPerMember > 0 ? ((avgRidesPerMember - Double(stats.totalRides)) / avgRidesPerMember) * 100 : 0
            if ridePercent > 0 {
                verdict.append(". \(firstName) completed \(stats.totalRides) rides, \(String(format: "%.0f", ridePercent))% fewer than the club average of \(String(format: "%.1f", avgRidesPerMember)) rides")
            }
        }
        
        // Elevation analysis
        if stats.totalElevation == 0 {
            verdict.append(", with zero elevation gain recorded, suggesting flat recovery rides or indoor training")
        } else {
            let elevPercent = clubAverage.elevation > 0 ? ((clubAverage.elevation - stats.totalElevation) / clubAverage.elevation) * 100 : 0
            if elevPercent > 20 {
                verdict.append(". Elevation gain of \(String(format: "%.0f", stats.totalElevation))m was \(String(format: "%.0f", elevPercent))% below club average")
            }
        }
        
        // Speed analysis
        if stats.avgSpeed > 0 && stats.avgSpeed < avgSpeedClub {
            let speedDiff = avgSpeedClub - stats.avgSpeed
            verdict.append(". Average speed of \(String(format: "%.1f", stats.avgSpeed))km/h was \(String(format: "%.1f", speedDiff))km/h slower than the club average")
        }
        
        verdict.append(".")
        
        return verdict.joined()
    }
    
    // MARK: - Comparison Section
    
    private func comparisonSection(stats: MemberStats) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Performance Breakdown")
                .font(.headline)
                .padding(.horizontal, 24)
            
            VStack(spacing: 16) {
                comparisonRow(
                    title: "Distance",
                    performerValue: stats.totalKM,
                    clubAvgValue: clubAverage.distance,
                    top3AvgValue: top3Average.distance,
                    unit: "km",
                    color: .orange
                )
                
                comparisonRow(
                    title: "Rides",
                    performerValue: Double(stats.totalRides),
                    clubAvgValue: clubAverage.rides,
                    top3AvgValue: top3Average.rides,
                    unit: "rides",
                    color: .red,
                    decimals: 0
                )
                
                comparisonRow(
                    title: "Elevation",
                    performerValue: stats.totalElevation,
                    clubAvgValue: clubAverage.elevation,
                    top3AvgValue: top3Average.elevation,
                    unit: "m",
                    color: .blue,
                    decimals: 0
                )
                
                comparisonRow(
                    title: "Avg Speed",
                    performerValue: stats.avgSpeed,
                    clubAvgValue: clubAverage.speed,
                    top3AvgValue: top3Average.speed,
                    unit: "km/h",
                    color: .purple
                )
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }
    
    private func comparisonRow(
        title: String,
        performerValue: Double,
        clubAvgValue: Double,
        top3AvgValue: Double,
        unit: String,
        color: Color,
        decimals: Int = 1
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // Values comparison
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Member")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.\(decimals)f", performerValue))
                        .font(.headline)
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Club Avg")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.\(decimals)f", clubAvgValue))
                        .font(.headline)
                        .foregroundStyle(.gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Top 3 Avg")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.\(decimals)f", top3AvgValue))
                        .font(.headline)
                        .foregroundStyle(.green)
                }
                
                Spacer()
            }
            
            // Status indicator
            let status = getPerformanceStatus(
                value: performerValue,
                clubAvg: clubAvgValue,
                top3Avg: top3AvgValue
            )
            
            HStack(spacing: 8) {
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
                
                Text(status.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func getPerformanceStatus(value: Double, clubAvg: Double, top3Avg: Double) -> (color: Color, label: String) {
        if value >= top3Avg * 0.9 {
            return (.green, "Near top performers")
        } else if value >= clubAvg * 0.8 {
            return (.orange, "Below club average")
        } else {
            return (.red, "Significantly below average")
        }
    }
    
    // MARK: - Analysis Section (old - kept for reference)
    
    private func analysisSection(stats: MemberStats) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Analysis")
                .font(.headline)
                .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                ForEach(generateReasons(for: stats), id: \.self) { reason in
                    analysisRow(reason: reason)
                }
            }
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }
    
    private func analysisRow(reason: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.orange)
                .font(.title3)
            
            Text(reason)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    private func generateReasons(for stats: MemberStats) -> [String] {
        var reasons: [String] = []
        
        // Distance comparison
        let distanceGap = clubAverageDistance - stats.totalKM
        if distanceGap > 0 {
            reasons.append(String(format: "%.1f km below club average", distanceGap))
        }
        
        // Ride count comparison
        if Double(stats.totalRides) < avgRidesPerMember {
            let rideGap = avgRidesPerMember - Double(stats.totalRides)
            if stats.totalRides == 1 {
                reasons.append("Only 1 ride this week")
            } else if stats.totalRides == 0 {
                reasons.append("No rides logged this week")
            } else {
                reasons.append(String(format: "%.0f fewer rides than average", rideGap))
            }
        }
        
        // Average speed comparison
        if stats.avgSpeed > 0 && stats.avgSpeed < avgSpeedClub {
            let speedGap = avgSpeedClub - stats.avgSpeed
            reasons.append(String(format: "Average speed %.1f km/h below club average", speedGap))
        }
        
        // Activity frequency
        if stats.totalRides > 0 {
            let avgDistancePerRide = stats.totalKM / Double(stats.totalRides)
            let clubAvgPerRide = clubAverageDistance / avgRidesPerMember
            
            if avgDistancePerRide < clubAvgPerRide {
                reasons.append("Shorter rides compared to club members")
            }
        }
        
        // If no specific reasons, provide encouragement
        if reasons.isEmpty {
            reasons.append("Still at the lower end of the leaderboard this week")
        }
        
        return reasons
    }
    
    // MARK: - Comparison Chart (old version - replaced)
    
    private func comparisonChart_old(stats: MemberStats) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("vs Club Average")
                .font(.headline)
                .padding(.horizontal, 24)
            
            let comparisonData = [
                ComparisonData(category: "Distance", performer: stats.totalKM, average: clubAverage.distance, unit: "km"),
                ComparisonData(category: "Rides", performer: Double(stats.totalRides), average: avgRidesPerMember, unit: "rides"),
                ComparisonData(category: "Avg Speed", performer: stats.avgSpeed, average: avgSpeedClub, unit: "km/h")
            ]
            
            Chart(comparisonData) { data in
                BarMark(
                    x: .value("Category", data.category),
                    y: .value("Value", data.performer)
                )
                .foregroundStyle(Color.orange.opacity(0.7))
                .position(by: .value("Type", "Member"))
                
                BarMark(
                    x: .value("Category", data.category),
                    y: .value("Value", data.average)
                )
                .foregroundStyle(Color.dccBlue.opacity(0.7))
                .position(by: .value("Type", "Club Avg"))
            }
            .frame(height: 200)
            .chartForegroundStyleScale([
                "Member": Color.orange.opacity(0.7),
                "Club Avg": Color.dccBlue.opacity(0.7)
            ])
            .padding(.horizontal, 24)
            
            // Legend
            HStack(spacing: 20) {
                legendItem(color: .orange, label: stats.memberName)
                legendItem(color: .dccBlue, label: "Club Average")
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }
    
    private struct ComparisonData: Identifiable {
        let id = UUID()
        let category: String
        let performer: Double
        let average: Double
        let unit: String
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color.opacity(0.7))
                .frame(width: 10, height: 10)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Motivational Section
    
    private func motivationalSection(stats: MemberStats) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("💪 How to Improve")
                .font(.headline)
                .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                ForEach(generateSuggestions(for: stats), id: \.self) { suggestion in
                    suggestionRow(suggestion: suggestion)
                }
            }
        }
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [Color.dccGreen.opacity(0.1), Color.dccSaffron.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }
    
    private func suggestionRow(suggestion: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.dccGreen)
                .font(.title3)
            
            Text(suggestion)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    private func generateSuggestions(for stats: MemberStats) -> [String] {
        var suggestions: [String] = []
        
        // Based on ride count
        let targetRides = Int(ceil(avgRidesPerMember))
        if stats.totalRides < targetRides {
            suggestions.append("Try to ride at least \(targetRides) times per week to match club activity")
        }
        
        // Based on distance
        let targetDistance = clubAverageDistance * 1.1
        suggestions.append(String(format: "Aim for %.0f km next week to reach club average", targetDistance))
        
        // Based on ride frequency
        if stats.totalRides <= 1 {
            suggestions.append("Add at least one more ride this week to build consistency")
        }
        
        // General motivation
        suggestions.append("Join group rides to stay motivated and improve fitness")
        
        return Array(suggestions.prefix(4))
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            Text("Everyone's Doing Great!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("All club members are actively riding. Keep up the excellent work!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }
}

// MARK: - Preview

#Preview {
    let sampleActivities = [
        Activity(
            memberName: "Alice Smith",
            activityName: "Morning Ride",
            distance: 65.5,
            date: Date(),
            averageSpeed: 32.5,
            elevationGain: 650,
            movingTime: 6400,
            type: "Ride"
        ),
        Activity(
            memberName: "Bob Wilson",
            activityName: "Evening Ride",
            distance: 52.0,
            date: Date().addingTimeInterval(-86400),
            averageSpeed: 28.0,
            elevationGain: 420,
            movingTime: 5600,
            type: "Ride"
        ),
        Activity(
            memberName: "Charlie Brown",
            activityName: "Short Ride",
            distance: 12.5,
            date: Date(),
            averageSpeed: 18.0,
            elevationGain: 100,
            movingTime: 2200,
            type: "Ride"
        ),
    ]
    
    let stats = [
        MemberStats(memberName: "Alice Smith", activities: [sampleActivities[0]]),
        MemberStats(memberName: "Bob Wilson", activities: [sampleActivities[1]]),
        MemberStats(memberName: "Charlie Brown", activities: [sampleActivities[2]]),
    ]
    
    let interval = DateRangeProvider.getLastCompletedWeek()
    let dateRange = (start: interval.start, end: interval.end)
    
    return NavigationStack {
        WorstPerformerView(
            stats: stats,
            activities: sampleActivities,
            dateRange: dateRange
        )
        .navigationTitle("Worst Performer")
        .navigationBarTitleDisplayMode(.inline)
    }
}


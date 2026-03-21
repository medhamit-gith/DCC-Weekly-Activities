//
//  JustMyStatsView.swift
//  DCC-Weekly-Activities
//
//  Displays only the authenticated user's stats from last week with
//  club comparisons showing position vs club average and top 3
//

import SwiftUI
import Charts

struct JustMyStatsView: View {
    let athleteProfile: AthleteProfile
    let stats: [MemberStats]
    let activities: [Activity]
    let dateRange: (start: Date, end: Date)?
    
    private var myStats: MemberStats? {
        let fullName = "\(athleteProfile.firstname) \(athleteProfile.lastname)"
        return stats.first { $0.memberName == fullName }
    }
    
    private var myActivities: [Activity] {
        let fullName = "\(athleteProfile.firstname) \(athleteProfile.lastname)"
        return activities.filter { $0.memberName == fullName }
            .sorted { $0.date > $1.date }
    }
    
    private var dateInterval: DateInterval? {
        guard let range = dateRange else { return nil }
        return DateInterval(start: range.start, end: range.end)
    }
    
    private var clubAverage: (distance: Double, rides: Double, elevation: Double, speed: Double, movingTime: Double) {
        guard !stats.isEmpty else {
            return (0, 0, 0, 0, 0)
        }
        
        let totalDistance = stats.reduce(0.0) { $0 + $1.totalKM }
        let totalRides = stats.reduce(0) { $0 + $1.totalRides }
        let totalElevation = stats.reduce(0.0) { $0 + $1.totalElevation }
        let avgSpeed = stats.reduce(0.0) { $0 + $1.avgSpeed } / Double(stats.count)
        
        // Calculate average moving time from activities
        let allActivities = activities
        let totalMovingTime = Double(allActivities.reduce(0) { $0 + $1.movingTime })
        let avgMovingTime = allActivities.isEmpty ? 0 : totalMovingTime / Double(allActivities.count)
        
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
                VStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.dccSaffron, Color.dccGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("\(athleteProfile.firstname)'s Stats")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                if let stats = myStats {
                    // Hero metrics
                    heroMetrics(stats: stats)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // All stats grid - comprehensive data display
                    allStatsGrid(stats: stats)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Intelligent insights
                    insightsSection(stats: stats)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Detailed comparisons
                    comparisonSection(stats: stats)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Activities list with navigation
                    activitiesList
                } else {
                    // No activities found
                    emptyStateView
                }
            }
            .padding(.bottom, 32)
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
    
    // MARK: - Hero Metrics
    
    private func heroMetrics(stats: MemberStats) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            HeroStatCard(
                title: "Total Distance",
                value: String(format: "%.1f km", stats.totalKM),
                icon: "road.lanes",
                color: .dccSaffron,
                currentValue: stats.totalKM,
                previousValue: stats.previousWeekKM,
                unit: "km",
                showTrend: true
            )
            
            HeroStatCard(
                title: "Total Rides",
                value: "\(stats.totalRides)",
                icon: "bicycle",
                color: .dccGreen,
                currentValue: Double(stats.totalRides),
                previousValue: Double(stats.previousWeekRides),
                unit: "rides",
                showTrend: true
            )
            
            HeroStatCard(
                title: "Avg Speed",
                value: String(format: "%.1f km/h", stats.avgSpeed),
                icon: "speedometer",
                color: .dccBlue
            )
            
            HeroStatCard(
                title: "Total Elevation",
                value: String(format: "%.0f m", stats.totalElevation),
                icon: "mountain.2.fill",
                color: .purple
            )
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - All Stats Grid
    
    private func allStatsGrid(stats: MemberStats) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("All Your Data")
                .font(.headline)
                .padding(.horizontal, 24)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                // Row 1: Current Week KM | Previous Week KM
                statCell(
                    label: "This Week KM",
                    value: formatDistance(stats.totalKM),
                    icon: "road.lanes",
                    color: .dccSaffron,
                    clubAvg: formatDistance(clubAverage.distance)
                )
                
                statCell(
                    label: "Last Week KM",
                    value: formatDistance(stats.previousWeekKM),
                    icon: "road.lanes.2",
                    color: .gray,
                    clubAvg: nil
                )
                
                // Row 2: Current Rides | Previous Rides
                statCell(
                    label: "This Week Rides",
                    value: "\(stats.totalRides)",
                    icon: "bicycle",
                    color: .dccGreen,
                    clubAvg: formatRides(clubAverage.rides)
                )
                
                statCell(
                    label: "Last Week Rides",
                    value: "\(stats.previousWeekRides)",
                    icon: "figure.outdoor.cycle",
                    color: .gray,
                    clubAvg: nil
                )
                
                // Row 3: Avg Speed | Elevation
                statCell(
                    label: "Avg Speed",
                    value: formatSpeed(stats.avgSpeed),
                    icon: "speedometer",
                    color: .dccBlue,
                    clubAvg: formatSpeed(clubAverage.speed)
                )
                
                statCell(
                    label: "Elevation",
                    value: formatElevation(stats.totalElevation),
                    icon: "mountain.2.fill",
                    color: .purple,
                    clubAvg: formatElevation(clubAverage.elevation)
                )
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }
    
    private func statCell(label: String, value: String, icon: String, color: Color, clubAvg: String?) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(DCCColors.textSecondary)
                .multilineTextAlignment(.center)

            if let avg = clubAvg {
                Text("Club: \(avg)")
                    .font(.caption2)
                    .foregroundStyle(DCCColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Insights Section
    
    private func insightsSection(stats: MemberStats) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Insights")
                .font(.headline)
                .padding(.horizontal, 24)
            
            let insights = RiderInsightEngine.insights(
                for: stats,
                against: self.stats,
                mode: .personalStats
            )
            
            if insights.isEmpty {
                ContentUnavailableView(
                    "Not enough data yet",
                    systemImage: "chart.bar.xaxis",
                    description: Text("Keep riding to unlock personalized insights")
                )
                .padding(.vertical, 40)
            } else {
                ForEach(Array(insights.prefix(5))) { insight in
                    insightCard(insight: insight)
                }
            }
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }
    
    private func insightCard(insight: RiderInsight) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.icon)
                .foregroundStyle(insight.iconColor)
                .font(.title2)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.headline)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(insight.detail)
                    .font(.caption)
                    .foregroundStyle(DCCColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(
            insight.sentiment == .positive ?
                Color.green.opacity(0.08) :
            insight.sentiment == .negative ?
                Color.red.opacity(0.08) :
            insight.sentiment == .remarkable ?
                Color.purple.opacity(0.08) :
                Color.orange.opacity(0.08)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
    }
    
    // MARK: - Comparison Section
    
    private func comparisonSection(stats: MemberStats) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("How You Compare")
                .font(.headline)
                .padding(.horizontal, 24)
            
            VStack(spacing: 16) {
                comparisonRow(
                    title: "Distance",
                    myValue: stats.totalKM,
                    clubAvg: clubAverage.distance,
                    top3Avg: top3Average.distance,
                    unit: "km",
                    color: .dccSaffron,
                    previousValue: stats.previousWeekKM
                )
                
                comparisonRow(
                    title: "Rides",
                    myValue: Double(stats.totalRides),
                    clubAvg: clubAverage.rides,
                    top3Avg: top3Average.rides,
                    unit: "rides",
                    color: .dccGreen,
                    decimals: 0,
                    previousValue: Double(stats.previousWeekRides)
                )
                
                comparisonRow(
                    title: "Elevation",
                    myValue: stats.totalElevation,
                    clubAvg: clubAverage.elevation,
                    top3Avg: top3Average.elevation,
                    unit: "m",
                    color: .dccBlue,
                    decimals: 0
                )
                
                comparisonRow(
                    title: "Avg Speed",
                    myValue: stats.avgSpeed,
                    clubAvg: clubAverage.speed,
                    top3Avg: top3Average.speed,
                    unit: "km/h",
                    color: .purple
                )
                
                // Moving time comparison
                let myTotalMovingTime = Double(myActivities.reduce(0) { $0 + $1.movingTime })
                comparisonRow(
                    title: "Moving Time",
                    myValue: Double(myTotalMovingTime) / 3600.0, // Convert to hours
                    clubAvg: clubAverage.movingTime / 3600.0,
                    top3Avg: clubAverage.movingTime / 3600.0, // Use club avg as proxy
                    unit: "hrs",
                    color: .orange
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
        myValue: Double,
        clubAvg: Double,
        top3Avg: Double,
        unit: String,
        color: Color,
        decimals: Int = 1,
        previousValue: Double? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and value
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(String(format: "%.\(decimals)f", myValue))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(DCCColors.textSecondary)
            }

            // Delta line (if previous week data available)
            if let prev = previousValue {
                let delta = myValue - prev
                let deltaText: String = {
                    if prev == 0 {
                        return "No data last week"
                    } else {
                        let sign = delta >= 0 ? "+" : ""
                        return "\(sign)\(String(format: "%.\(decimals)f", delta)) \(unit) vs last week"
                    }
                }()
                let deltaColor: Color = prev == 0 ? DCCColors.textSecondary : (delta >= 0 ? DCCColors.success : DCCColors.error)

                Text(deltaText)
                    .font(.caption2)
                    .foregroundStyle(deltaColor)
            }
            
            // Visual comparison bar
            GeometryReader { geometry in
                let maxValue = max(myValue, clubAvg, top3Avg, 0.1) // Avoid divide by zero
                let myWidth = (myValue / maxValue) * geometry.size.width
                let clubWidth = (clubAvg / maxValue) * geometry.size.width
                let top3Width = (top3Avg / maxValue) * geometry.size.width
                
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    // My value bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: myWidth, height: 8)
                    
                    // Club average marker
                    Rectangle()
                        .fill(Color.gray.opacity(0.6))
                        .frame(width: 2, height: 16)
                        .offset(x: clubWidth)
                    
                    // Top 3 average marker
                    Rectangle()
                        .fill(Color.green.opacity(0.6))
                        .frame(width: 2, height: 16)
                        .offset(x: top3Width)
                }
            }
            .frame(height: 16)
            
            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                    Text("You")
                        .font(.caption2)
                        .foregroundStyle(DCCColors.textSecondary)
                }

                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.6))
                        .frame(width: 2, height: 12)
                    Text(String(format: "Club Avg: %.\(decimals)f", clubAvg))
                        .font(.caption2)
                        .foregroundStyle(DCCColors.textSecondary)
                }

                HStack(spacing: 4) {
                    Rectangle()
                        .fill(DCCColors.success.opacity(0.6))
                        .frame(width: 2, height: 12)
                    Text(String(format: "Top 3: %.\(decimals)f", top3Avg))
                        .font(.caption2)
                        .foregroundStyle(DCCColors.textSecondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Activities List (with navigation)
    
    private var activitiesList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Activities")
                .font(.headline)
                .padding(.horizontal, 24)
            
            ForEach(Array(myActivities.prefix(20))) { activity in
                NavigationLink {
                    ActivityDetailView(activity: activity, allActivities: activities)
                } label: {
                    activityRow(activity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }
    
    private func activityRow(_ activity: Activity) -> some View {
        HStack(spacing: 12) {
            Image(systemName: activityIcon(for: activity.type))
                .font(.title3)
                .foregroundStyle(Color.dccGreen)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.activityName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                
                Text(formatDate(activity.date))
                    .font(.caption)
                    .foregroundStyle(DCCColors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f km", activity.distance))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.dccSaffron)
                
                Text(String(format: "%.1f km/h", activity.averageSpeed))
                    .font(.caption2)
                    .foregroundStyle(DCCColors.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(DCCColors.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(activity.activityName), \(String(format: "%.1f", activity.distance)) kilometers")
        .accessibilityHint("Tap to view activity details")
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bicycle.circle")
                .font(.system(size: 80))
                .foregroundStyle(DCCColors.textSecondary)

            Text("No Activities Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("You haven't logged any activities this week. Get out there and ride!")
                .font(.subheadline)
                .foregroundStyle(DCCColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Helper Methods
    
    private func activityIcon(for type: String) -> String {
        switch type.lowercased() {
        case "ride": return "bicycle"
        case "run": return "figure.outdoor.cycle"
        case "walk": return "figure.outdoor.cycle"
        case "swim": return "figure.outdoor.cycle"
        default: return "figure.outdoor.cycle"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Formatting Helpers
    
    private func formatDistance(_ km: Double) -> String {
        String(format: "%.1f", km) + "km"
    }
    
    private func formatSpeed(_ speed: Double) -> String {
        String(format: "%.1f", speed) + "km/h"
    }
    
    private func formatElevation(_ meters: Double) -> String {
        String(format: "%.0f", meters) + "m"
    }
    
    private func formatRides(_ rides: Double) -> String {
        String(format: "%.1f", rides)
    }
}

// MARK: - Hero Stat Card

struct HeroStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let currentValue: Double
    let previousValue: Double
    let unit: String
    let showTrend: Bool
    
    init(
        title: String,
        value: String,
        icon: String,
        color: Color,
        currentValue: Double = 0,
        previousValue: Double = 0,
        unit: String = "",
        showTrend: Bool = false
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.currentValue = currentValue
        self.previousValue = previousValue
        self.unit = unit
        self.showTrend = showTrend
    }
    
    private var delta: Double {
        currentValue - previousValue
    }
    
    private var deltaText: String {
        if previousValue == 0 {
            return "No data last week"
        }
        let sign = delta >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", delta)) \(unit) vs last week"
    }
    
    private var deltaColor: Color {
        if previousValue == 0 {
            return DCCColors.textSecondary
        }
        return delta >= 0 ? DCCColors.success : DCCColors.error
    }
    
    private var trendIcon: String {
        if previousValue == 0 {
            return "minus.circle.fill"
        }
        if delta > 0 {
            return "arrow.up.circle.fill"
        } else if delta < 0 {
            return "arrow.down.circle.fill"
        } else {
            return "minus.circle.fill"
        }
    }
    
    private var trendColor: Color {
        if previousValue == 0 {
            return DCCColors.textSecondary
        }
        return delta > 0 ? DCCColors.success : (delta < 0 ? DCCColors.error : DCCColors.textSecondary)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                if showTrend {
                    Image(systemName: trendIcon)
                        .font(.system(size: 20))
                        .foregroundStyle(trendColor)
                }
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(DCCColors.textSecondary)
                .multilineTextAlignment(.center)

            // Delta line (week-on-week comparison)
            if showTrend {
                Text(deltaText)
                    .font(.caption2)
                    .foregroundStyle(deltaColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview

#Preview {
    let sampleActivities = [
        Activity(
            memberName: "John Doe",
            activityName: "Morning Ride",
            distance: 45.5,
            date: Date(),
            averageSpeed: 28.5,
            elevationGain: 450,
            movingTime: 5400,
            type: "Ride"
        ),
        Activity(
            memberName: "John Doe",
            activityName: "Evening Ride",
            distance: 32.0,
            date: Date().addingTimeInterval(-86400),
            averageSpeed: 25.0,
            elevationGain: 320,
            movingTime: 4600,
            type: "Ride"
        ),
        Activity(
            memberName: "Jane Smith",
            activityName: "Long Ride",
            distance: 65.0,
            date: Date(),
            averageSpeed: 30.0,
            elevationGain: 800,
            movingTime: 7200,
            type: "Ride"
        ),
    ]
    
    let stats = [
        MemberStats(memberName: "John Doe", activities: Array(sampleActivities.prefix(2))),
        MemberStats(memberName: "Jane Smith", activities: [sampleActivities[2]]),
    ]
    
    let interval = DateRangeProvider.getLastCompletedWeek()
    let dateRange = (start: interval.start, end: interval.end)
    
    let profile = AthleteProfile(
        id: 12345,
        firstname: "John",
        lastname: "Doe",
        profile: nil,
        city: "Delhi",
        state: nil,
        country: "India"
    )
    
    return NavigationStack {
        JustMyStatsView(
            athleteProfile: profile,
            stats: stats,
            activities: sampleActivities,
            dateRange: dateRange
        )
        .navigationTitle("Just My Stats")
        .navigationBarTitleDisplayMode(.inline)
    }
}


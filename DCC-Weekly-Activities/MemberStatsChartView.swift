//
//  MemberStatsChartView.swift
//  DCC-Weekly-Activities
//
//  ChartsTab - Graphical view displaying member statistics using Swift Charts
//  SCREEN: ChartsTab
//

import SwiftUI
import Charts

struct MemberStatsChartView: View {
    let stats: [MemberStats]
    let dateRange: (start: Date, end: Date)? // Optional date range from fetched data
    let athleteProfile: AthleteProfile
    let activities: [Activity]
    
    @State private var selectedMetric: ChartMetric = .totalKM
    @State private var selectedMember: MemberStats? // For navigation
    @State private var selectedMetricForMode: MetricType?
    
    // MARK: - Metric Configuration
    
    enum MetricType: String, CaseIterable, Identifiable {
        case totalDistance = "Total Distance"
        case totalRides = "Total Rides"
        case totalElevation = "Total Elevation"
        case activeMembers = "Active Members"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .totalDistance: return "road.lanes"
            case .totalRides: return "bicycle"
            case .totalElevation: return "mountain.2.fill"
            case .activeMembers: return "person.3.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .totalDistance: return .blue
            case .totalRides: return .green
            case .totalElevation: return .orange
            case .activeMembers: return .purple
            }
        }
        
        func getValue(from stats: [MemberStats]) -> String {
            switch self {
            case .totalDistance:
                return String(format: "%.1f km", stats.reduce(0) { $0 + $1.totalKM })
            case .totalRides:
                return "\(stats.reduce(0) { $0 + $1.totalRides })"
            case .totalElevation:
                return String(format: "%.0f m", stats.reduce(0) { $0 + $1.totalElevation })
            case .activeMembers:
                return "\(stats.count)"
            }
        }
    }
    
    enum ChartMetric: String, CaseIterable {
        case totalKM = "Total KM"
        case totalRides = "Total Rides"
        case avgSpeed = "Avg Speed"
        case elevation = "Elevation"
        
        var icon: String {
            switch self {
            case .totalKM: return "road.lanes"
            case .totalRides: return "flag.checkered"
            case .avgSpeed: return "speedometer"
            case .elevation: return "mountain.2.fill"
            }
        }
        
        var unit: String {
            switch self {
            case .totalKM: return "km"
            case .totalRides: return "rides"
            case .avgSpeed: return "km/h"
            case .elevation: return "m"
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var topPerformers: [MemberStats] {
        // Show top 10 or all if less than 10
        let sorted = stats.sorted { stat1, stat2 in
            switch selectedMetric {
            case .totalKM:
                return stat1.totalKM > stat2.totalKM
            case .totalRides:
                return stat1.totalRides > stat2.totalRides
            case .avgSpeed:
                return stat1.avgSpeed > stat2.avgSpeed
            case .elevation:
                return stat1.totalElevation > stat2.totalElevation
            }
        }
        return Array(sorted.prefix(10))
    }
    
    var clubTotals: ClubTotals {
        ClubTotals(from: stats)
    }
    
    private var dateInterval: DateInterval? {
        guard let range = dateRange else { return nil }
        return DateInterval(start: range.start, end: range.end)
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // MARK: Date Range Header
                DateRangeHeaderView(dateRange: dateInterval)
                    .padding(.top, 8)
                
                Divider()
                
                // MARK: Week Summary Cards (Now Tappable!)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach([MetricType.totalDistance, .totalRides, .totalElevation, .activeMembers]) { metric in
                        TappableStatCard(
                            metric: metric,
                            stats: stats
                        )
                        .onTapGesture {
                            selectedMetricForMode = metric
                        }
                        .disabled(stats.isEmpty)
                        .opacity(stats.isEmpty ? 0.5 : 1.0)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // MARK: Metric Selector
                Picker("Metric", selection: $selectedMetric) {
                    ForEach(ChartMetric.allCases, id: \.self) { metric in
                        Label(metric.rawValue, systemImage: metric.icon)
                            .tag(metric)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // MARK: Main Bar Chart (Grouped Current/Previous Week)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top Performers")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Club totals annotation
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Club total: \(String(format: "%.1f", clubTotals.totalCurrentWeekKM))km this week")
                            .font(.subheadline)
                            .foregroundStyle(DCCColors.green)   // 5.1:1 on white — AA compliant
                        Text("vs \(String(format: "%.1f", clubTotals.totalPreviousWeekKM))km last week")
                            .font(.subheadline)
                            .foregroundStyle(DCCColors.textSecondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    
                    Chart {
                        ForEach(topPerformers) { stat in
                            // Current week bar (solid green)
                            BarMark(
                                x: .value("Member", stat.memberName),
                                y: .value(selectedMetric.rawValue, getValue(for: stat)),
                                width: .ratio(0.35)
                            )
                            .foregroundStyle(by: .value("Week", "Current"))
                            .position(by: .value("Week", "Current"))
                            .cornerRadius(6)
                            .annotation(position: .top, alignment: .center) {
                                let value = getValue(for: stat)
                                if value > 0 {
                                    VStack(spacing: 2) {
                                        Text(formatValue(value))
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.primary)
                                        
                                        Image(systemName: trendIcon(for: stat.currentWeekTrend))
                                            .font(.system(size: 12))
                                            .foregroundStyle(trendColor(for: stat.currentWeekTrend))
                                    }
                                }
                            }
                            
                            // Previous week bar (light green) - only for metrics with previous week data
                            if let previousValue = getPreviousWeekValue(for: stat) {
                                BarMark(
                                    x: .value("Member", stat.memberName),
                                    y: .value(selectedMetric.rawValue, previousValue),
                                    width: .ratio(0.35)
                                )
                                .foregroundStyle(by: .value("Week", "Previous"))
                                .position(by: .value("Week", "Previous"))
                                .cornerRadius(6)
                            }
                        }
                    }
                    .chartForegroundStyleScale([
                        "Current": .green,
                        "Previous": .green.opacity(0.4)
                    ])
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let name = value.as(String.self) {
                                    Text(name)
                                        .font(.caption2)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let val = value.as(Double.self) {
                                    Text(String(format: "%.0f", val))
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .chartLegend(position: .bottom) {
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(.green)
                                    .frame(width: 12, height: 12)
                                Text("Current Week")
                                    .font(.caption)
                            }
                            HStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(.green.opacity(0.4))
                                    .frame(width: 12, height: 12)
                                Text("Previous Week")
                                    .font(.caption)
                            }
                        }
                    }
                    .frame(height: 350)
                    .padding(.horizontal)
                    .overlay(
                        // Invisible tap overlay for bar selection
                        chartTapOverlay
                    )
                    .accessibilityLabel(chartAccessibilityLabel)
                    .accessibilityHint("Tap a bar to view that member's detailed statistics")
                }
                
                // Tap instruction
                Text("Tap any bar to view member details")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                Divider()
                
                // MARK: Distance Distribution Chart
                VStack(alignment: .leading) {
                    Text("Distance Distribution")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    let totalDistance = topPerformers.reduce(0) { $0 + $1.totalKM }
                    
                    Chart(topPerformers) { stat in
                        SectorMark(
                            angle: .value("Distance", stat.totalKM),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Member", stat.memberName))
                        .annotation(position: .overlay) {
                            let percentage = (stat.totalKM / totalDistance) * 100
                            if percentage > 3 { // Show percentage for slices > 3%
                                VStack(spacing: 2) {
                                    Text(String(format: "%.0f%%", percentage))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 0)
                                }
                            }
                        }
                    }
                    .frame(height: 300)
                    .padding(.horizontal)
                    
                    // Legend with percentages
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(topPerformers) { stat in
                                let percentage = (stat.totalKM / totalDistance) * 100
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.accentColor)
                                        .frame(width: 8, height: 8)
                                    Text(stat.memberName)
                                        .font(.caption)
                                    Text("(\(String(format: "%.1f%%", percentage)))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("DCC Weekly Activity Report — Week \(DateRangeProvider.weekNumber())")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // Refresh action - handled by parent
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        // MARK: Navigation to Member Detail
        .navigationDestination(item: $selectedMember) { member in
            MemberDetailView(memberStats: member, allStats: stats)
        }
        // MARK: Sheet for Metric Mode Selection
        .sheet(item: $selectedMetricForMode) { metric in
            MetricModeSelectionView(
                metric: metric,
                athleteProfile: athleteProfile,
                stats: stats,
                activities: activities,
                dateRange: dateRange
            )
        }
    }
    
    // MARK: - Accessibility

    private var chartAccessibilityLabel: String {
        let metricName = selectedMetric.rawValue.lowercased()
        let top = topPerformers.first?.memberName ?? "unknown"
        return "Bar chart showing \(metricName) for \(topPerformers.count) club members. Top performer is \(top). Swipe right for individual member statistics."
    }

    // MARK: - Chart Tap Overlay
    
    /// Creates an invisible overlay with tap gesture recognizer for bar selection
    private var chartTapOverlay: some View {
        GeometryReader { geometry in
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            handleChartTap(at: value.location, in: geometry.size)
                        }
                )
        }
    }
    
    /// Handles tap on chart to select member
    private func handleChartTap(at location: CGPoint, in size: CGSize) {
        // Calculate which bar was tapped based on location
        let barWidth = size.width / CGFloat(topPerformers.count)
        let tappedIndex = Int(location.x / barWidth)
        
        if tappedIndex >= 0 && tappedIndex < topPerformers.count {
            selectedMember = topPerformers[tappedIndex]
        }
    }
    
    // MARK: - Helper Methods
    
    private func getValue(for stat: MemberStats) -> Double {
        switch selectedMetric {
        case .totalKM:
            return stat.totalKM
        case .totalRides:
            return Double(stat.totalRides)
        case .avgSpeed:
            return stat.avgSpeed
        case .elevation:
            return stat.totalElevation
        }
    }
    
    private func getPreviousWeekValue(for stat: MemberStats) -> Double? {
        // Only Distance and Rides have previous week data
        switch selectedMetric {
        case .totalKM:
            return stat.previousWeekKM
        case .totalRides:
            return Double(stat.previousWeekRides)
        case .avgSpeed, .elevation:
            return nil // No previous week data available
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        switch selectedMetric {
        case .totalKM:
            return String(format: "%.1f", value)
        case .totalRides:
            return String(format: "%.0f", value)
        case .avgSpeed:
            return String(format: "%.1f", value)
        case .elevation:
            return String(format: "%.0f", value)
        }
    }
    
    // MARK: - Trend Helpers
    
    private func trendIcon(for trend: MemberStats.TrendDirection) -> String {
        switch trend {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        case .new: return "star.circle.fill"
        }
    }
    
    private func trendColor(for trend: MemberStats.TrendDirection) -> Color {
        switch trend {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        case .new: return .orange
        }
    }
}

// MARK: - Supporting Views

struct TappableStatCard: View {
    let metric: MemberStatsChartView.MetricType
    let stats: [MemberStats]
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: metric.icon)
                .font(.title2)
                .foregroundStyle(metric.color)
            
            Text(metric.getValue(from: stats))
                .font(.title2)
                .fontWeight(.bold)
            
            Text(metric.rawValue)
                .font(.caption)
                .foregroundStyle(DCCColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(metric.color.opacity(0.3), lineWidth: 2)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(metric.rawValue): \(metric.getValue(from: stats))")
        .accessibilityHint("Double tap to view breakdown by member")
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Member Detail View

struct MemberDetailView: View {
    let memberStats: MemberStats
    let allStats: [MemberStats]
    
    private var memberRanking: Int {
        let sorted = allStats.sorted { $0.totalKM > $1.totalKM }
        return (sorted.firstIndex(where: { $0.id == memberStats.id }) ?? 0) + 1
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerCard
                
                // Stats Grid
                statsGrid
                
                // Activities List
                activitiesSection
            }
            .padding()
        }
        .background(DCCColors.background.ignoresSafeArea())
        .navigationTitle(memberStats.memberName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.dccSaffron, Color.dccGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("#\(memberRanking)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Ranking")
                        .font(.caption)
                        .foregroundStyle(DCCColors.textSecondary)
                }
            }

            Text(memberStats.memberName)
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 16) {
                Label("\(memberStats.totalRides) rides", systemImage: "bicycle")
                    .font(.subheadline)
                    .foregroundStyle(DCCColors.textSecondary)

                // Trend: emoji is decorative; text label carries the meaning for VoiceOver
                HStack(spacing: 4) {
                    Text(memberStats.trendEmoji)
                        .font(.subheadline)
                        .accessibilityHidden(true)
                    Text(trendTextLabel)
                        .font(.subheadline)
                        .foregroundStyle(trendColor)
                }
                .accessibilityLabel("Trend: \(trendTextLabel)")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            statCard(
                title: "Total Distance",
                value: String(format: "%.1f km", memberStats.totalKM),
                icon: "road.lanes",
                color: Color.dccSaffron
            )
            
            statCard(
                title: "Avg Speed",
                value: String(format: "%.1f km/h", memberStats.avgSpeed),
                icon: "speedometer",
                color: Color.dccGreen
            )
            
            statCard(
                title: "Total Elevation",
                value: String(format: "%.0f m", memberStats.totalElevation),
                icon: "mountain.2.fill",
                color: Color.dccBlue
            )
            
            statCard(
                title: "Activities",
                value: "\(memberStats.totalRides)",
                icon: "figure.run",
                color: Color.purple
            )
        }
    }
    
    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activities")
                .font(.headline)
            
            ForEach(memberStats.rides.prefix(10)) { activity in
                activityRow(activity)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func activityRow(_ activity: Activity) -> some View {
        HStack(spacing: 12) {
            Image(systemName: activityIcon(for: activity.type))
                .foregroundStyle(Color.dccGreen)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.activityName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(formatDate(activity.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(String(format: "%.1f km", activity.distance))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.dccSaffron)
        }
        .padding(.vertical, 8)
    }
    
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
    
    private var trendIcon: String {
        switch memberStats.currentWeekTrend {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .stable: return "arrow.left.and.right.circle.fill"
        case .new: return "star.circle.fill"
        }
    }
    
    private var trendColor: Color {
        switch memberStats.currentWeekTrend {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        case .new: return .orange
        }
    }

    /// Plain-text trend description used as the VoiceOver label for the trend indicator.
    private var trendTextLabel: String {
        switch memberStats.currentWeekTrend {
        case .up:     return "Improving"
        case .down:   return "Declining"
        case .stable: return "Stable"
        case .new:    return "New member"
        }
    }
}

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
            memberName: "Jane Smith",
            activityName: "Evening Ride",
            distance: 32.0,
            date: Date().addingTimeInterval(-86400),
            averageSpeed: 25.0,
            elevationGain: 320,
            movingTime: 4600,
            type: "Ride"
        ),
        Activity(
            memberName: "Bob Wilson",
            activityName: "Hill Climb",
            distance: 28.5,
            date: Date(),
            averageSpeed: 22.0,
            elevationGain: 800,
            movingTime: 4200,
            type: "Ride"
        )
    ]
    
    let stats = [
        MemberStats(memberName: "John Doe", activities: [sampleActivities[0]]),
        MemberStats(memberName: "Jane Smith", activities: [sampleActivities[1]]),
        MemberStats(memberName: "Bob Wilson", activities: [sampleActivities[2]]),
    ]
    
    let dateRange = (
        start: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
        end: Date()
    )
    
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
        MemberStatsChartView(
            stats: stats,
            dateRange: dateRange,
            athleteProfile: profile,
            activities: sampleActivities
        )
        .navigationTitle("DCC Weekly")
    }
}

//
//  PerformanceZonesView.swift
//  DCC-Weekly-Activities
//
//  Animated horizontal bar charts showing best and worst performers across 4 metrics.
//  Replaces the speed-zone distribution chart in PersonalInsightsView Section 3.
//

import SwiftUI

struct PerformanceZonesView: View {
    let allStats: [MemberStats]
    let athleteProfile: AthleteProfile
    
    @State private var animationProgress: CGFloat = 0
    
    // The 4 metrics to display
    private enum MetricType {
        case speed, elevation, distance, rides
        
        var icon: String {
            switch self {
            case .speed: return "speedometer"
            case .elevation: return "mountain.2.fill"
            case .distance: return "arrow.left.and.right"
            case .rides: return "flag.checkered"
            }
        }
        
        var title: String {
            switch self {
            case .speed: return "Speed"
            case .elevation: return "Elevation"
            case .distance: return "Distance"
            case .rides: return "Rides"
            }
        }
        
        var unit: String {
            switch self {
            case .speed: return "km/h"
            case .elevation: return "m"
            case .distance: return "km"
            case .rides: return "rides"
            }
        }
        
        var emoji: String {
            switch self {
            case .speed: return "🚀"
            case .elevation: return "⛰"
            case .distance: return "📍"
            case .rides: return "🚴"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Section header
            HStack {
                Label("Performance Zones", systemImage: "chart.bar.xaxis")
                    .font(.sectionTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            
            // Four metric cards
            VStack(spacing: Spacing.md) {
                metricCard(.speed)
                metricCard(.elevation)
                metricCard(.distance)
                metricCard(.rides)
            }
        }
        .padding(.vertical, Spacing.md)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                animationProgress = 1.0
            }
        }
    }
    
    // MARK: - Metric Card
    
    @ViewBuilder
    private func metricCard(_ metric: MetricType) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Metric header
            HStack(spacing: Spacing.xs) {
                Text(metric.emoji)
                    .font(.title3)
                
                Text(metric.title)
                    .font(.cardTitle)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                
                Spacer()
                
                Image(systemName: metric.icon)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
            
            // Best performers (top half - green/accent bars)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("BEST")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.textSecondary)
                    .tracking(1.2)
                    .padding(.horizontal, Spacing.md)
                
                ForEach(bestPerformers(for: metric), id: \.memberName) { performer in
                    performerBar(
                        name: performer.memberName,
                        value: getValue(for: performer, metric: metric),
                        maxValue: getMaxValue(for: metric),
                        unit: metric.unit,
                        color: isCurrentUser(performer) ? Color.accent : Color.dccGreen,
                        isCurrentUser: isCurrentUser(performer)
                    )
                }
            }
            .padding(.bottom, Spacing.xs)
            
            Divider()
                .padding(.horizontal, Spacing.md)
            
            // Worst performers (bottom half - muted/red bars)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("NEEDS IMPROVEMENT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.textSecondary)
                    .tracking(1.2)
                    .padding(.horizontal, Spacing.md)
                
                ForEach(worstPerformers(for: metric), id: \.memberName) { performer in
                    performerBar(
                        name: performer.memberName,
                        value: getValue(for: performer, metric: metric),
                        maxValue: getMaxValue(for: metric),
                        unit: metric.unit,
                        color: isCurrentUser(performer) ? Color.accent.opacity(0.6) : Color.textSecondary.opacity(0.4),
                        isCurrentUser: isCurrentUser(performer)
                    )
                }
            }
            .padding(.bottom, Spacing.md)
        }
        .background(Color.surface)
        .cornerRadius(CornerRadius.lg)
    }
    
    // MARK: - Performer Bar
    
    @ViewBuilder
    private func performerBar(
        name: String,
        value: Double,
        maxValue: Double,
        unit: String,
        color: Color,
        isCurrentUser: Bool
    ) -> some View {
        HStack(spacing: Spacing.sm) {
            // Name
            HStack(spacing: Spacing.xs) {
                if isCurrentUser {
                    Image(systemName: "person.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.accent)
                }
                
                Text(name)
                    .font(.system(size: 12, weight: isCurrentUser ? .semibold : .regular))
                    .foregroundStyle(isCurrentUser ? Color.accent : Color.textPrimary)
                    .lineLimit(1)
            }
            .frame(width: 100, alignment: .leading)
            
            // Animated bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.surfaceElevated)
                        .frame(height: 20)
                    
                    // Foreground bar (animated)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(
                            width: geometry.size.width * (value / maxValue) * animationProgress,
                            height: 20
                        )
                }
            }
            .frame(height: 20)
            
            // Value label
            Text(formatValue(value, unit: unit))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .monospacedDigit()
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 2)
    }
    
    // MARK: - Data Helpers
    
    private func getValue(for stats: MemberStats, metric: MetricType) -> Double {
        switch metric {
        case .speed: return stats.avgSpeed
        case .elevation: return stats.totalElevation
        case .distance: return stats.totalKM
        case .rides: return Double(stats.totalRides)
        }
    }
    
    private func getMaxValue(for metric: MetricType) -> Double {
        let values = allStats.map { getValue(for: $0, metric: metric) }
        return values.max() ?? 1.0
    }
    
    private func bestPerformers(for metric: MetricType) -> [MemberStats] {
        allStats.sorted { getValue(for: $0, metric: metric) > getValue(for: $1, metric: metric) }
    }
    
    private func worstPerformers(for metric: MetricType) -> [MemberStats] {
        allStats.sorted { getValue(for: $0, metric: metric) < getValue(for: $1, metric: metric) }
    }
    
    private func isCurrentUser(_ stats: MemberStats) -> Bool {
        // Match by first name and last initial
        let userKey = "\(athleteProfile.firstname) \(String(athleteProfile.lastname.prefix(1)))."
        return stats.memberName == userKey || stats.memberName.contains(athleteProfile.firstname)
    }
    
    private func formatValue(_ value: Double, unit: String) -> String {
        if unit == "rides" {
            return "\(Int(value))"
        } else if unit == "m" {
            return "\(Int(value)) \(unit)"
        } else {
            return String(format: "%.1f %@", value, unit)
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        PerformanceZonesView(
            allStats: [
                MemberStats(
                    memberName: "Alice M.",
                    activities: [
                        Activity(
                            memberName: "Alice M.",
                            activityName: "Morning Ride",
                            distance: 50.0,
                            date: Date(),
                            averageSpeed: 28.5,
                            elevationGain: 650,
                            movingTime: 6300
                        )
                    ]
                ),
                MemberStats(
                    memberName: "Bob S.",
                    activities: [
                        Activity(
                            memberName: "Bob S.",
                            activityName: "Evening Ride",
                            distance: 45.0,
                            date: Date(),
                            averageSpeed: 25.0,
                            elevationGain: 480,
                            movingTime: 6480
                        )
                    ]
                ),
                MemberStats(
                    memberName: "Charlie K.",
                    activities: [
                        Activity(
                            memberName: "Charlie K.",
                            activityName: "Hill Climb",
                            distance: 30.0,
                            date: Date(),
                            averageSpeed: 18.5,
                            elevationGain: 850,
                            movingTime: 5832
                        )
                    ]
                )
            ],
            athleteProfile: AthleteProfile(
                id: 1,
                firstname: "Alice",
                lastname: "M.",
                profile: nil,
                city: nil,
                state: nil,
                country: nil
            )
        )
        .padding()
    }
    .background(Color.appBackground)
}

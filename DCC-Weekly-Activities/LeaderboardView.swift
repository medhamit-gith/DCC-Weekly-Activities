//
//  LeaderboardView.swift
//  DCC-Weekly-Activities
//
//  Unified Leaderboard + Overview screen showing all riders
//  Tapping a rider launches full-screen detailed analysis
//

import SwiftUI
import Charts

struct LeaderboardView: View {
    let stats: [MemberStats]
    let activities: [Activity]
    let dateRange: (start: Date, end: Date)?
    
    @State private var navigationPath = NavigationPath()
    
    private var sortedStats: [MemberStats] {
        stats.sorted { $0.totalKM > $1.totalKM }
    }
    
    private var clubTotals: ClubTotals {
        ClubTotals(from: stats)
    }
    
    private var dateInterval: DateInterval? {
        guard let range = dateRange else { return nil }
        return DateInterval(start: range.start, end: range.end)
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                if stats.isEmpty {
                    EmptyStateView(
                        icon: "figure.outdoor.cycle",
                        title: "No Activities Yet",
                        message: "Riders will appear here once they log activities"
                    )
                } else {
                    mainContent
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "trophy.fill")
                            .font(.headline)
                            .foregroundStyle(Color.dccSaffron)
                        
                        Text("Leaderboard")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.textPrimary)
                    }
                }
            }
            .navigationDestination(for: MemberStats.self) { rider in
                RiderAnalysisView(
                    rider: rider,
                    allStats: stats,
                    activities: activities
                )
            }
        }
    }
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Date Range Header
                if let interval = dateInterval {
                    DateRangeCard(interval: interval)
                        .padding(.horizontal, Spacing.md)
                }
                
                // Club Overview Cards
                ClubOverviewSection(clubTotals: clubTotals, stats: stats)
                    .padding(.horizontal, Spacing.md)
                
                // Leaderboard List
                LeaderboardListSection(stats: sortedStats)
                    .padding(.horizontal, Spacing.md)
            }
            .padding(.vertical, Spacing.md)
        }
    }
}

// MARK: - Date Range Card

private struct DateRangeCard: View {
    let interval: DateInterval
    
    var body: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundStyle(Color.accent)
            
            Text(formatDateRange())
                .font(.bodyDefault)
                .foregroundStyle(Color.textSecondary)
            
            Spacer()
            
            Text(weekLabel())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.accent)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.accent.opacity(0.15))
                )
        }
        .padding(Spacing.md)
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
    }
    
    private func formatDateRange() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: interval.start)
        let end = formatter.string(from: interval.end)
        return "\(start) - \(end)"
    }
    
    private func weekLabel() -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(interval.end) || interval.contains(Date()) {
            return "This Week"
        } else {
            return "Past Week"
        }
    }
}

// MARK: - Club Overview Section

private struct ClubOverviewSection: View {
    let clubTotals: ClubTotals
    let stats: [MemberStats]
    
    private var activeRiders: Int {
        stats.count
    }
    
    private var totalRides: Int {
        clubTotals.totalCurrentWeekRides
    }
    
    private var totalDistance: Double {
        clubTotals.totalCurrentWeekKM
    }
    
    private var avgPerRider: Double {
        activeRiders > 0 ? totalDistance / Double(activeRiders) : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Club Overview", systemImage: "chart.bar.fill")
                .font(.cardTitle)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)
            
            HStack(spacing: Spacing.md) {
                OverviewStatCard(
                    value: String(format: "%.0f", totalDistance.safeValue),
                    unit: "km",
                    label: "Total Distance",
                    icon: "road.lanes",
                    color: .dccBlue
                )
                
                OverviewStatCard(
                    value: "\(totalRides)",
                    unit: "rides",
                    label: "Total Rides",
                    icon: "figure.outdoor.cycle",
                    color: .dccSaffron
                )
            }
            
            HStack(spacing: Spacing.md) {
                OverviewStatCard(
                    value: "\(activeRiders)",
                    unit: "riders",
                    label: "Active Riders",
                    icon: "person.2.fill",
                    color: .dccGreen
                )
                
                OverviewStatCard(
                    value: String(format: "%.1f", avgPerRider.safeValue),
                    unit: "km",
                    label: "Avg per Rider",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .accent
                )
            }
        }
        .padding(Spacing.md)
        .background(Color.surface)
        .cornerRadius(CornerRadius.lg)
    }
}

private struct OverviewStatCard: View {
    let value: String
    let unit: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                
                Spacer()
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                    .monospacedDigit()
                
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(color.opacity(0.1))
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value) \(unit)")
    }
}

// MARK: - Leaderboard List Section

private struct LeaderboardListSection: View {
    let stats: [MemberStats]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Rankings", systemImage: "list.number")
                .font(.cardTitle)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, Spacing.md)
            
            VStack(spacing: Spacing.sm) {
                ForEach(Array(stats.enumerated()), id: \.element.id) { index, rider in
                    NavigationLink(value: rider) {
                        LeaderboardRowContent(rider: rider, rank: index + 1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.surface)
        .cornerRadius(CornerRadius.lg)
    }
}

private struct LeaderboardRow: View {
    let rider: MemberStats
    let rank: Int
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    private var rankIcon: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(rank)"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            LeaderboardRowContent(rider: rider, rank: rank)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .brightness(isPressed ? 0.05 : 0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

private struct LeaderboardRowContent: View {
    let rider: MemberStats
    let rank: Int
    
    private var rankIcon: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(rank)"
        }
    }
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Rank — decorative, VoiceOver reads the full row label below
            Text(rankIcon)
                .font(.system(size: 20, weight: .bold, design: .default))
                .frame(width: 40, alignment: .center)
                .accessibilityHidden(true)

            // Rider Info
            VStack(alignment: .leading, spacing: 4) {
                Text(rider.memberName)
                    .font(.bodyDefault)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)

                HStack(spacing: Spacing.sm) {
                    Label("\(rider.totalRides)", systemImage: "figure.outdoor.cycle")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)

                    Label(String(format: "%.1f km/h", rider.avgSpeed.safeValue), systemImage: "speedometer")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)

                    Label(String(format: "%.0fm", rider.totalElevation.safeValue), systemImage: "mountain.2")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            Spacer()

            // Distance
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f", rider.totalKM.safeValue))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.accent)
                    .monospacedDigit()

                Text("km")
                    .font(.caption2)
                    .foregroundStyle(Color.textSecondary)
            }

            // Chevron — decorative
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.textTertiary)
                .accessibilityHidden(true)
        }
        .padding(Spacing.md)
        .frame(minHeight: 44)  // minimum 44pt touch target
        .background(Color.surfaceElevated)
        .cornerRadius(CornerRadius.md)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rowAccessibilityLabel)
        .accessibilityHint("Double tap to view detailed analysis")
    }

    private var rowAccessibilityLabel: String {
        let rankText: String
        switch rank {
        case 1: rankText = "1st place"
        case 2: rankText = "2nd place"
        case 3: rankText = "3rd place"
        default: rankText = "Ranked \(rank)"
        }
        return "\(rider.memberName), \(rankText), \(String(format: "%.1f", rider.totalKM.safeValue)) kilometres in \(rider.totalRides) rides"
    }
}

// MARK: - Preview

#Preview {
    LeaderboardView(
        stats: [
            MemberStats(
                memberName: "Alice",
                activities: [
                    Activity(
                        memberName: "Alice",
                        activityName: "Morning Ride",
                        distance: 50.0,
                        date: Date(),
                        averageSpeed: 25.5,
                        elevationGain: 450,
                        movingTime: 7200
                    )
                ]
            ),
            MemberStats(
                memberName: "Bob",
                activities: [
                    Activity(
                        memberName: "Bob",
                        activityName: "Evening Ride",
                        distance: 45.0,
                        date: Date(),
                        averageSpeed: 23.0,
                        elevationGain: 380,
                        movingTime: 6800
                    )
                ]
            ),
            MemberStats(
                memberName: "Charlie",
                activities: [
                    Activity(
                        memberName: "Charlie",
                        activityName: "Hill Climb",
                        distance: 38.0,
                        date: Date(),
                        averageSpeed: 18.5,
                        elevationGain: 680,
                        movingTime: 7400
                    )
                ]
            )
        ],
        activities: [],
        dateRange: (start: Date().addingTimeInterval(-7*24*3600), end: Date())
    )
}

//
//  IPadMainTabView.swift
//  DCC-Weekly-Activities
//
//  Consolidated "This Week" dashboard tab — combines all week summary info
//  in a single, information-dense layout. Replaces the old Ride + Overview
//  tabs which showed the same data twice.
//
//  Layout:
//    ┌─ Date header (week label + inline week picker) ─────────────────────┐
//    │  Hero strip: 4 key club numbers (distance, rides, elev, avg speed)  │
//    ├─────────────────────────────────────────────────┬───────────────────┤
//    │  Left column (2/3):                             │  Right column     │
//    │   • Podium (top 3 riders)                       │  (1/3):           │
//    │   • Full ranked rider table                     │  • Best ride card │
//    │                                                 │  • New stats:     │
//    │                                                 │    Longest ride   │
//    │                                                 │    Fastest rider  │
//    │                                                 │    Most active    │
//    │                                                 │    Club W-o-W     │
//    │                                                 │    Total time     │
//    └─────────────────────────────────────────────────┴───────────────────┘
//

import SwiftUI

struct IPadMainTabView: View {
    let stats: [MemberStats]
    let dateRange: DateInterval?
    let athleteProfile: AthleteProfile
    let activities: [Activity]
    @Binding var selectedWeekOffset: Int
    let onWeekChanged: () -> Void

    @State private var headerAppeared = false
    @State private var heroAppeared   = false
    @State private var leftAppeared   = false
    @State private var rightAppeared  = false

    // MARK: - Derived stats

    private var sortedStats: [MemberStats] {
        stats.sorted { $0.totalKM > $1.totalKM }
    }
    private var totalKM: Double       { stats.reduce(0) { $0 + $1.totalKM } }
    private var totalRides: Int       { stats.reduce(0) { $0 + $1.totalRides } }
    private var totalElevation: Double{ stats.reduce(0) { $0 + $1.totalElevation } }
    private var clubAvgSpeed: Double  {
        let active = stats.filter { $0.avgSpeed > 0 }
        guard !active.isEmpty else { return 0 }
        return active.reduce(0) { $0 + $1.avgSpeed } / Double(active.count)
    }
    private var bestRide: Activity?   { activities.max(by: { $0.distance < $1.distance }) }
    private var longestRide: Activity? { activities.max(by: { $0.distance < $1.distance }) }
    private var fastestRide: Activity? { activities.max(by: { $0.averageSpeed < $1.averageSpeed }) }
    private var mostActiveRider: MemberStats? {
        stats.max(by: { $0.totalRides < $1.totalRides })
    }
    private var totalMovingTimeSecs: Int {
        activities.reduce(0) { $0 + $1.movingTime }
    }
    private var clubWoWDeltaKM: Double {
        let currentTotal  = stats.reduce(0) { $0 + $1.totalKM }
        let previousTotal = stats.reduce(0) { $0 + $1.previousWeekKM }
        guard previousTotal > 0 else { return 0 }
        return currentTotal - previousTotal
    }
    private var avgKMPerRider: Double {
        guard !stats.isEmpty else { return 0 }
        return totalKM / Double(stats.count)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: IPadLayout.sectionGap) {

                // ── Date header + week picker ─────────────────────────────
                dateHeader
                    .opacity(headerAppeared ? 1 : 0)
                    .offset(y: headerAppeared ? 0 : -10)

                // ── Hero stat strip ───────────────────────────────────────
                heroStrip
                    .opacity(heroAppeared ? 1 : 0)
                    .offset(y: heroAppeared ? 0 : 18)

                // ── Two-column body ───────────────────────────────────────
                HStack(alignment: .top, spacing: IPadLayout.cardGap) {
                    // Left 2/3: podium + ranked table
                    leftColumn
                        .opacity(leftAppeared ? 1 : 0)
                        .offset(x: leftAppeared ? 0 : -20)

                    // Right 1/3: best ride + highlight stats
                    rightColumn
                        .opacity(rightAppeared ? 1 : 0)
                        .offset(x: rightAppeared ? 0 : 20)
                }
            }
            .frame(maxWidth: IPadLayout.maxContentWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, IPadLayout.screenMargin)
            .padding(.vertical, IPadLayout.sectionGap)
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground.ignoresSafeArea())
        .containerBackground(Color.appBackground, for: .navigation)
        .navigationTitle("DCC Weekly Rides")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            withAnimation(.easeOut(duration: 0.35))                     { headerAppeared = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) { heroAppeared   = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.22)) { leftAppeared  = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.32)) { rightAppeared = true }
        }
    }

    // MARK: - Date Header

    @ViewBuilder
    private var dateHeader: some View {
        if let range = dateRange {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedWeekOffset == 0
                         ? "CURRENT WEEK"
                         : DateRangeProvider.weekOffsetLabel(selectedWeekOffset).uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.textSecondary)
                        .tracking(1.6)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedWeekOffset)
                    Text(DateRangeProvider.formatDateRange(range))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedWeekOffset)
                }
                Spacer()
                InlineWeekPicker(
                    selectedWeekOffset: $selectedWeekOffset,
                    onWeekChanged: onWeekChanged
                )
            }
        }
    }

    // MARK: - Hero Strip (4 club-wide numbers)

    private var heroStrip: some View {
        HStack(spacing: IPadLayout.cardGap) {
            heroTile(
                value: String(format: "%.1f", totalKM),
                unit: "km",
                label: "Club Distance",
                icon: "arrow.forward.circle.fill",
                gradient: [Color.accent, Color(hex: "#FF8C55")],
                tint: Color.accent
            )
            heroTile(
                value: "\(totalRides)",
                unit: "rides",
                label: "Total Rides",
                icon: "flag.checkered.2.crossed",
                gradient: [Color.dccGreen, Color(hex: "#34D399")],
                tint: Color.dccGreen
            )
            heroTile(
                value: String(format: "%.0f", totalElevation),
                unit: "m",
                label: "Elevation",
                icon: "mountain.2.fill",
                gradient: [Color.dccBlue, Color(hex: "#60A5FA")],
                tint: Color.dccBlue
            )
            heroTile(
                value: String(format: "%.1f", clubAvgSpeed),
                unit: "km/h",
                label: "Club Avg Speed",
                icon: "speedometer",
                gradient: [Color.dccSaffron, Color(hex: "#FCD34D")],
                tint: Color.dccSaffron
            )
        }
    }

    private func heroTile(
        value: String,
        unit: String,
        label: String,
        icon: String,
        gradient: [Color],
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(gradient.first ?? tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                Spacer()
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text(unit)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .padding(.bottom, 3)
            }
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.textSecondary)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .glassEffect(.regular.tint(tint.opacity(0.10)), in: .rect(cornerRadius: IPadLayout.cardCornerRadius))
    }

    // MARK: - Left Column: Podium + Ranked Table

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: IPadLayout.sectionGap) {
            // Podium (top 3)
            if sortedStats.count >= 3 {
                podiumSection
            }
            // Full weekly rider table
            weeklyTableSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var podiumSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            IPadSectionHeader(title: "Podium", icon: "trophy.fill", color: .dccSaffron)
            HStack(spacing: IPadLayout.cardGap) {
                // 2nd, 1st, 3rd ordering
                podiumCard(rank: 2, rider: sortedStats[1])
                podiumCard(rank: 1, rider: sortedStats[0])
                podiumCard(rank: 3, rider: sortedStats[2])
            }
        }
    }

    private func podiumCard(rank: Int, rider: MemberStats) -> some View {
        let rankColor: Color = rank == 1 ? Color(hex: "#FFD700") : rank == 2 ? Color(hex: "#C0C0C0") : Color(hex: "#CD7F32")
        let medal = rank == 1 ? "👑" : rank == 2 ? "🥈" : "🥉"
        let height: CGFloat = rank == 1 ? 130 : 110

        return VStack(spacing: 6) {
            Text(medal).font(.system(size: rank == 1 ? 26 : 20))
            Text(rider.memberName.components(separatedBy: " ").first ?? rider.memberName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.1f", rider.totalKM))
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(rankColor)
                Text("km")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
            }
            Text("\(rider.totalRides) ride\(rider.totalRides == 1 ? "" : "s")")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.textSecondary)
            // W-o-W trend badge
            trendBadge(rider: rider)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .glassEffect(.regular.tint(rankColor.opacity(0.10)), in: .rect(cornerRadius: 14))
    }

    private func trendBadge(rider: MemberStats) -> some View {
        let delta = rider.totalKM - rider.previousWeekKM
        let hasPrevious = rider.previousWeekKM > 0
        guard hasPrevious else {
            return AnyView(
                Text("NEW")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.dccGreen)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.dccGreen.opacity(0.15))
                    .clipShape(Capsule())
            )
        }
        let pct = (delta / rider.previousWeekKM) * 100
        let color: Color = delta > 0 ? .dccGreen : delta < 0 ? .red : .textSecondary
        let arrow = delta > 0 ? "↑" : delta < 0 ? "↓" : "→"
        return AnyView(
            Text("\(arrow)\(String(format: "%.0f", abs(pct)))%")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(color)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(color.opacity(0.15))
                .clipShape(Capsule())
        )
    }

    private var weeklyTableSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            IPadSectionHeader(title: "Weekly Report", icon: "tablecells.fill", color: .dccBlue)
            WeeklyReportTableView(stats: stats)
        }
    }

    // MARK: - Right Column: Best Ride + Highlight Stats

    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: IPadLayout.sectionGap) {
            bestRideSection
            highlightStatsSection
        }
        .frame(maxWidth: 320, alignment: .leading)
    }

    @ViewBuilder
    private var bestRideSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            IPadSectionHeader(title: "Best Ride", icon: "star.fill", color: .dccSaffron)
            if let ride = bestRide {
                IPadBestRideCard(activity: ride)
            } else {
                emptyRideState
            }
        }
    }

    private var emptyRideState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "bicycle")
                .font(.system(size: 36))
                .foregroundStyle(Color.textTertiary)
            Text("No rides yet this week")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .glassEffect(.regular.tint(.white.opacity(0.03)), in: .rect(cornerRadius: IPadLayout.cardCornerRadius))
    }

    // MARK: - Highlight Stats (new, not shown elsewhere)

    private var highlightStatsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            IPadSectionHeader(title: "Highlights", icon: "bolt.circle.fill", color: .accent)

            // Fastest rider
            if let fastest = fastestRide {
                highlightRow(
                    icon: "hare.fill",
                    label: "Fastest Rider",
                    value: String(format: "%.1f km/h", fastest.averageSpeed),
                    sub: fastest.memberName,
                    color: .dccSaffron
                )
            }

            // Longest single ride
            if let longest = longestRide {
                highlightRow(
                    icon: "arrow.up.right.circle.fill",
                    label: "Longest Ride",
                    value: String(format: "%.1f km", longest.distance),
                    sub: longest.memberName,
                    color: .accent
                )
            }

            // Most active rider (by ride count)
            if let mostActive = mostActiveRider, mostActive.totalRides > 1 {
                highlightRow(
                    icon: "repeat.circle.fill",
                    label: "Most Active",
                    value: "\(mostActive.totalRides) rides",
                    sub: mostActive.memberName,
                    color: .dccGreen
                )
            }

            // Club week-on-week delta
            if clubWoWDeltaKM != 0 {
                let sign = clubWoWDeltaKM > 0 ? "+" : ""
                let color: Color = clubWoWDeltaKM > 0 ? .dccGreen : .red
                highlightRow(
                    icon: clubWoWDeltaKM > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                    label: "vs Last Week",
                    value: "\(sign)\(String(format: "%.1f", clubWoWDeltaKM)) km",
                    sub: clubWoWDeltaKM > 0 ? "Club is improving" : "Club is down",
                    color: color
                )
            }

            // Avg km per rider
            highlightRow(
                icon: "person.fill.checkmark",
                label: "Avg per Rider",
                value: String(format: "%.1f km", avgKMPerRider),
                sub: "\(stats.count) active riders",
                color: .dccBlue
            )

            // Total saddle time
            if totalMovingTimeSecs > 0 {
                highlightRow(
                    icon: "timer.circle.fill",
                    label: "Total Saddle Time",
                    value: formatDuration(totalMovingTimeSecs),
                    sub: "Combined riding time",
                    color: .dccSaffron
                )
            }
        }
    }

    private func highlightRow(
        icon: String,
        label: String,
        value: String,
        sub: String,
        color: Color
    ) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
                Text(value)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text(sub)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(Spacing.md)
        .glassEffect(.regular.tint(color.opacity(0.07)), in: .rect(cornerRadius: IPadLayout.cardCornerRadius))
    }

    // MARK: - Helpers

    private func formatDuration(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

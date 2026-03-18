// RiderProfileView.swift
// DCC-Weekly-Activities
//
// Full-screen rider profile pushed from DashboardView.
// Shows: stat comparison vs club, per-ride chart, percentile ranks,
// and a personalised "Where to improve" coaching section.

import SwiftUI
import Charts

#if os(tvOS)
// Stub to satisfy the compiler on tvOS — full profile view is iOS/iPadOS/macOS only.
struct RiderProfileView: View {
    let member:   MemberStats
    let allStats: [MemberStats]
    var body: some View { EmptyView() }
}

#else

// MARK: - Main View

struct RiderProfileView: View {
    let member:   MemberStats
    let allStats: [MemberStats]

    // Derived club-wide numbers (excluding this rider)
    private var clubAvgKM: Double {
        let others = allStats.filter { $0.id != member.id }
        guard !others.isEmpty else { return 0 }
        return others.reduce(0) { $0 + $1.totalKM } / Double(others.count)
    }
    private var clubAvgSpeed: Double {
        let others = allStats.filter { $0.id != member.id && $0.avgSpeed > 0 }
        guard !others.isEmpty else { return 0 }
        return others.reduce(0) { $0 + $1.avgSpeed } / Double(others.count)
    }
    private var clubAvgElevation: Double {
        let others = allStats.filter { $0.id != member.id }
        guard !others.isEmpty else { return 0 }
        return others.reduce(0) { $0 + $1.totalElevation } / Double(others.count)
    }
    private var clubAvgRides: Double {
        let others = allStats.filter { $0.id != member.id }
        guard !others.isEmpty else { return 0 }
        return Double(others.reduce(0) { $0 + $1.totalRides }) / Double(others.count)
    }

    // Percentile rank — what % of riders this member beats
    private func percentile(value: Double, keyPath: KeyPath<MemberStats, Double>) -> Int {
        let all = allStats.map { $0[keyPath: keyPath] }
        guard all.count > 1 else { return 100 }
        let below = all.filter { $0 < value }.count
        return Int(Double(below) / Double(all.count - 1) * 100)
    }

    private var kmPercentile:        Int { percentile(value: member.totalKM,        keyPath: \.totalKM) }
    private var speedPercentile:     Int { percentile(value: member.avgSpeed,       keyPath: \.avgSpeed) }
    private var elevationPercentile: Int { percentile(value: member.totalElevation, keyPath: \.totalElevation) }

    // Club rank position
    private var kmRank: Int {
        (allStats.sorted { $0.totalKM > $1.totalKM }.firstIndex { $0.id == member.id } ?? 0) + 1
    }

    @State private var barsVisible = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: DS.Spacing.lg) {

                // ── Header ────────────────────────────────────────────
                headerSection

                // ── This Week at a Glance ─────────────────────────────
                glanceSection

                // ── vs Club Average ───────────────────────────────────
                vsClubSection

                // ── Percentile Ranking ────────────────────────────────
                percentileSection

                // ── Per-Ride Distance Chart ───────────────────────────
                if !member.rides.isEmpty {
                    rideChartSection
                }

                // ── Where to Improve ──────────────────────────────────
                improvementSection

                // ── This Week's Rides (full list) ─────────────────────
                ridesListSection

                Spacer().frame(height: DS.Spacing.xxl)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.top, DS.Spacing.sm)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(member.memberName)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation { barsVisible = true }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: DS.Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.dccAccent, Color.dccGreenAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                Text(member.initials)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .shadow(color: Color.dccAccent.opacity(0.3), radius: 8, y: 3)

            VStack(alignment: .leading, spacing: 4) {
                Text(member.memberName)
                    .font(.title2.bold())
                    .foregroundStyle(Color.labelPrimary)

                HStack(spacing: DS.Spacing.xs) {
                    trendBadge
                    Text("Rank #\(kmRank) of \(allStats.count)")
                        .font(.dccCaption)
                        .foregroundStyle(Color.labelSecondary)
                        .padding(.horizontal, DS.Spacing.xs)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.labelTertiary.opacity(0.12)))
                }
            }
            Spacer()
        }
        .padding(DS.Spacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg))
        .glassEffect(.regular.tint(Color.dccAccent.opacity(0.04)), in: .rect(cornerRadius: DS.Radius.lg))
    }

    @ViewBuilder private var trendBadge: some View {
        let (label, color): (String, Color) = {
            switch member.currentWeekTrend {
            case .up:     return ("↑ Improving", Color.statusUp)
            case .down:   return ("↓ Declining", Color.statusDown)
            case .stable: return ("→ Stable",    Color.statusStable)
            case .new:    return ("★ New",        Color.statusNew)
            }
        }()
        Text(label)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, DS.Spacing.xs)
            .padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.14)))
    }

    // MARK: - This Week at a Glance (4-tile grid)

    private var glanceSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionHeader("This Week", icon: "calendar")

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: DS.Spacing.sm
            ) {
                GlanceTile(icon: "road.lanes",  value: String(format: "%.1f km",   member.totalKM),        label: "Distance")
                GlanceTile(icon: "bicycle",      value: "\(member.totalRides) rides",                        label: "Rides")
                GlanceTile(icon: "speedometer",  value: String(format: "%.1f km/h", member.avgSpeed),       label: "Avg Speed")
                GlanceTile(icon: "mountain.2",   value: String(format: "%.0f m",    member.totalElevation), label: "Elevation")
            }
        }
    }

    // MARK: - vs Club Average

    private var vsClubSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionHeader("vs. Club Average", icon: "person.3")

            VStack(spacing: DS.Spacing.xs) {
                ComparisonRow(
                    label:      "Distance",
                    icon:       "road.lanes",
                    riderValue: member.totalKM,
                    clubValue:  clubAvgKM,
                    unit:       "km",
                    format:     "%.1f",
                    barsVisible: barsVisible
                )
                Divider().padding(.leading, 36)
                ComparisonRow(
                    label:      "Avg Speed",
                    icon:       "speedometer",
                    riderValue: member.avgSpeed,
                    clubValue:  clubAvgSpeed,
                    unit:       "km/h",
                    format:     "%.1f",
                    barsVisible: barsVisible
                )
                Divider().padding(.leading, 36)
                ComparisonRow(
                    label:      "Elevation",
                    icon:       "mountain.2",
                    riderValue: member.totalElevation,
                    clubValue:  clubAvgElevation,
                    unit:       "m",
                    format:     "%.0f",
                    barsVisible: barsVisible
                )
                Divider().padding(.leading, 36)
                ComparisonRow(
                    label:      "Rides",
                    icon:       "bicycle",
                    riderValue: Double(member.totalRides),
                    clubValue:  clubAvgRides,
                    unit:       "",
                    format:     "%.0f",
                    barsVisible: barsVisible
                )
            }
            .padding(DS.Spacing.md)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
            .glassEffect(.regular.tint(Color.dccAccent.opacity(0.04)), in: .rect(cornerRadius: DS.Radius.md))
        }
    }

    // MARK: - Percentile Ranking

    private var percentileSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionHeader("Club Ranking", icon: "trophy")

            HStack(spacing: DS.Spacing.sm) {
                PercentileTile(label: "Distance",  percentile: kmPercentile,        color: .dccAccent)
                PercentileTile(label: "Speed",     percentile: speedPercentile,     color: Color.statusUp)
                PercentileTile(label: "Elevation", percentile: elevationPercentile, color: Color.dccGreenAccent)
            }
        }
    }

    // MARK: - Per-Ride Chart

    private var rideChartSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionHeader("Rides This Week", icon: "chart.bar")

            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Chart(member.rides) { ride in
                    BarMark(
                        x: .value("Ride", rideLabel(ride)),
                        y: .value("Distance (km)", ride.distance)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.dccAccent, Color.dccAccent.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(6)
                    .annotation(position: .top) {
                        Text(String(format: "%.0f", ride.distance))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.labelSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(Color.labelTertiary.opacity(0.4))
                        AxisValueLabel {
                            if let km = value.as(Double.self) {
                                Text("\(Int(km)) km")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.labelSecondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.system(size: 10))
                    }
                }
                .frame(height: 180)

                // Club avg line legend
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(Color.labelTertiary.opacity(0.5))
                        .frame(width: 20, height: 1.5)
                    Text(String(format: "Club avg %.0f km", clubAvgKM))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.labelSecondary)
                }
            }
            .padding(DS.Spacing.md)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
            .glassEffect(.regular.tint(Color.dccAccent.opacity(0.04)), in: .rect(cornerRadius: DS.Radius.md))
        }
    }

    private func rideLabel(_ ride: ClubActivity) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: ride.date)
    }

    // MARK: - Where to Improve

    private var improvementSection: some View {
        let tips = improvementTips()
        guard !tips.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                sectionHeader("Where to Improve", icon: "lightbulb")

                VStack(spacing: DS.Spacing.xs) {
                    ForEach(Array(tips.enumerated()), id: \.offset) { _, tip in
                        ImprovementRow(tip: tip)
                    }
                }
                .padding(DS.Spacing.md)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                .glassEffect(.regular.tint(Color.dccAccent.opacity(0.04)), in: .rect(cornerRadius: DS.Radius.md))
            }
        )
    }

    private func improvementTips() -> [ImprovementTip] {
        var tips: [ImprovementTip] = []

        // Distance gap
        let kmGap = clubAvgKM - member.totalKM
        if kmGap > 5 {
            tips.append(ImprovementTip(
                icon: "road.lanes",
                color: Color.dccAccent,
                title: "Boost weekly distance",
                detail: String(format: "You're %.0f km below the club average (%.0f km). Try adding one more ride per week.", kmGap, clubAvgKM)
            ))
        } else if member.totalKM > clubAvgKM * 1.2 {
            tips.append(ImprovementTip(
                icon: "road.lanes",
                color: Color.statusUp,
                title: "Distance — leading the pack",
                detail: String(format: "You're %.0f km above the club average. Great work — focus on sustaining it.", member.totalKM - clubAvgKM)
            ))
        }

        // Speed gap
        let speedGap = clubAvgSpeed - member.avgSpeed
        if clubAvgSpeed > 0 && speedGap > 1.5 {
            tips.append(ImprovementTip(
                icon: "speedometer",
                color: Color.dccAccent.opacity(0.8),
                title: "Work on average speed",
                detail: String(format: "Your pace (%.1f km/h) is %.1f km/h slower than the club average. Interval training or flatter routes can help.", member.avgSpeed, speedGap)
            ))
        } else if clubAvgSpeed > 0 && member.avgSpeed > clubAvgSpeed + 1.5 {
            tips.append(ImprovementTip(
                icon: "speedometer",
                color: Color.statusUp,
                title: "Speed — above average",
                detail: String(format: "Your average pace (%.1f km/h) is %.1f km/h faster than the club. Consider longer endurance rides.", member.avgSpeed, member.avgSpeed - clubAvgSpeed)
            ))
        }

        // Elevation gap
        let elevGap = clubAvgElevation - member.totalElevation
        if elevGap > 50 {
            tips.append(ImprovementTip(
                icon: "mountain.2",
                color: Color.dccGreenAccent,
                title: "Add more climbing",
                detail: String(format: "Your elevation (%.0f m) is %.0f m below the club average. Hill routes will strengthen your legs and improve stamina.", member.totalElevation, elevGap)
            ))
        }

        // Consistency — few rides
        if member.totalRides == 1 {
            tips.append(ImprovementTip(
                icon: "calendar.badge.plus",
                color: Color.statusNew,
                title: "Ride more consistently",
                detail: "You logged 1 ride this week. Spreading rides across the week builds endurance faster than a single long effort."
            ))
        } else if Double(member.totalRides) < clubAvgRides - 1 {
            tips.append(ImprovementTip(
                icon: "calendar.badge.plus",
                color: Color.statusNew,
                title: "Increase ride frequency",
                detail: String(format: "You rode %d times vs. the club average of %.0f. More shorter rides can improve your weekly total.", member.totalRides, clubAvgRides)
            ))
        }

        // All good — no negative tips
        if tips.isEmpty {
            tips.append(ImprovementTip(
                icon: "checkmark.seal.fill",
                color: Color.statusUp,
                title: "Above average across the board",
                detail: "You're beating the club average on distance, speed, and elevation. Keep pushing!"
            ))
        }

        return tips
    }

    // MARK: - Full Rides List

    private var ridesListSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            sectionHeader("All Rides (\(member.rides.count))", icon: "list.bullet")

            VStack(spacing: 0) {
                ForEach(Array(member.rides.enumerated()), id: \.element.id) { idx, ride in
                    DetailedRideRow(ride: ride, rank: idx + 1)
                    if idx < member.rides.count - 1 {
                        Divider().padding(.leading, DS.Spacing.md)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Color.labelPrimary)
    }
}

// MARK: - Sub-views

private struct GlanceTile: View {
    let icon:  String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: DS.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.dccAccent)
            Text(value)
                .font(.dccMetricSmall)
                .foregroundStyle(Color.labelPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.dccMicro)
                .foregroundStyle(Color.labelSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.lg)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        .glassEffect(.regular.tint(Color.dccAccent.opacity(0.05)), in: .rect(cornerRadius: DS.Radius.md))
    }
}

private struct ComparisonRow: View {
    let label:       String
    let icon:        String
    let riderValue:  Double
    let clubValue:   Double
    let unit:        String
    let format:      String
    let barsVisible: Bool

    private var isAhead: Bool { riderValue >= clubValue }
    private var maxVal:  Double { max(riderValue, clubValue, 1) }

    var body: some View {
        VStack(spacing: 6) {
            // Labels row
            HStack {
                Label(label, systemImage: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.labelPrimary)
                Spacer()
                HStack(spacing: 4) {
                    Text(String(format: format, riderValue) + (unit.isEmpty ? "" : " \(unit)"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isAhead ? Color.statusUp : Color.dccAccent)
                    Image(systemName: isAhead ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isAhead ? Color.statusUp : Color.labelSecondary)
                    Text("avg \(String(format: format, clubValue))")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.labelSecondary)
                }
            }

            // Dual bar
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    // Club avg bar (background)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.labelTertiary.opacity(0.15))
                        .frame(
                            width: barsVisible ? max(4, w * (clubValue / maxVal)) : 0,
                            height: 8
                        )
                        .animation(DS.Motion.standard.delay(0.05), value: barsVisible)

                    // Rider bar (foreground)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isAhead
                              ? LinearGradient(colors: [Color.statusUp, Color.statusUp.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                              : LinearGradient(colors: [Color.dccAccent, Color.dccAccent.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                        .frame(
                            width: barsVisible ? max(4, w * (riderValue / maxVal)) : 0,
                            height: 8
                        )
                        .animation(DS.Motion.standard, value: barsVisible)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, DS.Spacing.xs)
    }
}

private struct PercentileTile: View {
    let label:      String
    let percentile: Int
    let color:      Color

    private var tier: String {
        switch percentile {
        case 80...100: return "Top 20%"
        case 60..<80:  return "Top 40%"
        case 40..<60:  return "Middle"
        case 20..<40:  return "Lower"
        default:       return "Bottom"
        }
    }

    var body: some View {
        VStack(spacing: DS.Spacing.xs) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 5)
                    .frame(width: 56, height: 56)
                Circle()
                    .trim(from: 0, to: CGFloat(percentile) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
                Text("\(percentile)%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.labelPrimary)
            }
            Text(label)
                .font(.dccMicro)
                .foregroundStyle(Color.labelSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
            Text(tier)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        .glassEffect(.regular.tint(color.opacity(0.05)), in: .rect(cornerRadius: DS.Radius.md))
    }
}

struct ImprovementTip: Identifiable {
    let id    = UUID()
    let icon:   String
    let color:  Color
    let title:  String
    let detail: String
}

private struct ImprovementRow: View {
    let tip: ImprovementTip

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.sm) {
            Image(systemName: tip.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(tip.color)
                .frame(width: 32, height: 32)
                .background(Circle().fill(tip.color.opacity(0.12)))

            VStack(alignment: .leading, spacing: 3) {
                Text(tip.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.labelPrimary)
                Text(tip.detail)
                    .font(.dccCaption)
                    .foregroundStyle(Color.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, DS.Spacing.xs)
    }
}

private struct DetailedRideRow: View {
    let ride: ClubActivity
    let rank: Int

    private var activityIcon: String {
        switch ride.type.lowercased() {
        case "run":  return "figure.run"
        case "walk": return "figure.walk"
        default:     return "figure.outdoor.cycle"
        }
    }

    private var formattedTime: String {
        guard ride.movingTime > 0 else { return "" }
        let h = ride.movingTime / 3600
        let m = (ride.movingTime % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: activityIcon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.dccAccent)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.dccAccent.opacity(0.1)))

            VStack(alignment: .leading, spacing: 2) {
                Text(ride.activityName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.labelPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(ride.formattedDate)
                        .font(.dccCaption)
                        .foregroundStyle(Color.labelSecondary)
                    if !formattedTime.isEmpty {
                        Text("·")
                            .foregroundStyle(Color.labelTertiary)
                        Text(formattedTime)
                            .font(.dccCaption)
                            .foregroundStyle(Color.labelSecondary)
                    }
                    if ride.elevationGain > 0 {
                        Text("·")
                            .foregroundStyle(Color.labelTertiary)
                        Label(String(format: "%.0f m", ride.elevationGain), systemImage: "mountain.2")
                            .font(.dccCaption)
                            .foregroundStyle(Color.labelSecondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f km", ride.distance))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.labelPrimary)
                if ride.averageSpeed > 0 {
                    Text(String(format: "%.1f km/h", ride.averageSpeed))
                        .font(.dccCaption)
                        .foregroundStyle(Color.labelSecondary)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
    }
}

#endif // os(tvOS) / !os(tvOS)

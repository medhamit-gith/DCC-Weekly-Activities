// DashboardView.swift
// DCC-Weekly-Activities
//
// Main dashboard for iOS. Replaces the old Charts/Table/Activities tab system.
// Architecture: NavigationStack → ScrollView → sections.
// No nested navigation. No deep hierarchies.

import SwiftUI
import Charts

#if !os(tvOS)

// MARK: - Root Dashboard

struct DashboardView: View {
    let activities:  [ClubActivity]
    let memberStats: [MemberStats]
    let dateRange:   (start: Date, end: Date)?
    let isLoading:   Bool
    let onRefresh:   () async -> Void
    let onLogout:    () -> Void

    @State private var selectedMember:   MemberStats?
    @State private var showAllMembers  = false
    @State private var barsVisible     = false
    @State private var cardsVisible    = false

    var body: some View {
        #if DEBUG
        let _ = print("🏠 [DashboardView] body evaluated — memberStats: \(memberStats.count), selectedMember: \(selectedMember?.memberName ?? "nil")")
        #endif
        return NavigationStack {
            ZStack {
                // Layer 0 — background gradient
                backgroundGradient.ignoresSafeArea()

                if isLoading {
                    loadingState
                } else if activities.isEmpty {
                    emptyState
                } else {
                    contentScroll
                }
            }
            .navigationTitle("This Week")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarItems }
            .refreshable {
                DS.haptic(.medium)
                await onRefresh()
            }
            .sheet(item: $selectedMember) { member in
                #if DEBUG
                let _ = print("📋 [DashboardView] sheet closure fired for: \(member.memberName)")
                #endif
                return MemberDetailSheet(member: member)
            }
        }
        .onAppear {
            #if DEBUG
            print("🏠 [DashboardView] onAppear — memberStats: \(memberStats.count), activities: \(activities.count)")
            #endif
        }
    }

    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemGroupedBackground),
                Color(.systemGroupedBackground).opacity(0.95)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                DS.haptic(.light)
                onLogout()
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.labelSecondary)
            }
            .accessibilityLabel("Log out")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                DS.haptic(.light)
                Task { await onRefresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.dccAccent)
            }
            .accessibilityLabel("Refresh data")
        }
    }

    // MARK: - Main scroll content
    private var contentScroll: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: DS.Spacing.lg) {
                // Date range pill
                if let range = dateRange {
                    dateRangePill(range)
                }

                // Hero — total KM ring + mini metrics
                HeroCard(stats: memberStats, activities: activities)
                    .opacity(cardsVisible ? 1 : 0)
                    .offset(y: cardsVisible ? 0 : 16)
                    .animation(DS.Motion.standard, value: cardsVisible)

                // Top performers bar chart
                TopPerformersCard(
                    stats: memberStats,
                    barsVisible: barsVisible,
                    onMemberTap: { member in
                        #if DEBUG
                        print("👆 [DashboardView] onMemberTap fired for: \(member.memberName)")
                        #endif
                        DS.haptic(.medium)
                        selectedMember = member
                        #if DEBUG
                        print("👆 [DashboardView] selectedMember set to: \(selectedMember?.memberName ?? "nil")")
                        #endif
                    },
                    showAllMembers: $showAllMembers
                )
                .opacity(cardsVisible ? 1 : 0)
                .offset(y: cardsVisible ? 0 : 24)
                .animation(DS.Motion.standard.delay(0.08), value: cardsVisible)

                // Recent activities
                RecentActivitiesCard(activities: activities)
                    .opacity(cardsVisible ? 1 : 0)
                    .offset(y: cardsVisible ? 0 : 32)
                    .animation(DS.Motion.standard.delay(0.15), value: cardsVisible)

                Spacer().frame(height: DS.Spacing.xxl)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.top, DS.Spacing.sm)
        }
        .onAppear {
            cardsVisible = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                barsVisible = true
            }
        }
    }

    // MARK: - Date pill
    private func dateRangePill(_ range: (start: Date, end: Date)) -> some View {
        Text(formatRange(range.start, range.end))
            .font(.dccCaption)
            .foregroundStyle(Color.labelSecondary)
            .padding(.horizontal, DS.Spacing.sm)
            .padding(.vertical, DS.Spacing.xxs)
            .background(
                Capsule().fill(Color.cardBackground)
            )
            .glassEffect(.regular.tint(Color.dccAccent.opacity(0.06)), in: .capsule)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Loading state
    private var loadingState: some View {
        VStack(spacing: DS.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.4)
                .tint(Color.dccAccent)
            Text("Loading rides…")
                .font(.dccCaption)
                .foregroundStyle(Color.labelSecondary)
        }
    }

    // MARK: - Empty state
    private var emptyState: some View {
        VStack(spacing: DS.Spacing.xl) {
            Spacer()
            Image(systemName: "bicycle.circle")
                .font(.system(size: 72, weight: .thin))
                .foregroundStyle(Color.labelTertiary)

            VStack(spacing: DS.Spacing.xs) {
                Text("No rides this week")
                    .font(.dccSectionTitle)
                    .foregroundStyle(Color.labelPrimary)
                Text("Everyone's resting — check back after\nyour next ride.")
                    .font(.dccCaption)
                    .foregroundStyle(Color.labelSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                DS.haptic(.medium)
                Task { await onRefresh() }
            } label: {
                Label("Sync Now", systemImage: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, DS.Spacing.xl)
                    .padding(.vertical, DS.Spacing.sm)
            }
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.sm)
                    .fill(Color.dccAccent)
            )
            .glassEffect(.regular.tint(Color.dccAccent.opacity(0.15)).interactive(), in: .rect(cornerRadius: DS.Radius.sm))
            Spacer()
        }
        .padding(.horizontal, DS.Spacing.xl)
    }

    private func formatRange(_ start: Date, _ end: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return "\(f.string(from: start)) – \(f.string(from: end))"
    }
}

// MARK: - Hero Card

private struct HeroCard: View {
    let stats:      [MemberStats]
    let activities: [ClubActivity]

    private var totalKM:        Double { stats.reduce(0) { $0 + $1.totalKM } }
    private var totalRides:     Int    { stats.reduce(0) { $0 + $1.totalRides } }
    private var activeMembers:  Int    { stats.count }
    private var totalElevation: Double { stats.reduce(0) { $0 + $1.totalElevation } }

    @State private var ringVisible = false

    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            // Ring + big number
            ZStack {
                // Background ring track
                Circle()
                    .stroke(Color.labelTertiary.opacity(0.15), lineWidth: 18)
                    .frame(width: 180, height: 180)

                // Animated progress ring
                Circle()
                    .trim(from: 0, to: ringVisible ? min(totalKM / 500.0, 1.0) : 0)
                    .stroke(
                        AngularGradient(
                            colors: [Color.dccAccent, Color.dccAccent.opacity(0.55)],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.0, dampingFraction: 0.8), value: ringVisible)

                // Center text
                VStack(spacing: 2) {
                    Text(String(format: "%.0f", totalKM))
                        .font(.dccMetricLarge)
                        .foregroundStyle(Color.labelPrimary)
                    Text("kilometres")
                        .font(.dccMicro)
                        .foregroundStyle(Color.labelSecondary)
                        .textCase(.uppercase)
                        .tracking(0.8)
                }
            }
            .onAppear { ringVisible = true }

            Divider()
                .padding(.horizontal, DS.Spacing.lg)

            // Three mini metrics
            HStack(spacing: 0) {
                MiniMetricTile(
                    icon: "bicycle",
                    value: "\(totalRides)",
                    label: "Rides"
                )
                Divider().frame(height: 36)
                MiniMetricTile(
                    icon: "person.3",
                    value: "\(activeMembers)",
                    label: "Riders"
                )
                Divider().frame(height: 36)
                MiniMetricTile(
                    icon: "mountain.2",
                    value: String(format: "%.0fm", totalElevation),
                    label: "Elevation"
                )
            }
        }
        .padding(.vertical, DS.Spacing.xl)
        .padding(.horizontal, DS.Spacing.md)
        .dsCard(prominent: true)
        .glassEffect(.regular.tint(Color.dccAccent.opacity(0.04)), in: .rect(cornerRadius: DS.Radius.lg))
    }
}

private struct MiniMetricTile: View {
    let icon:  String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: DS.Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.dccAccent)
            Text(value)
                .font(.dccMetricSmall)
                .foregroundStyle(Color.labelPrimary)
            Text(label)
                .font(.dccMicro)
                .foregroundStyle(Color.labelSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Top Performers Card

private struct TopPerformersCard: View {
    let stats:           [MemberStats]
    let barsVisible:     Bool
    let onMemberTap:     (MemberStats) -> Void
    @Binding var showAllMembers: Bool

    enum SortMode: String, CaseIterable {
        case distance  = "Distance"
        case speed     = "Speed"
        case elevation = "Elevation"

        var icon: String {
            switch self {
            case .distance:  return "road.lanes"
            case .speed:     return "speedometer"
            case .elevation: return "mountain.2"
            }
        }
    }

    @State private var sortMode: SortMode = .distance

    private var sorted: [MemberStats] {
        switch sortMode {
        case .distance:  return stats.sorted { $0.totalKM        > $1.totalKM }
        case .speed:     return stats.sorted { $0.avgSpeed       > $1.avgSpeed }
        case .elevation: return stats.sorted { $0.totalElevation > $1.totalElevation }
        }
    }

    private var displayed: [MemberStats] {
        showAllMembers ? sorted : Array(sorted.prefix(5))
    }

    private var maxValue: Double {
        switch sortMode {
        case .distance:  return sorted.first?.totalKM        ?? 1
        case .speed:     return sorted.first?.avgSpeed       ?? 1
        case .elevation: return sorted.first?.totalElevation ?? 1
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            // Section header row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Top Performers")
                        .font(.dccSectionTitle)
                        .foregroundStyle(Color.labelPrimary)
                    Text("\(stats.count) members rode this week")
                        .font(.dccCaption)
                        .foregroundStyle(Color.labelSecondary)
                }
                Spacer()
                if stats.count > 5 {
                    Button(showAllMembers ? "Less" : "See All") {
                        DS.hapticSelect()
                        withAnimation(DS.Motion.standard) { showAllMembers.toggle() }
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.dccAccent)
                }
            }

            // Sort picker
            HStack(spacing: DS.Spacing.xs) {
                ForEach(SortMode.allCases, id: \.self) { mode in
                    Button {
                        DS.hapticSelect()
                        withAnimation(DS.Motion.standard) { sortMode = mode }
                    } label: {
                        Label(mode.rawValue, systemImage: mode.icon)
                            .font(.system(size: 13, weight: sortMode == mode ? .semibold : .regular))
                            .foregroundStyle(sortMode == mode ? Color.white : Color.dccAccent)
                            .padding(.horizontal, DS.Spacing.sm)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(sortMode == mode ? Color.dccAccent : Color.dccAccent.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Performer rows — re-animate bars when sort changes
            ForEach(Array(displayed.enumerated()), id: \.element.id) { index, member in
                Button {
                    #if DEBUG
                    print("👆 [TopPerformersCard] Button action fired: \(member.memberName)")
                    #endif
                    onMemberTap(member)
                } label: {
                    PerformerBarRow(
                        member:     member,
                        rank:       index + 1,
                        maxValue:   maxValue,
                        sortMode:   sortMode,
                        barVisible: barsVisible,
                        index:      index
                    )
                }
                .buttonStyle(PerformerRowButtonStyle())
            }
        }
        .padding(DS.Spacing.md)
        .dsCard()
        .glassEffect(.regular.tint(Color.dccAccent.opacity(0.04)), in: .rect(cornerRadius: DS.Radius.md))
    }
}

private struct PerformerBarRow: View {
    let member:     MemberStats
    let rank:       Int
    let maxValue:   Double
    let sortMode:   TopPerformersCard.SortMode
    let barVisible: Bool
    let index:      Int

    // isPressed is now driven by PerformerRowButtonStyle — not needed here
    private var rankColor: Color {
        switch rank {
        case 1: return Color.rankGold
        case 2: return Color.rankSilver
        case 3: return Color.rankBronze
        default: return Color.dccAccent.opacity(0.7)
        }
    }

    private var metricValue: Double {
        switch sortMode {
        case .distance:  return member.totalKM
        case .speed:     return member.avgSpeed
        case .elevation: return member.totalElevation
        }
    }

    private var metricLabel: String {
        switch sortMode {
        case .distance:  return String(format: "%.0f km",   member.totalKM)
        case .speed:     return String(format: "%.1f km/h", member.avgSpeed)
        case .elevation: return String(format: "%.0f m",    member.totalElevation)
        }
    }

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.15))
                    .frame(width: 30, height: 30)
                Text("\(rank)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(rankColor)
            }

            // Name
            Text(member.memberName)
                .font(.dccBarLabel)
                .foregroundStyle(Color.labelPrimary)
                .lineLimit(1)
                .frame(width: 88, alignment: .leading)

            // Animated bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .fill(Color.labelTertiary.opacity(0.1))
                        .frame(height: 28)

                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .fill(
                            LinearGradient(
                                colors: [rankColor, rankColor.opacity(0.65)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: barVisible
                                ? max(28, geo.size.width * (metricValue / maxValue))
                                : 0,
                            height: 28
                        )
                        .animation(DS.Motion.stagger(index), value: barVisible)
                        .animation(DS.Motion.standard, value: sortMode)
                }
            }
            .frame(height: 28)

            // Value label
            Text(metricLabel)
                .font(.dccMetricSmall)
                .foregroundStyle(Color.labelPrimary)
                .frame(width: 52, alignment: .trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, DS.Spacing.xxs)
        .contentShape(Rectangle())
    }
}

// ButtonStyle that provides scale feedback without interfering with
// the parent ScrollView or any other gesture recognisers.
private struct PerformerRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(DS.Motion.micro, value: configuration.isPressed)
    }
}

// MARK: - Recent Activities Card

private struct RecentActivitiesCard: View {
    let activities: [ClubActivity]

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("Recent Rides")
                .font(.dccSectionTitle)
                .foregroundStyle(Color.labelPrimary)

            ForEach(activities.prefix(6)) { activity in
                CompactActivityRow(activity: activity)

                if activity.id != activities.prefix(6).last?.id {
                    Divider()
                }
            }
        }
        .padding(DS.Spacing.md)
        .dsCard()
        .glassEffect(.regular.tint(Color.dccAccent.opacity(0.04)), in: .rect(cornerRadius: DS.Radius.md))
    }
}

private struct CompactActivityRow: View {
    let activity: ClubActivity

    private var activityIcon: String {
        switch activity.type.lowercased() {
        case "ride":  return "figure.outdoor.cycle"
        case "run":   return "figure.run"
        case "walk":  return "figure.walk"
        default:      return "figure.outdoor.cycle"
        }
    }

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            // Icon chip
            Image(systemName: activityIcon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.dccAccent)
                .frame(width: 36, height: 36)
                .background(
                    Circle().fill(Color.dccAccent.opacity(0.10))
                )

            // Name + activity title
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.memberName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.labelPrimary)
                    .lineLimit(1)
                Text(activity.activityName)
                    .font(.dccCaption)
                    .foregroundStyle(Color.labelSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Distance + date
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f km", activity.distance))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.labelPrimary)
                Text(activity.formattedDate)
                    .font(.dccCaption)
                    .foregroundStyle(Color.labelTertiary)
            }
        }
    }
}

// MARK: - Member Detail Sheet

struct MemberDetailSheet: View {
    let member: MemberStats
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        #if DEBUG
        let _ = print("📋 [MemberDetailSheet] body evaluated for: \(member.memberName)")
        #endif
        return NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: DS.Spacing.xl) {

                    // ── Avatar + name header ──────────────────────────────
                    VStack(spacing: DS.Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.dccAccent, Color.dccGreenAccent],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            Text(member.initials)
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: Color.dccAccent.opacity(0.3), radius: 10, y: 4)

                        Text(member.memberName)
                            .font(.dccSectionTitle)
                            .foregroundStyle(Color.labelPrimary)

                        trendBadge
                    }
                    .padding(.top, DS.Spacing.md)

                    // ── Stats 2×2 grid ────────────────────────────────────
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: DS.Spacing.sm
                    ) {
                        StatBox(icon: "road.lanes",
                                value: String(format: "%.1f km",   member.totalKM),
                                label: "Distance")
                        StatBox(icon: "bicycle",
                                value: "\(member.totalRides)",
                                label: "Rides")
                        StatBox(icon: "speedometer",
                                value: String(format: "%.1f km/h", member.avgSpeed),
                                label: "Avg Speed")
                        StatBox(icon: "mountain.2",
                                value: String(format: "%.0f m",    member.totalElevation),
                                label: "Elevation")
                    }
                    .padding(.horizontal, DS.Spacing.md)

                    // ── Individual rides ──────────────────────────────────
                    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                        Text("This Week's Rides (\(member.rides.count))")
                            .font(.dccSectionTitle)
                            .foregroundStyle(Color.labelPrimary)
                            .padding(.horizontal, DS.Spacing.md)

                        if member.rides.isEmpty {
                            Text("No individual rides recorded.")
                                .font(.dccCaption)
                                .foregroundStyle(Color.labelSecondary)
                                .padding(.horizontal, DS.Spacing.md)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(member.rides.enumerated()), id: \.element.id) { idx, ride in
                                    RideDetailRow(activity: ride)
                                    if idx < member.rides.count - 1 {
                                        Divider()
                                            .padding(.leading, DS.Spacing.md)
                                    }
                                }
                            }
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
                            .padding(.horizontal, DS.Spacing.md)
                        }
                    }

                    Spacer().frame(height: DS.Spacing.xxl)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(member.memberName)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { 
                #if DEBUG
                print("📋 [MemberDetailSheet] ScrollView content appeared for: \(member.memberName)")
                #endif
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.dccAccent)
                }
            }
        }
    }

    @ViewBuilder
    private var trendBadge: some View {
        let (label, color): (String, Color) = {
            switch member.currentWeekTrend {
            case .up:     return ("↑ Improving",  Color.statusUp)
            case .down:   return ("↓ Declining",  Color.statusDown)
            case .stable: return ("→ Stable",     Color.statusStable)
            case .new:    return ("★ First Week",  Color.statusNew)
            }
        }()

        Text(label)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, DS.Spacing.sm)
            .padding(.vertical, DS.Spacing.xxs)
            .background(Capsule().fill(color.opacity(0.14)))
    }
}

private struct StatBox: View {
    let icon:  String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: DS.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
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

private struct RideDetailRow: View {
    let activity: ClubActivity

    private var activityIcon: String {
        switch activity.type.lowercased() {
        case "ride": return "figure.outdoor.cycle"
        case "run":  return "figure.run"
        case "walk": return "figure.walk"
        default:     return "figure.outdoor.cycle"
        }
    }

    private var formattedTime: String {
        guard activity.movingTime > 0 else { return "" }
        let h = activity.movingTime / 3600
        let m = (activity.movingTime % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            // Activity icon chip
            Image(systemName: activityIcon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.dccAccent)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color.dccAccent.opacity(0.1)))

            // Name + date
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.activityName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.labelPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(activity.formattedDate)
                        .font(.dccCaption)
                        .foregroundStyle(Color.labelSecondary)
                    if !formattedTime.isEmpty {
                        Text("·")
                            .font(.dccCaption)
                            .foregroundStyle(Color.labelTertiary)
                        Label(formattedTime, systemImage: "clock")
                            .font(.dccCaption)
                            .foregroundStyle(Color.labelSecondary)
                    }
                }
            }

            Spacer()

            // Distance + speed
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f km", activity.distance))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.labelPrimary)
                if activity.averageSpeed > 0 {
                    Text(String(format: "%.1f km/h", activity.averageSpeed))
                        .font(.dccCaption)
                        .foregroundStyle(Color.labelSecondary)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
    }
}

// MARK: - Rider Profile Sheet wrapper
// Wraps RiderProfileView in a NavigationStack so it gets a nav bar
// with a "Done" dismiss button when presented as a modal sheet.

private struct RiderProfileSheet: View {
    let member:   MemberStats
    let allStats: [MemberStats]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            RiderProfileView(member: member, allStats: allStats)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                            .fontWeight(.semibold)
                    }
                }
        }
    }
}


#endif // !os(tvOS)


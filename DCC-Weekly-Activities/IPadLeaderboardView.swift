//
//  IPadLeaderboardView.swift
//  DCC-Weekly-Activities
//
//  iPad "Leaderboard" tab — NavigationSplitView with an animated podium header,
//  ranked rider sidebar, and full rider analysis in the detail pane.
//

import SwiftUI

struct IPadLeaderboardView: View {
    let stats: [MemberStats]
    let activities: [Activity]
    let dateRange: DateInterval?
    /// User initial + actions for the profile menu button in the toolbar
    let userInitial: String
    let onCopyToken: () -> Void
    let onLogOut: () -> Void

    @State private var selectedRider: MemberStats?
    @State private var podiumAppeared = false

    private var sortedStats: [MemberStats] {
        stats.sorted { $0.totalKM > $1.totalKM }
    }

    private var podium: [MemberStats] {
        Array(sortedStats.prefix(3))
    }

    private var restOfRiders: [(Int, MemberStats)] {
        Array(sortedStats.enumerated().filter { $0.offset >= 3 }.map { ($0.offset + 1, $0.element) })
    }

    var body: some View {
        NavigationSplitView {
            sidebarContent
                .navigationTitle("Leaderboard")
                .toolbar { profileMenuToolbarItem }
        } detail: {
            detailContent
        }
        .containerBackground(Color.appBackground, for: .navigationSplitView)
        .onAppear {
            if selectedRider == nil {
                selectedRider = sortedStats.first
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1)) {
                podiumAppeared = true
            }
        }
    }

    @ToolbarContentBuilder
    private var profileMenuToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button { onCopyToken() } label: {
                    Label("Copy Token for Apple TV", systemImage: "appletv")
                }
                Divider()
                Button(role: .destructive) { onLogOut() } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.dccSaffron.opacity(0.18))
                        .frame(width: 34, height: 34)
                    Text(userInitial)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.dccSaffron)
                }
            }
        }
    }

    // MARK: - Sidebar

    private var sidebarContent: some View {
        List(selection: $selectedRider) {

            // Podium section header with 3-card display
            if podium.count >= 3 {
                Section {
                    podiumHeader
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }
            }

            // Club summary
            if !stats.isEmpty {
                Section {
                    clubSummaryRow
                        .listRowBackground(Color.surface.opacity(0.6))
                }
            }

            // Top 3 as selectable rows
            if podium.count >= 1 {
                Section("Top Riders") {
                    ForEach(Array(podium.enumerated()), id: \.element.id) { index, rider in
                        IPadRiderRow(rank: index + 1, rider: rider)
                            .tag(rider)
                            .listRowBackground(Color.surface.opacity(0.5))
                    }
                }
            }

            // All other riders
            if !restOfRiders.isEmpty {
                Section("All Riders") {
                    ForEach(restOfRiders, id: \.1.id) { rank, rider in
                        IPadRiderRow(rank: rank, rider: rider)
                            .tag(rider)
                            .listRowBackground(Color.surface.opacity(0.5))
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .containerBackground(Color.appBackground, for: .navigation)
    }

    // MARK: - Podium header (top 3 cards stacked horizontally)

    private var podiumHeader: some View {
        HStack(spacing: 8) {
            // 2nd place
            if podium.count >= 2 {
                compactPodiumBadge(rank: 2, rider: podium[1])
            }
            // 1st place (taller)
            if podium.count >= 1 {
                compactPodiumBadge(rank: 1, rider: podium[0])
            }
            // 3rd place
            if podium.count >= 3 {
                compactPodiumBadge(rank: 3, rider: podium[2])
            }
        }
        .opacity(podiumAppeared ? 1 : 0)
        .scaleEffect(podiumAppeared ? 1 : 0.92)
    }

    private func compactPodiumBadge(rank: Int, rider: MemberStats) -> some View {
        let rankColor: Color = {
            switch rank {
            case 1: return Color(hex: "#FFD700")
            case 2: return Color(hex: "#C0C0C0")
            default: return Color(hex: "#CD7F32")
            }
        }()

        return VStack(spacing: 5) {
            Text(rank == 1 ? "👑" : rank == 2 ? "🥈" : "🥉")
                .font(.system(size: rank == 1 ? 22 : 18))
            Text(rider.memberName.components(separatedBy: " ").first ?? rider.memberName)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
            Text(String(format: "%.0f km", rider.totalKM))
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(rankColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, rank == 1 ? 14 : 10)
        .glassEffect(
            .regular.tint(rankColor.opacity(0.12)),
            in: .rect(cornerRadius: 12)
        )
    }

    // MARK: - Club summary row

    private var clubSummaryRow: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "person.3.fill")
                .font(.subheadline)
                .foregroundStyle(Color.dccSaffron)
                .frame(width: 30, height: 30)
                .background(Color.dccSaffron.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(stats.count) active riders")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                Text(String(format: "%.1f km club total", stats.reduce(0) { $0 + $1.totalKM }))
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Detail pane

    @ViewBuilder
    private var detailContent: some View {
        if let rider = selectedRider {
            ScrollView {
                VStack(spacing: IPadLayout.sectionGap) {
                    // Rider rank banner at top of detail
                    riderDetailBanner(rider)
                    RiderAnalysisView(
                        rider: rider,
                        allStats: stats,
                        activities: activities
                    )
                }
                .padding(.horizontal, IPadLayout.screenMargin)
                .padding(.vertical, IPadLayout.sectionGap)
            }
            .scrollContentBackground(.hidden)
            .containerBackground(Color.appBackground, for: .navigation)
            .background(Color.appBackground.ignoresSafeArea())
        } else {
            ContentUnavailableView(
                "Select a Rider",
                systemImage: "person.fill.questionmark",
                description: Text("Choose a rider from the leaderboard to view their full analysis")
            )
            .containerBackground(Color.appBackground, for: .navigation)
            .background(Color.appBackground.ignoresSafeArea())
        }
    }

    private func riderDetailBanner(_ rider: MemberStats) -> some View {
        let rank = (sortedStats.firstIndex(where: { $0.id == rider.id }) ?? 0) + 1
        let rankColor: Color = rank == 1 ? Color(hex: "#FFD700") : rank == 2 ? Color(hex: "#C0C0C0") : rank == 3 ? Color(hex: "#CD7F32") : Color.textSecondary

        return HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.18))
                    .frame(width: 52, height: 52)
                Text(rank <= 3 ? (rank == 1 ? "👑" : rank == 2 ? "🥈" : "🥉") : "\(rank)")
                    .font(.system(size: rank <= 3 ? 26 : 20, weight: .bold, design: .rounded))
                    .foregroundStyle(rank > 3 ? rankColor : Color.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(rider.memberName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text("Rank #\(rank) of \(stats.count) riders")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            HStack(spacing: Spacing.xl) {
                bannerStat(value: String(format: "%.1f", rider.totalKM), unit: "km", color: .dccSaffron)
                bannerStat(value: "\(rider.totalRides)", unit: "rides", color: .dccGreen)
                if rider.avgSpeed > 0 {
                    bannerStat(value: String(format: "%.1f", rider.avgSpeed), unit: "avg km/h", color: .accent)
                }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(
            .regular.tint(rankColor.opacity(0.08)),
            in: .rect(cornerRadius: IPadLayout.panelCornerRadius)
        )
    }

    private func bannerStat(value: String, unit: String, color: Color) -> some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(unit)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
    }
}

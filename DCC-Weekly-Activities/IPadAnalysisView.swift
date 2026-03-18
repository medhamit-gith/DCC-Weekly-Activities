//
//  IPadAnalysisView.swift
//  DCC-Weekly-Activities
//
//  iPad "Analysis" tab — NavigationSplitView with a polished rider selector
//  sidebar and an animated 2-column chart grid in the detail pane.
//

import SwiftUI

struct IPadAnalysisView: View {
    let stats: [MemberStats]
    let activities: [Activity]
    let userInitial: String
    let onCopyToken: () -> Void
    let onLogOut: () -> Void

    @State private var viewModel = InsightsViewModel()
    @State private var detailAppeared = false

    var body: some View {
        NavigationSplitView {
            sidebarContent
                .navigationTitle("Analysis")
                .toolbar { profileMenuToolbarItem }
        } detail: {
            detailContent
        }
        .containerBackground(Color.appBackground, for: .navigationSplitView)
        .onAppear {
            viewModel.stats = stats
            if viewModel.selectedRiderName == nil {
                viewModel.selectedRiderName = stats.sorted { $0.totalKM > $1.totalKM }.first?.memberName
            }
        }
        .onChange(of: stats) { _, newStats in
            viewModel.stats = newStats
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
        List(selection: Binding(
            get: { viewModel.selectedRider },
            set: { viewModel.selectedRiderName = $0?.memberName }
        )) {
            // Summary header
            Section {
                analysisSummaryRow
                    .listRowBackground(Color.surface.opacity(0.6))
            }

            // Riders
            Section("Riders") {
                ForEach(viewModel.sortedStats) { rider in
                    analysisRiderRow(rider)
                        .tag(rider as MemberStats?)
                        .listRowBackground(Color.surface.opacity(0.5))
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .containerBackground(Color.appBackground, for: .navigation)
    }

    private var analysisSummaryRow: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "chart.xyaxis.line")
                .font(.subheadline)
                .foregroundStyle(Color.accent)
                .frame(width: 30, height: 30)
                .background(Color.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 7))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(stats.count) riders analysed")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                Text("Tap a rider to explore their data")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func analysisRiderRow(_ rider: MemberStats) -> some View {
        let rank = (viewModel.sortedStats.firstIndex(where: { $0.id == rider.id }) ?? 0) + 1
        let isSelected = viewModel.selectedRider?.id == rider.id

        return HStack(spacing: Spacing.sm) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(Color.rankColor(for: rank).opacity(0.18))
                    .frame(width: 30, height: 30)
                Text("\(rank)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.rankColor(for: rank))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(rider.memberName)
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text("\(rider.totalRides) ride\(rider.totalRides == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    if rider.currentWeekTrend == .up {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.dccGreen)
                    } else if rider.currentWeekTrend == .down {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.error)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f", rider.totalKM))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dccSaffron)
                Text("km")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(.vertical, IPadLayout.sidebarItemPadding)
        .contentShape(Rectangle())
    }

    // MARK: - Detail pane

    @ViewBuilder
    private var detailContent: some View {
        if let selectedRider = viewModel.selectedRider {
            ScrollView {
                VStack(spacing: IPadLayout.sectionGap) {
                    // Rider header
                    riderAnalysisHeader(selectedRider)
                        .opacity(detailAppeared ? 1 : 0)
                        .offset(y: detailAppeared ? 0 : 16)

                    // 2-column chart grid
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: IPadLayout.cardGap),
                            GridItem(.flexible(), spacing: IPadLayout.cardGap)
                        ],
                        spacing: IPadLayout.cardGap
                    ) {
                        chartCard(
                            tint: Color.dccSaffron,
                            delay: 0.1
                        ) {
                            DistanceBarChart(
                                stats: stats,
                                selectedRider: selectedRider,
                                viewModel: viewModel
                            )
                        }

                        chartCard(
                            tint: Color.dccGreen,
                            delay: 0.18
                        ) {
                            SpeedElevationScatter(
                                stats: stats,
                                selectedRider: selectedRider
                            )
                        }

                        chartCard(
                            tint: Color.dccBlue,
                            delay: 0.26
                        ) {
                            RadarChartView(
                                rider: selectedRider,
                                viewModel: viewModel
                            )
                        }

                        coachingTipsPanel(for: selectedRider)
                            .opacity(detailAppeared ? 1 : 0)
                            .scaleEffect(detailAppeared ? 1 : 0.95)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.32), value: detailAppeared)
                    }
                    .opacity(detailAppeared ? 1 : 0)
                    .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.08), value: detailAppeared)
                }
                .frame(maxWidth: IPadLayout.maxContentWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, IPadLayout.screenMargin)
                .padding(.vertical, IPadLayout.sectionGap)
            }
            .scrollContentBackground(.hidden)
            .containerBackground(Color.appBackground, for: .navigation)
            .background(Color.appBackground.ignoresSafeArea())
            .onChange(of: selectedRider) { _, _ in
                // Re-trigger animation when rider changes
                detailAppeared = false
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05)) {
                    detailAppeared = true
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                    detailAppeared = true
                }
            }
        } else {
            ContentUnavailableView(
                "Select a Rider",
                systemImage: "chart.xyaxis.line",
                description: Text("Choose a rider from the sidebar to view their performance charts")
            )
            .containerBackground(Color.appBackground, for: .navigation)
            .background(Color.appBackground.ignoresSafeArea())
        }
    }

    // MARK: - Rider analysis header

    private func riderAnalysisHeader(_ rider: MemberStats) -> some View {
        let rank = viewModel.rank(for: rider)
        let rankColor: Color = rank == 1 ? Color(hex: "#FFD700") : rank == 2 ? Color(hex: "#C0C0C0") : rank == 3 ? Color(hex: "#CD7F32") : Color.accent

        return HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.18))
                    .frame(width: 48, height: 48)
                Image(systemName: "person.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(rankColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(rider.memberName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                HStack(spacing: Spacing.xs) {
                    Text("Rank #\(rank) of \(stats.count)")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                    if rider.currentWeekTrend == .up {
                        Label("Improving", systemImage: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(Color.dccGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .glassEffect(.regular.tint(Color.dccGreen.opacity(0.12)), in: .capsule)
                    } else if rider.currentWeekTrend == .down {
                        Label("Declining", systemImage: "arrow.down.right")
                            .font(.caption)
                            .foregroundStyle(Color.error)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .glassEffect(.regular.tint(Color.error.opacity(0.12)), in: .capsule)
                    }
                }
            }

            Spacer()

            // Key stats inline
            HStack(spacing: Spacing.xl) {
                analysisHeaderStat(value: String(format: "%.1f", rider.totalKM), unit: "km", color: .dccSaffron)
                analysisHeaderStat(value: "\(rider.totalRides)", unit: "rides", color: .dccGreen)
                if rider.avgSpeed > 0 {
                    analysisHeaderStat(value: String(format: "%.1f", rider.avgSpeed), unit: "km/h avg", color: .accent)
                }
                if rider.totalElevation > 0 {
                    analysisHeaderStat(value: String(format: "%.0f", rider.totalElevation), unit: "m elev", color: .dccBlue)
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

    private func analysisHeaderStat(value: String, unit: String, color: Color) -> some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(unit)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - Chart card wrapper with glass + entrance animation

    private func chartCard<Content: View>(
        tint: Color,
        delay: Double,
        @ViewBuilder content: () -> Content
    ) -> some View {
        AnimatedChartCard(tint: tint, delay: delay, appeared: detailAppeared, content: content)
    }

    // MARK: - Coaching tips panel

    private func coachingTipsPanel(for rider: MemberStats) -> some View {
        let tips = viewModel.generateCoachingTips(for: rider)
        return VStack(alignment: .leading, spacing: Spacing.md) {
            IPadSectionHeader(
                title: "Coaching Tips",
                icon: "lightbulb.fill",
                color: .dccSaffron
            )
            if tips.isEmpty {
                Text("Keep it up — no coaching tips needed!")
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.vertical, Spacing.sm)
            } else {
                ForEach(Array(tips.enumerated()), id: \.element.id) { index, tip in
                    CoachingTipCard(tip: tip, index: index)
                }
            }
        }
        .padding(Spacing.lg)
        .glassEffect(
            .regular.tint(Color.dccSaffron.opacity(0.05)),
            in: .rect(cornerRadius: IPadLayout.cardCornerRadius)
        )
    }
}

// MARK: - Animated chart card wrapper

private struct AnimatedChartCard: View {
    let tint: Color
    let delay: Double
    let appeared: Bool
    let content: AnyView

    init<Content: View>(tint: Color, delay: Double, appeared: Bool, @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.delay = delay
        self.appeared = appeared
        self.content = AnyView(content())
    }

    @State private var localAppeared = false

    var body: some View {
        content
            .glassEffect(
                .regular.tint(tint.opacity(0.05)),
                in: .rect(cornerRadius: IPadLayout.cardCornerRadius)
            )
            .opacity(localAppeared ? 1 : 0)
            .scaleEffect(localAppeared ? 1 : 0.95)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                    localAppeared = true
                }
            }
            .onChange(of: appeared) { _, newValue in
                if newValue {
                    localAppeared = false
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                        localAppeared = true
                    }
                }
            }
    }
}


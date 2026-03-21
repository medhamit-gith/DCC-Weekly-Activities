//
//  WorkerKVDashboardView.swift
//  DCC-Weekly-Activities
//
//  Live dashboard showing the state of the Cloudflare Worker KV cache.
//  Fetches /club-data for the current week and last week from the worker,
//  and displays a clean summary of what is stored.
//
//  Presented as a sheet from the Performance / profile menu on both
//  iPhone (ProfessionalDashboardView) and iPad (IPadDashboardView).
//
//  iOS ONLY — do not add to tvOS target.
//

import SwiftUI

// MARK: - ViewModel

@MainActor
@Observable
final class WorkerKVDashboardViewModel {

    // MARK: Per-week snapshot

    struct WeekSnapshot: Identifiable {
        let id: String          // weekStart ISO date e.g. "2026-03-16"
        let label: String       // e.g. "w/c 16 Mar"
        let weekStart: String
        let weekEnd: String
        let memberCount: Int
        let totalActivities: Int
        let totalDistanceKm: Double
        let topRider: String?
        let topRiderKm: Double
        let lastFetchedAt: Date?
        let noDataAvailable: Bool
        let members: [SnapshotMember]
    }

    struct SnapshotMember: Identifiable {
        let id: String          // name
        let name: String
        let totalDistanceKm: Double
        let rideCount: Int
        let avgSpeed: Double
        let totalElevation: Int
        let movingTimeFormatted: String
    }

    // MARK: State

    var weeks: [WeekSnapshot] = []
    var isLoading = false
    var errorMessage: String?
    var lastRefreshedAt: Date?

    private let workerBase = StravaConfig.workerURL + "/club-data"
    private let isoFormatter = ISO8601DateFormatter()

    // MARK: Fetch

    func refresh() async {
        isLoading = true
        errorMessage = nil
        weeks = []

        // Fetch current week (offset=0) and last week (offset=-1) in parallel
        async let this = fetchWeek(offset: 0)
        async let last = fetchWeek(offset: -1)

        let results = await [this, last].compactMap { $0 }
        weeks = results
        lastRefreshedAt = Date()
        isLoading = false
    }

    private func fetchWeek(offset: Int) async -> WeekSnapshot? {
        var urlStr = workerBase
        if offset != 0 { urlStr += "?weekOffset=\(offset)" }
        guard let url = URL(string: urlStr) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return nil
            }
            let decoded = try JSONDecoder().decode(CloudDataResponse.self, from: data)
            return snapshot(from: decoded)
        } catch {
            return nil
        }
    }

    private func snapshot(from r: CloudDataResponse) -> WeekSnapshot {
        let fetchedAt: Date? = r.lastFetchedAt.flatMap { isoFormatter.date(from: $0) }
        let totalKm = r.members.reduce(0.0) { $0 + $1.totalDistance }
        let top = r.members.max(by: { $0.totalDistance < $1.totalDistance })

        let members: [SnapshotMember] = r.members.map { m in
            SnapshotMember(
                id: m.name,
                name: m.name,
                totalDistanceKm: m.totalDistance,
                rideCount: m.rideCount,
                avgSpeed: m.avgSpeed,
                totalElevation: m.totalElevation,
                movingTimeFormatted: m.movingTimeFormatted ?? ""
            )
        }

        // Derive weekStart / weekEnd from the response or fall back to empty strings
        let weekStart = r.weekStart ?? ""
        let weekEnd   = weekEndFromStart(weekStart)
        let label     = r.members.isEmpty ? labelFromWeekStart(weekStart) : labelFromWeekStart(weekStart)

        return WeekSnapshot(
            id:               weekStart,
            label:            label,
            weekStart:        weekStart,
            weekEnd:          weekEnd,
            memberCount:      r.memberCount ?? r.members.count,
            totalActivities:  r.totalActivities ?? 0,
            totalDistanceKm:  totalKm,
            topRider:         top?.name,
            topRiderKm:       top?.totalDistance ?? 0,
            lastFetchedAt:    fetchedAt,
            noDataAvailable:  r.noDataAvailable ?? false,
            members:          members
        )
    }

    // Derive a human label like "w/c 16 Mar" from "2026-03-16"
    private func labelFromWeekStart(_ iso: String) -> String {
        guard iso.count >= 10 else { return "Unknown week" }
        let parts = iso.prefix(10).split(separator: "-")
        guard parts.count == 3,
              let month = Int(parts[1]),
              let day   = Int(parts[2]) else { return iso }
        let months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        let name = month >= 1 && month <= 12 ? months[month - 1] : "?"
        return "w/c \(day) \(name)"
    }

    private func weekEndFromStart(_ start: String) -> String {
        guard start.count >= 10,
              let date = isoFormatter.date(from: start + "T00:00:00Z") else { return "" }
        let end = date.addingTimeInterval(6 * 86400)
        return ISO8601DateFormatter().string(from: end).prefix(10).description
    }
}

// MARK: - Main View

struct WorkerKVDashboardView: View {

    @Binding var isPresented: Bool

    @State private var vm = WorkerKVDashboardViewModel()
    @State private var expandedWeek: String? = nil     // id of expanded week card
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.appBackground.ignoresSafeArea()

                if vm.isLoading {
                    loadingView
                } else if let err = vm.errorMessage {
                    errorView(err)
                } else {
                    content
                }
            }
            .navigationTitle("Worker KV Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await vm.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(vm.isLoading)
                }
            }
        }
        .task {
            await vm.refresh()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                appeared = true
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .tint(Color.accent)
                .scaleEffect(1.4)
            Text("Fetching worker data…")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - Error

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.dccSaffron)
            Text("Could not reach worker")
                .font(.title3).bold()
            Text(msg)
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
            Button("Retry") { Task { await vm.refresh() } }
                .buttonStyle(.dccGlass(tintColor: Color.accent, isProminent: true))
        }
        .padding(Spacing.xl)
    }

    // MARK: - Main Content

    private var content: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // ── Top status bar ────────────────────────────────────────
                workerStatusCard
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(.spring(response: 0.5, dampingFraction: 0.78).delay(0.05), value: appeared)

                // ── Week cards ────────────────────────────────────────────
                ForEach(Array(vm.weeks.enumerated()), id: \.element.id) { idx, week in
                    weekCard(week, delay: Double(idx) * 0.08 + 0.10)
                }

                if vm.weeks.isEmpty && !vm.isLoading {
                    emptyStateCard
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
                }

                // ── Footer ────────────────────────────────────────────────
                if let at = vm.lastRefreshedAt {
                    Text("Last refreshed \(at, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .padding(.bottom, Spacing.md)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.35), value: appeared)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xxl)
        }
    }

    // MARK: - Worker Status Card

    private var workerStatusCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.sm) {
                // Status dot
                Circle()
                    .fill(vm.weeks.isEmpty ? Color.dccSaffron : Color.dccGreen)
                    .frame(width: 10, height: 10)
                    .shadow(color: (vm.weeks.isEmpty ? Color.dccSaffron : Color.dccGreen).opacity(0.6), radius: 4)

                Text("Worker Online")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                // Weeks cached count
                Label("\(vm.weeks.filter { !$0.noDataAvailable }.count) week\(vm.weeks.filter { !$0.noDataAvailable }.count == 1 ? "" : "s") cached",
                      systemImage: "internaldrive.fill")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)

            Divider().opacity(0.2)

            // Stats row
            HStack(spacing: 0) {
                kvStatCell(
                    icon: "figure.outdoor.cycle",
                    value: "\(vm.weeks.reduce(0) { $0 + $1.totalActivities })",
                    label: "Total Activities"
                )
                kvDivider
                kvStatCell(
                    icon: "person.2.fill",
                    value: "\(vm.weeks.reduce(0) { $0 + $1.memberCount })",
                    label: "Member Records"
                )
                kvDivider
                kvStatCell(
                    icon: "road.lanes",
                    value: "\(Int(vm.weeks.reduce(0.0) { $0 + $1.totalDistanceKm })) km",
                    label: "Total Distance"
                )
            }
            .padding(.vertical, Spacing.sm)
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.dccGreen.opacity(0.25), lineWidth: 1)
                )
        )
    }

    private func kvStatCell(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.accent)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var kvDivider: some View {
        Divider()
            .frame(height: 36)
            .opacity(0.25)
    }

    // MARK: - Week Card

    @ViewBuilder
    private func weekCard(_ week: WorkerKVDashboardViewModel.WeekSnapshot, delay: Double) -> some View {
        let isExpanded = expandedWeek == week.id
        let isCurrentWeek = week.id == vm.weeks.first?.id

        VStack(spacing: 0) {

            // ── Header row ────────────────────────────────────────────────
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                    expandedWeek = isExpanded ? nil : week.id
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    // Week badge
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            if isCurrentWeek {
                                Text("LIVE")
                                    .font(.system(size: 9, weight: .heavy))
                                    .foregroundStyle(Color.dccGreen)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.dccGreen.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                            Text(week.label)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.textPrimary)
                        }
                        Text("\(week.weekStart) → \(week.weekEnd)")
                            .font(.caption2)
                            .foregroundStyle(Color.textSecondary)
                            .monospacedDigit()
                    }

                    Spacer()

                    if week.noDataAvailable {
                        // No data badge
                        Text("No Data")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.dccSaffron)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.dccSaffron.opacity(0.12))
                            .clipShape(Capsule())
                    } else {
                        // Summary chips
                        HStack(spacing: 6) {
                            kvChip(icon: "figure.outdoor.cycle",
                                   value: "\(week.totalActivities)",
                                   color: Color.accent)
                            kvChip(icon: "road.lanes",
                                   value: "\(Int(week.totalDistanceKm))km",
                                   color: Color.dccGreen)
                        }
                    }

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isExpanded)
                }
                .padding(Spacing.md)
            }
            .buttonStyle(.plain)

            // ── Expanded detail ───────────────────────────────────────────
            if isExpanded {
                Divider().opacity(0.2).padding(.horizontal, Spacing.md)

                if week.noDataAvailable {
                    noDataExpandedView
                } else {
                    weekDetailView(week)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(
                            isCurrentWeek
                                ? Color.dccGreen.opacity(0.30)
                                : Color.white.opacity(0.08),
                            lineWidth: 1
                        )
                )
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.78).delay(delay), value: appeared)
    }

    private func kvChip(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(value)
                .font(.caption2)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .foregroundStyle(color)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - No Data Expanded

    private var noDataExpandedView: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "xmark.icloud")
                .font(.title3)
                .foregroundStyle(Color.dccSaffron.opacity(0.7))
            Text("No KV data stored for this week yet.\nThe Monday cron will bootstrap it automatically.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
    }

    // MARK: - Week Detail (member table)

    private func weekDetailView(_ week: WorkerKVDashboardViewModel.WeekSnapshot) -> some View {
        VStack(spacing: 0) {
            // Summary row
            HStack(spacing: 0) {
                weekSummaryCell(icon: "person.2.fill",
                                value: "\(week.memberCount)",
                                label: "Members")
                Divider().frame(height: 30).opacity(0.2)
                weekSummaryCell(icon: "figure.outdoor.cycle",
                                value: "\(week.totalActivities)",
                                label: "Activities")
                Divider().frame(height: 30).opacity(0.2)
                weekSummaryCell(icon: "road.lanes",
                                value: "\(Int(week.totalDistanceKm)) km",
                                label: "Distance")
                if let at = week.lastFetchedAt {
                    Divider().frame(height: 30).opacity(0.2)
                    weekSummaryCell(icon: "clock",
                                    value: at.formatted(.relative(presentation: .named)),
                                    label: "Cached")
                }
            }
            .padding(.vertical, Spacing.sm)

            // Member rows
            if !week.members.isEmpty {
                Divider().opacity(0.15).padding(.horizontal, Spacing.md)

                VStack(spacing: 0) {
                    ForEach(Array(week.members.sorted(by: { $0.totalDistanceKm > $1.totalDistanceKm }).enumerated()),
                            id: \.element.id) { idx, member in
                        memberRow(member, rank: idx + 1, isLast: idx == week.members.count - 1)
                    }
                }
                .padding(.bottom, Spacing.sm)
            }
        }
    }

    private func weekSummaryCell(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(Color.accent.opacity(0.8))
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private func memberRow(
        _ member: WorkerKVDashboardViewModel.SnapshotMember,
        rank: Int,
        isLast: Bool
    ) -> some View {
        HStack(spacing: Spacing.sm) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor(rank).opacity(0.15))
                    .frame(width: 28, height: 28)
                Text(rank <= 3 ? ["1","2","3"][rank-1] : "\(rank)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(rankColor(rank))
            }

            // Name
            Text(member.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)

            Spacer()

            // Stats
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text("\(member.totalDistanceKm, specifier: "%.1f") km")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                    Text("·")
                        .foregroundStyle(Color.textSecondary)
                    Text("\(member.rideCount) ride\(member.rideCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.dccSaffron.opacity(0.8))
                    Text("\(member.avgSpeed, specifier: "%.1f") km/h")
                        .font(.caption2)
                        .foregroundStyle(Color.textSecondary)
                    Text("·")
                        .foregroundStyle(Color.textSecondary.opacity(0.5))
                    Text("\(member.movingTimeFormatted)")
                        .font(.caption2)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            rank % 2 == 0
                ? Color.white.opacity(0.025)
                : Color.clear
        )
        if !isLast {
            Divider()
                .opacity(0.08)
                .padding(.horizontal, Spacing.md)
        }
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color.dccSaffron
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return Color.textSecondary
        }
    }

    // MARK: - Empty State

    private var emptyStateCard: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 44))
                .foregroundStyle(Color.dccSaffron.opacity(0.7))
            Text("No KV data available")
                .font(.title3).bold()
                .foregroundStyle(Color.textPrimary)
            Text("The worker has no cached data yet.\nTrigger a fetch or wait for the next cron run.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xxl)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Spacing / CornerRadius guard
// These constants are already defined in the app's DesignSystem.
// The extension below is a compile-time safety net only — it adds nothing
// if the value is already declared in DesignSystem.swift.

private extension Spacing {
    static var xxl: CGFloat { 32 }
}

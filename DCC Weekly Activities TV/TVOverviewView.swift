//
//  TVOverviewView.swift
//  DCC Weekly Activities TV
//
//  "This Week / Club Overview" tab — rebuilt to UX spec:
//  — Left column: 4 club-total stat cards + active rider chips
//  — Right column: rider breakdown with mini progress bars
//  — Premium dark aesthetic: Strava orange accent, SF Pro typography
//  — Focus: tvFocusCard modifier (glow + scale per spec)
//  — All stat values animate in on appear (count-up)
//
//  Depends on TVDesignSystem.swift.
//  Uses TVMemberStats from TVRootView.swift.
//

import SwiftUI

// MARK: - Root view

struct TVOverviewView: View {

    let memberStats: [TVMemberStats]

    // Derived club totals
    private var totalKM: Double        { memberStats.reduce(0) { $0 + $1.totalKM } }
    private var totalRides: Int        { memberStats.reduce(0) { $0 + $1.totalRides } }
    private var totalElevation: Double { memberStats.reduce(0) { $0 + $1.totalElevation } }
    private var avgSpeed: Double {
        guard !memberStats.isEmpty else { return 0 }
        let valid = memberStats.filter { $0.avgSpeed > 0 }
        guard !valid.isEmpty else { return 0 }
        return valid.reduce(0) { $0 + $1.avgSpeed } / Double(valid.count)
    }
    private var sorted: [TVMemberStats] {
        memberStats.sorted { $0.totalKM > $1.totalKM }
    }

    @State private var animateStats = false

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {

                // ── LEFT COLUMN (42%) ─────────────────────────────────────
                VStack(alignment: .leading, spacing: 28) {

                    TVSectionLabel(eyebrow: "THIS WEEK", title: "Club Overview")
                        .padding(.top, 28)

                    // 2×2 stat cards
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: TVLayout.cardGap),
                            GridItem(.flexible(), spacing: TVLayout.cardGap)
                        ],
                        spacing: TVLayout.cardGap
                    ) {
                        OverviewStatCard(
                            value: totalKM,
                            format: "%.0f",
                            unit: "km",
                            label: "Total Distance",
                            icon: "road.lanes",
                            color: .tvAccent,
                            animate: animateStats
                        )
                        OverviewStatCard(
                            value: Double(totalRides),
                            format: "%.0f",
                            unit: "",
                            label: "Total Rides",
                            icon: "figure.outdoor.cycle",
                            color: .tvSaffron,
                            animate: animateStats
                        )
                        OverviewStatCard(
                            value: totalElevation,
                            format: "%.0f",
                            unit: "m",
                            label: "Total Elevation",
                            icon: "mountain.2.fill",
                            color: .tvBlue,
                            animate: animateStats
                        )
                        OverviewStatCard(
                            value: avgSpeed,
                            format: "%.1f",
                            unit: "km/h",
                            label: "Club Avg Speed",
                            icon: "speedometer",
                            color: .tvGreen,
                            animate: animateStats
                        )
                    }

                    // Active riders bar
                    if !sorted.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("ACTIVE RIDERS")
                                    .font(TVFont.caption())
                                    .tracking(2)
                                    .foregroundStyle(Color.tvTextTertiary)
                                Spacer()
                                Text("\(sorted.count)")
                                    .font(TVFont.dataLabel())
                                    .foregroundStyle(Color.tvAccent)
                            }

                            // Rider initials chips
                            let columns = [GridItem(.adaptive(minimum: 56), spacing: 10)]
                            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                                ForEach(Array(sorted.enumerated()), id: \.element.id) { idx, rider in
                                    RiderInitialChip(rider: rider, rank: idx + 1)
                                }
                            }
                        }
                        .padding(TVLayout.cardPadding)
                        .background(
                            RoundedRectangle(cornerRadius: TVLayout.cardCornerRadius)
                                .fill(Color.tvCard)
                                .overlay(
                                    RoundedRectangle(cornerRadius: TVLayout.cardCornerRadius)
                                        .strokeBorder(Color.tvDivider, lineWidth: 1)
                                )
                        )
                    }

                    Spacer()
                }
                .padding(.leading, TVLayout.screenMargin)
                .padding(.trailing, TVLayout.cardGap)
                .frame(width: geo.size.width * 0.42)

                // Vertical divider
                Rectangle()
                    .fill(Color.tvDivider)
                    .frame(width: 1)

                // ── RIGHT COLUMN (58%) ────────────────────────────────────
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    HStack {
                        TVSectionLabel(eyebrow: "RANKED BY DISTANCE", title: "Rider Breakdown")
                        Spacer()
                    }
                    .padding(.top, 28)
                    .padding(.bottom, 20)

                    // Rider list
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(Array(sorted.enumerated()), id: \.element.id) { index, rider in
                                OverviewRiderRow(
                                    rider: rider,
                                    rank: index + 1,
                                    maxKM: sorted.first?.totalKM ?? 1
                                )
                            }
                        }
                        .padding(.trailing, TVLayout.screenMargin)
                        .padding(.bottom, TVLayout.sectionGap)
                    }
                }
                .padding(.leading, TVLayout.cardGap)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    animateStats = true
                }
            }
        }
    }
}

// MARK: - Overview stat card

private struct OverviewStatCard: View {
    let value: Double
    let format: String
    let unit: String
    let label: String
    let icon: String
    let color: Color
    let animate: Bool

    @FocusState private var isFocused: Bool
    @State private var displayed: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(color)
                Spacer()
                Text(label.uppercased())
                    .font(TVFont.caption())
                    .tracking(1.5)
                    .foregroundStyle(Color.tvTextTertiary)
            }

            HStack(alignment: .lastTextBaseline, spacing: 5) {
                Text(String(format: format, displayed))
                    .font(TVFont.statValue())
                    .foregroundStyle(Color.tvTextPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                if !unit.isEmpty {
                    Text(unit)
                        .font(TVFont.caption())
                        .foregroundStyle(Color.tvTextSecondary)
                }
            }
        }
        .padding(TVLayout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tvFocusCard(isFocused: isFocused, baseColor: .tvCard, accentColor: color)
        .focusable()
        .focused($isFocused)
        .onChange(of: animate) { _, newValue in
            if newValue {
                withAnimation(.easeOut(duration: 0.8)) { displayed = value }
            } else {
                displayed = 0
            }
        }
        .onChange(of: value) { _, newVal in
            displayed = 0
            withAnimation(.easeOut(duration: 0.6)) { displayed = newVal }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(String(format: format, value)) \(unit)")
    }
}

// MARK: - Rider initial chip

private struct RiderInitialChip: View {
    let rider: TVMemberStats
    let rank: Int

    private var initials: String {
        let parts = rider.memberName.split(separator: " ")
        let first = parts.first.map { String($0.prefix(1)) } ?? "?"
        let last  = parts.dropFirst().first.map { String($0.prefix(1)) } ?? ""
        return (first + last).uppercased()
    }

    private var chipColor: Color {
        switch rank {
        case 1: return .tvGold
        case 2: return .tvSilver
        case 3: return .tvBronze
        default: return .tvTextSecondary
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(chipColor.opacity(0.15))
                .frame(width: 52, height: 52)
            Circle()
                .strokeBorder(chipColor.opacity(rank <= 3 ? 0.5 : 0.2), lineWidth: 1.5)
                .frame(width: 52, height: 52)
            Text(initials)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(chipColor)
        }
        .accessibilityLabel("\(rider.memberName), rank \(rank)")
    }
}

// MARK: - Rider breakdown row

private struct OverviewRiderRow: View {
    let rider: TVMemberStats
    let rank: Int
    let maxKM: Double

    @FocusState private var isFocused: Bool
    @State private var barWidth: CGFloat = 0

    private var barFill: Double {
        guard maxKM > 0 else { return 0 }
        return min(rider.totalKM / maxKM, 1.0)
    }

    private var initials: String {
        let parts = rider.memberName.split(separator: " ")
        let first = parts.first.map { String($0.prefix(1)) } ?? "?"
        let last  = parts.dropFirst().first.map { String($0.prefix(1)) } ?? ""
        return (first + last).uppercased()
    }

    private var rankColor: Color { tvRankColor(rank) }

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(rankColor.opacity(isFocused ? 0.22 : 0.12))
                    .frame(width: 60, height: 60)
                Text(initials)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(rankColor)
            }

            // Name + speed + bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(rider.memberName)
                        .font(TVFont.cardHeadline())
                        .foregroundStyle(Color.tvTextPrimary)
                        .lineLimit(1)
                    Spacer()
                    // Speed chip
                    if rider.avgSpeed > 0 {
                        HStack(spacing: 5) {
                            Image(systemName: "speedometer")
                                .font(.system(size: 18))
                            Text(String(format: "%.1f km/h", rider.avgSpeed))
                                .font(TVFont.dataLabel())
                                .monospacedDigit()
                        }
                        .foregroundStyle(Color.tvTextSecondary)
                    }
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.tvDivider)
                            .frame(height: 4)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.tvAccent, Color.tvAccent.opacity(0.55)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: barWidth, height: 4)
                    }
                    .onAppear {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.2)) {
                            barWidth = geo.size.width * barFill
                        }
                    }
                }
                .frame(height: 4)
            }

            // KM value
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f", rider.totalKM))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(isFocused ? Color.tvAccent : Color.tvTextPrimary)
                    .monospacedDigit()
                Text("km")
                    .font(TVFont.caption())
                    .foregroundStyle(Color.tvTextSecondary)
            }
            .frame(width: 110, alignment: .trailing)
        }
        .padding(.horizontal, TVLayout.cardPadding)
        .padding(.vertical, 18)
        .tvFocusCard(isFocused: isFocused, baseColor: .tvCard)
        .focusable()
        .focused($isFocused)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(rider.memberName), rank \(rank), \(String(format: "%.1f", rider.totalKM)) kilometres, \(rider.totalRides) rides"
        )
    }
}

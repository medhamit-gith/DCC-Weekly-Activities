//
//  TVAnalysisView.swift
//  DCC Weekly Activities TV
//
//  "Analysis" tab — ESPN-style per-rider deep stats, rebuilt to UX spec:
//  — Left sidebar (360pt): focusable rider selector list
//  — Right panel: selected rider's full performance report
//    · 4 hero stat boxes with count-up animation
//    · 4 "vs Club Average" comparison bars
//    · Week-on-week trend card
//    · Individual rides list
//  — Focus: Strava orange glow + scale per spec
//  — Spring animation on bar widths when rider changes
//
//  Depends on TVDesignSystem.swift.
//  Uses TVMemberStats / TVTrendDirection / tvRankColor() from TVRootView.swift.
//

import SwiftUI

// MARK: - Root view

struct TVAnalysisView: View {

    let memberStats: [TVMemberStats]

    @State private var selectedRider: TVMemberStats?
    @FocusState private var focusedRider: String?

    // memberStats is sorted by totalKM descending (rank = index + 1)
    private var clubAvgKM: Double {
        guard !memberStats.isEmpty else { return 0 }
        return memberStats.reduce(0) { $0 + $1.totalKM } / Double(memberStats.count)
    }
    private var clubAvgSpeed: Double {
        let valid = memberStats.filter { $0.avgSpeed > 0 }
        guard !valid.isEmpty else { return 0 }
        return valid.reduce(0) { $0 + $1.avgSpeed } / Double(valid.count)
    }
    private var clubAvgElevation: Double {
        guard !memberStats.isEmpty else { return 0 }
        return memberStats.reduce(0) { $0 + $1.totalElevation } / Double(memberStats.count)
    }
    private var clubAvgRides: Double {
        guard !memberStats.isEmpty else { return 0 }
        return Double(memberStats.reduce(0) { $0 + $1.totalRides }) / Double(memberStats.count)
    }

    private func rank(of stats: TVMemberStats) -> Int {
        (memberStats.firstIndex(where: { $0.id == stats.id }) ?? 0) + 1
    }

    var body: some View {
        HStack(spacing: 0) {

            // ── LEFT SIDEBAR: Rider selector ────────────────────────
            VStack(alignment: .leading, spacing: 0) {

                TVSectionLabel(eyebrow: "SELECT RIDER", title: "Analysis")
                    .padding(.top, 28)
                    .padding(.bottom, 20)

                Rectangle()
                    .fill(Color.tvDivider)
                    .frame(height: 1)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(memberStats) { rider in
                            let riderRank = rank(of: rider)
                            let isSelected = selectedRider?.id == rider.id

                            AnalysisSidebarRow(
                                rider: rider,
                                rank: riderRank,
                                isSelected: isSelected,
                                isFocused: focusedRider == rider.id.uuidString
                            )
                            .focused($focusedRider, equals: rider.id.uuidString)
                            .onAppear {
                                if selectedRider == nil {
                                    selectedRider = memberStats.first
                                }
                            }
                            .onChange(of: focusedRider) { _, newFocus in
                                if newFocus == rider.id.uuidString {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        selectedRider = rider
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, TVLayout.sectionGap)
                    .padding(.horizontal, 8)
                }
            }
            .padding(.leading, TVLayout.screenMargin)
            .frame(width: 360)

            // Divider
            Rectangle()
                .fill(Color.tvDivider)
                .frame(width: 1)

            // ── RIGHT PANEL: Rider detail ────────────────────────────
            if let rider = selectedRider ?? memberStats.first {
                AnalysisDetailPanel(
                    rider: rider,
                    rank: rank(of: rider),
                    clubAvgKM: clubAvgKM,
                    clubAvgSpeed: clubAvgSpeed,
                    clubAvgElevation: clubAvgElevation,
                    clubAvgRides: clubAvgRides,
                    maxKM: memberStats.first?.totalKM ?? 1
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .id(rider.id)
            } else {
                VStack {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 72))
                        .foregroundStyle(Color.tvTextTertiary)
                    Text("Select a rider")
                        .font(TVFont.cardHeadline())
                        .foregroundStyle(Color.tvTextTertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .animation(.easeOut(duration: 0.22), value: selectedRider?.id)
    }
}

// MARK: - Sidebar row

private struct AnalysisSidebarRow: View {
    let rider: TVMemberStats
    let rank: Int
    let isSelected: Bool
    let isFocused: Bool

    private var initials: String {
        let parts = rider.memberName.split(separator: " ")
        let first = parts.first.map { String($0.prefix(1)) } ?? "?"
        let last  = parts.dropFirst().first.map { String($0.prefix(1)) } ?? ""
        return (first + last).uppercased()
    }

    var body: some View {
        HStack(spacing: 14) {
            // Avatar / initials
            ZStack {
                Circle()
                    .fill(tvRankColor(rank).opacity(isSelected || isFocused ? 0.25 : 0.12))
                    .frame(width: 52, height: 52)
                Text(initials)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(tvRankColor(rank))
            }

            // Name + km
            VStack(alignment: .leading, spacing: 3) {
                Text(rider.memberName)
                    .font(TVFont.cardHeadline())
                    .foregroundStyle(isSelected || isFocused ? Color.tvTextPrimary : Color.tvTextSecondary)
                    .lineLimit(1)
                Text(String(format: "%.1f km · %d rides", rider.totalKM, rider.totalRides))
                    .font(TVFont.caption())
                    .foregroundStyle(Color.tvTextTertiary)
                    .monospacedDigit()
            }

            Spacer()

            // Rank badge
            Text("#\(rank)")
                .font(TVFont.dataLabel())
                .foregroundStyle(isFocused || isSelected ? Color.tvAccent : Color.tvTextTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.tvAccent.opacity(0.12) : (isFocused ? Color.tvCardFocused : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isSelected ? Color.tvAccent.opacity(0.4) : (isFocused ? Color.tvAccent.opacity(0.3) : Color.clear),
                    lineWidth: 1.5
                )
        )
        .scaleEffect(isFocused ? 1.03 : 1.0)
        .animation(
            isFocused ? .easeOut(duration: 0.12) : .easeOut(duration: 0.35),
            value: isFocused
        )
        .focusable()
        .accessibilityLabel(
            isSelected
                ? "\(rider.memberName), rank \(rank), currently selected"
                : "\(rider.memberName), rank \(rank)"
        )
        .accessibilityHint("Select to view full breakdown")
    }
}

// MARK: - Detail panel

private struct AnalysisDetailPanel: View {
    let rider: TVMemberStats
    let rank: Int
    let clubAvgKM: Double
    let clubAvgSpeed: Double
    let clubAvgElevation: Double
    let clubAvgRides: Double
    let maxKM: Double

    @State private var animateNumbers = false
    @State private var animateBars = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: TVLayout.cardGap) {

                // ── Hero header ──────────────────────────────────────
                HStack(spacing: TVLayout.cardGap) {
                    // Rank badge
                    ZStack {
                        Circle()
                            .fill(tvRankColor(rank).opacity(0.2))
                            .frame(width: 100, height: 100)
                        Circle()
                            .strokeBorder(tvRankColor(rank).opacity(0.55), lineWidth: 2)
                            .frame(width: 100, height: 100)
                        Text("\(rank)")
                            .font(TVFont.rankNumber())
                            .foregroundStyle(tvRankColor(rank))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(rider.memberName)
                            .font(TVFont.sectionHeader())
                            .foregroundStyle(Color.tvTextPrimary)

                        // Trend badge
                        AnalysisTrendBadge(stats: rider)
                    }

                    Spacer()
                }
                .padding(.top, 28)

                // ── 4 hero stat boxes ────────────────────────────────
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: TVLayout.cardGap),
                        GridItem(.flexible(), spacing: TVLayout.cardGap),
                        GridItem(.flexible(), spacing: TVLayout.cardGap),
                        GridItem(.flexible(), spacing: TVLayout.cardGap)
                    ],
                    spacing: TVLayout.cardGap
                ) {
                    AnalysisStatBox(
                        target: rider.totalKM, format: "%.1f", unit: "km",
                        label: "Distance", color: .tvAccent, animate: animateNumbers
                    )
                    AnalysisStatBox(
                        target: Double(rider.totalRides), format: "%.0f", unit: "",
                        label: "Rides", color: .tvSaffron, animate: animateNumbers
                    )
                    AnalysisStatBox(
                        target: rider.avgSpeed, format: "%.1f", unit: "km/h",
                        label: "Avg Speed", color: .tvGreen, animate: animateNumbers
                    )
                    AnalysisStatBox(
                        target: rider.totalElevation, format: "%.0f", unit: "m",
                        label: "Elevation", color: .tvBlue, animate: animateNumbers
                    )
                }

                // ── vs Club Average bars ─────────────────────────────
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("VS CLUB AVERAGE")
                            .font(TVFont.caption())
                            .tracking(2)
                            .foregroundStyle(Color.tvTextTertiary)
                        Spacer()
                        HStack(spacing: 6) {
                            Circle().fill(Color.tvAccent).frame(width: 8, height: 8)
                            Text("Rider")
                                .font(TVFont.caption())
                                .foregroundStyle(Color.tvTextSecondary)
                            Circle().fill(Color.tvDividerAccent).frame(width: 8, height: 8)
                            Text("Club avg")
                                .font(TVFont.caption())
                                .foregroundStyle(Color.tvTextSecondary)
                        }
                    }

                    ComparisonBar(
                        label: "Distance",
                        riderValue: rider.totalKM,
                        avgValue: clubAvgKM,
                        maxValue: max(rider.totalKM, clubAvgKM) * 1.1,
                        format: "%.1f km",
                        animate: animateBars
                    )
                    ComparisonBar(
                        label: "Avg Speed",
                        riderValue: rider.avgSpeed,
                        avgValue: clubAvgSpeed,
                        maxValue: max(rider.avgSpeed, clubAvgSpeed) * 1.1,
                        format: "%.1f km/h",
                        animate: animateBars
                    )
                    ComparisonBar(
                        label: "Elevation",
                        riderValue: rider.totalElevation,
                        avgValue: clubAvgElevation,
                        maxValue: max(rider.totalElevation, clubAvgElevation) * 1.1,
                        format: "%.0f m",
                        animate: animateBars
                    )
                    ComparisonBar(
                        label: "Rides",
                        riderValue: Double(rider.totalRides),
                        avgValue: clubAvgRides,
                        maxValue: max(Double(rider.totalRides), clubAvgRides) * 1.1,
                        format: "%.0f",
                        animate: animateBars
                    )
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

                // ── Individual rides ─────────────────────────────────
                if !rider.rides.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("RIDES THIS WEEK")
                            .font(TVFont.caption())
                            .tracking(2)
                            .foregroundStyle(Color.tvTextTertiary)

                        ForEach(rider.rides.sorted { $0.km > $1.km }) { ride in
                            AnalysisRideRow(ride: ride)
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
            }
            .padding(.horizontal, TVLayout.cardGap)
            .padding(.bottom, TVLayout.sectionGap)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.7)) {
                    animateNumbers = true
                    animateBars = true
                }
            }
        }
        .onChange(of: rider.id) { _, _ in
            animateNumbers = false
            animateBars = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.easeOut(duration: 0.6)) {
                    animateNumbers = true
                    animateBars = true
                }
            }
        }
    }
}

// MARK: - Stat box

private struct AnalysisStatBox: View {
    let target: Double
    let format: String
    let unit: String
    let label: String
    let color: Color
    let animate: Bool

    @State private var displayed: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label.uppercased())
                .font(TVFont.caption())
                .tracking(1.5)
                .foregroundStyle(Color.tvTextTertiary)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
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

            // Color accent bar
            Rectangle()
                .fill(color)
                .frame(height: 3)
                .cornerRadius(2)
        }
        .padding(TVLayout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: TVLayout.cardCornerRadius)
                .fill(Color.tvCard)
                .overlay(
                    RoundedRectangle(cornerRadius: TVLayout.cardCornerRadius)
                        .strokeBorder(color.opacity(0.2), lineWidth: 1)
                )
        )
        .onChange(of: animate) { _, newValue in
            if newValue {
                withAnimation(.easeOut(duration: 0.8)) { displayed = target }
            } else {
                displayed = 0
            }
        }
        .onChange(of: target) { _, newTarget in
            displayed = 0
            withAnimation(.easeOut(duration: 0.6)) { displayed = newTarget }
        }
        .accessibilityLabel("\(label): \(String(format: format, target)) \(unit)")
    }
}

// MARK: - Comparison bar

private struct ComparisonBar: View {
    let label: String
    let riderValue: Double
    let avgValue: Double
    let maxValue: Double
    let format: String
    let animate: Bool

    @State private var riderBarWidth: CGFloat = 0
    @State private var avgBarWidth: CGFloat = 0

    private var isAboveAverage: Bool { riderValue > avgValue }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(TVFont.dataLabel())
                    .foregroundStyle(Color.tvTextSecondary)
                Spacer()
                // Above/below badge
                if riderValue > 0 && avgValue > 0 {
                    let diff = ((riderValue - avgValue) / avgValue) * 100
                    Text(diff >= 0 ? String(format: "+%.0f%%", diff) : String(format: "%.0f%%", diff))
                        .font(TVFont.caption())
                        .foregroundStyle(isAboveAverage ? Color.tvGreen : Color.tvRed)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill((isAboveAverage ? Color.tvGreen : Color.tvRed).opacity(0.12))
                        )
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.tvDivider)
                        .frame(height: 10)

                    // Rider bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.tvAccent, Color.tvAccent.opacity(0.6)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: riderBarWidth, height: 10)

                    // Club avg marker
                    Rectangle()
                        .fill(Color.tvTextSecondary.opacity(0.5))
                        .frame(width: 2, height: 18)
                        .offset(x: avgBarWidth)
                }
                .onAppear {
                    if animate { animateBars(geo: geo) }
                }
                .onChange(of: animate) { _, newValue in
                    if newValue { animateBars(geo: geo) }
                    else {
                        riderBarWidth = 0
                        avgBarWidth = 0
                    }
                }
                .onChange(of: riderValue) { _, _ in
                    riderBarWidth = 0
                    avgBarWidth = 0
                    animateBars(geo: geo)
                }
            }
            .frame(height: 18)

            // Value labels
            HStack {
                Text(String(format: format, riderValue))
                    .font(TVFont.caption())
                    .foregroundStyle(Color.tvAccent)
                    .monospacedDigit()
                Spacer()
                Text("avg: \(String(format: format, avgValue))")
                    .font(TVFont.caption())
                    .foregroundStyle(Color.tvTextTertiary)
                    .monospacedDigit()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(label): rider \(String(format: format, riderValue)), club average \(String(format: format, avgValue))"
        )
    }

    private func animateBars(geo: GeometryProxy) {
        guard maxValue > 0 else { return }
        withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.1)) {
            riderBarWidth = geo.size.width * CGFloat(min(riderValue / maxValue, 1.0))
            avgBarWidth   = geo.size.width * CGFloat(min(avgValue / maxValue, 1.0))
        }
    }
}

// MARK: - Ride row

private struct AnalysisRideRow: View {
    let ride: TVRideEntry

    private var durationLabel: String {
        let h = ride.movingTime / 3600
        let m = (ride.movingTime % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "figure.outdoor.cycle")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Color.tvAccent.opacity(0.7))
                .frame(width: 32)

            Text(String(format: "%.1f km", ride.km))
                .font(TVFont.bodyData())
                .foregroundStyle(Color.tvTextPrimary)
                .monospacedDigit()
                .frame(width: 130, alignment: .leading)

            if ride.avgSpeed > 0 {
                HStack(spacing: 5) {
                    Image(systemName: "speedometer").font(.system(size: 16))
                    Text(String(format: "%.1f km/h", ride.avgSpeed)).monospacedDigit()
                }
                .font(TVFont.caption())
                .foregroundStyle(Color.tvTextSecondary)
            }

            if ride.elevation > 0 {
                HStack(spacing: 5) {
                    Image(systemName: "mountain.2").font(.system(size: 16))
                    Text(String(format: "%.0f m", ride.elevation)).monospacedDigit()
                }
                .font(TVFont.caption())
                .foregroundStyle(Color.tvTextSecondary)
            }

            Spacer()

            if ride.movingTime > 0 {
                Text(durationLabel)
                    .font(TVFont.caption())
                    .foregroundStyle(Color.tvTextTertiary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.tvBackground.opacity(0.6))
        )
    }
}

// MARK: - Trend badge

private struct AnalysisTrendBadge: View {
    let stats: TVMemberStats

    private var label: String {
        switch stats.trend {
        case .up:
            let pct = stats.previousWeekKM > 0
                ? ((stats.totalKM - stats.previousWeekKM) / stats.previousWeekKM) * 100
                : 0
            return "↑ +\(String(format: "%.0f", pct))% vs last week"
        case .down:
            let pct = stats.previousWeekKM > 0
                ? ((stats.previousWeekKM - stats.totalKM) / stats.previousWeekKM) * 100
                : 0
            return "↓ -\(String(format: "%.0f", pct))% vs last week"
        case .stable: return "→ On par with last week"
        case .new:    return "★ First rides this week"
        }
    }

    private var color: Color {
        switch stats.trend {
        case .up:     return Color.tvGreen
        case .down:   return Color.tvRed
        case .stable: return Color.tvTextSecondary
        case .new:    return Color.tvSaffron
        }
    }

    var body: some View {
        Text(label)
            .font(TVFont.dataLabel())
            .foregroundStyle(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
                    .overlay(Capsule().strokeBorder(color.opacity(0.3), lineWidth: 1))
            )
    }
}

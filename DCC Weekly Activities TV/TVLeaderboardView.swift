//
//  TVLeaderboardView.swift
//  DCC Weekly Activities TV
//
//  Sports-broadcast leaderboard rebuilt to UX spec:
//  — Left panel (680pt): scrollable ranked list with animated progress bars
//  — Right panel: hero card for focused/selected rider
//  — Metric picker: Distance / Rides / Elevation / Avg Speed
//  — Focus: Strava orange glow + scale 1.06× per spec
//  — Accessibility labels on every interactive element
//
//  Depends on TVDesignSystem.swift.
//  Uses TVMemberStats / TVTrendDirection from TVRootView.swift.
//

import SwiftUI

// MARK: - Metric picker

enum LeaderMetric: String, CaseIterable {
    case distance  = "Distance"
    case rides     = "Rides"
    case elevation = "Elevation"
    case speed     = "Avg Speed"

    var columnHeader: String {
        switch self {
        case .distance:  return "KM"
        case .rides:     return "RIDES"
        case .elevation: return "ELEV (m)"
        case .speed:     return "AVG km/h"
        }
    }
}

// MARK: - Root view

struct TVLeaderboardView: View {

    let memberStats: [TVMemberStats]

    @FocusState private var focusedRider: String?
    @State private var animateRows  = false
    @State private var selectedMetric: LeaderMetric = .distance

    private var sorted: [TVMemberStats] {
        switch selectedMetric {
        case .distance:  return memberStats.sorted { $0.totalKM > $1.totalKM }
        case .rides:     return memberStats.sorted { $0.totalRides > $1.totalRides }
        case .elevation: return memberStats.sorted { $0.totalElevation > $1.totalElevation }
        case .speed:     return memberStats.sorted { $0.avgSpeed > $1.avgSpeed }
        }
    }

    private var heroSubject: TVMemberStats? {
        if let id = focusedRider { return sorted.first(where: { $0.id.uuidString == id }) }
        return sorted.first
    }

    var body: some View {
        HStack(spacing: 0) {

            // ── LEFT PANEL ──────────────────────────────────────────
            VStack(alignment: .leading, spacing: 0) {

                // Header + metric picker
                HStack(alignment: .top) {
                    TVSectionLabel(
                        eyebrow: "WEEKLY LEADERBOARD",
                        title: "Ride Rankings"
                    )

                    Spacer()

                    // Metric picker pills
                    HStack(spacing: 10) {
                        ForEach(LeaderMetric.allCases, id: \.self) { metric in
                            MetricPillButton(
                                metric: metric,
                                isSelected: selectedMetric == metric
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedMetric = metric
                                }
                            }
                        }
                    }
                }
                .padding(.leading, TVLayout.screenMargin)
                .padding(.trailing, TVLayout.screenMargin)
                .padding(.top, 28)
                .padding(.bottom, 22)

                // Divider
                Rectangle()
                    .fill(Color.tvDivider)
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                // Column headers
                HStack(spacing: 0) {
                    Text("RANK")
                        .frame(width: 80, alignment: .leading)
                    Text("RIDER")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(selectedMetric.columnHeader)
                        .frame(width: 160, alignment: .trailing)
                    Text("RIDES")
                        .frame(width: 110, alignment: .trailing)
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 150)
                }
                .font(TVFont.caption())
                .tracking(1.5)
                .foregroundStyle(Color.tvTextTertiary)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                // Row list
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(Array(sorted.enumerated()), id: \.element.id) { index, stats in
                            TVLeaderboardRow(
                                rank: index + 1,
                                stats: stats,
                                metric: selectedMetric,
                                maxValue: maxValue(for: selectedMetric),
                                isFocused: focusedRider == stats.id.uuidString
                            )
                            .focused($focusedRider, equals: stats.id.uuidString)
                            .offset(y: animateRows ? 0 : 30)
                            .opacity(animateRows ? 1 : 0)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.055),
                                value: animateRows
                            )

                            Rectangle()
                                .fill(Color.tvDivider)
                                .frame(height: 1)
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .frame(width: 700)

            // ── RIGHT PANEL ─────────────────────────────────────────
            TVLeaderboardHeroCard(
                stats: heroSubject,
                rank: heroSubject.flatMap { s in
                    sorted.firstIndex(where: { $0.id == s.id }).map { $0 + 1 }
                } ?? 1,
                allStats: sorted
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                animateRows = true
            }
        }
    }

    private func maxValue(for metric: LeaderMetric) -> Double {
        switch metric {
        case .distance:  return sorted.first?.totalKM ?? 1
        case .rides:     return Double(sorted.first?.totalRides ?? 1)
        case .elevation: return sorted.first?.totalElevation ?? 1
        case .speed:     return sorted.first?.avgSpeed ?? 1
        }
    }
}

// MARK: - Metric pill button

private struct MetricPillButton: View {
    let metric: LeaderMetric
    let isSelected: Bool
    let action: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            Text(metric.rawValue)
                .font(TVFont.dataLabel())
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected
                              ? Color.tvAccent.opacity(0.22)
                              : Color.tvCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    isSelected
                                        ? Color.tvAccent.opacity(0.45)
                                        : Color.tvDivider,
                                    lineWidth: 1
                                )
                        )
                )
                .foregroundStyle(isSelected ? Color.tvTextPrimary : Color.tvTextSecondary)
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.06 : 1.0)
        .shadow(color: isFocused ? Color.tvAccent.opacity(0.25) : .clear, radius: 12)
        .animation(.easeOut(duration: isFocused ? 0.12 : 0.35), value: isFocused)
        .accessibilityLabel(isSelected ? "\(metric.rawValue), selected" : metric.rawValue)
        .accessibilityHint("Sort leaderboard by \(metric.rawValue.lowercased())")
    }
}

// MARK: - Leaderboard row

struct TVLeaderboardRow: View {
    let rank: Int
    let stats: TVMemberStats
    let metric: LeaderMetric
    let maxValue: Double
    let isFocused: Bool

    @State private var barWidth: CGFloat = 0

    private var metricValue: Double {
        switch metric {
        case .distance:  return stats.totalKM
        case .rides:     return Double(stats.totalRides)
        case .elevation: return stats.totalElevation
        case .speed:     return stats.avgSpeed
        }
    }

    private var metricFormatted: String {
        switch metric {
        case .distance:  return String(format: "%.1f km", stats.totalKM)
        case .rides:     return "\(stats.totalRides)"
        case .elevation: return String(format: "%.0f m", stats.totalElevation)
        case .speed:     return String(format: "%.1f", stats.avgSpeed)
        }
    }

    private var trendLabel: String {
        switch stats.trend {
        case .up:     return "↑ Up from last week"
        case .down:   return "↓ Down from last week"
        case .stable: return "→ Same as last week"
        case .new:    return "★ New this week"
        }
    }

    private var trendColor: Color {
        switch stats.trend {
        case .up:     return Color.tvGreen
        case .down:   return Color.tvRed
        case .stable: return Color.tvTextSecondary
        case .new:    return Color.tvSaffron
        }
    }

    var body: some View {
        HStack(spacing: 0) {

            // Rank badge
            Group {
                if rank <= 3 {
                    ZStack {
                        Circle()
                            .fill(tvRankColor(rank).opacity(isFocused ? 0.28 : 0.16))
                            .frame(width: 52, height: 52)
                        Text("\(rank)")
                            .font(TVFont.rankNumber())
                            .foregroundStyle(tvRankColor(rank))
                    }
                    .frame(width: 80)
                } else {
                    Text("\(rank)")
                        .font(TVFont.rankSmall())
                        .foregroundStyle(isFocused ? Color.tvAccent : Color.tvTextTertiary)
                        .frame(width: 80, alignment: .center)
                }
            }

            // Name + trend
            VStack(alignment: .leading, spacing: 5) {
                Text(stats.memberName)
                    .font(TVFont.cardHeadline())
                    .foregroundStyle(Color.tvTextPrimary)
                    .lineLimit(1)
                Text(trendLabel)
                    .font(TVFont.caption())
                    .foregroundStyle(trendColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Metric value
            Text(metricFormatted)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(isFocused ? Color.tvAccent : Color.tvTextPrimary)
                .monospacedDigit()
                .frame(width: 160, alignment: .trailing)

            // Ride count
            Text("\(stats.totalRides)")
                .font(TVFont.caption())
                .foregroundStyle(Color.tvTextSecondary)
                .frame(width: 110, alignment: .trailing)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.tvDivider)
                        .frame(height: 5)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.tvAccent, Color.tvAccent.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: barWidth, height: 5)
                }
                .frame(maxHeight: .infinity)
                .onAppear {
                    let ratio = maxValue > 0 ? metricValue / maxValue : 0
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.2)) {
                        barWidth = geo.size.width * ratio
                    }
                }
                .onChange(of: metric) { _, _ in
                    barWidth = 0
                    let ratio = maxValue > 0 ? metricValue / maxValue : 0
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.08)) {
                        barWidth = geo.size.width * ratio
                    }
                }
                .onChange(of: isFocused) { _, focused in
                    if focused {
                        withAnimation(.easeOut(duration: 0.15)) {
                            barWidth = barWidth  // trigger glow redraw
                        }
                    }
                }
            }
            .frame(width: 150, height: 70)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 86)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isFocused ? Color.tvCardFocused : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isFocused ? Color.tvAccent.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
        .shadow(
            color: isFocused ? Color.tvAccent.opacity(0.22) : .clear,
            radius: 18, y: 6
        )
        .scaleEffect(isFocused ? TVLayout.focusedScale : 1.0)
        .animation(
            isFocused ? .easeOut(duration: 0.12) : .easeOut(duration: 0.35),
            value: isFocused
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rowAccessibilityLabel)
    }

    private var rowAccessibilityLabel: String {
        let rankText: String
        switch rank {
        case 1: rankText = "1st place"
        case 2: rankText = "2nd place"
        case 3: rankText = "3rd place"
        default: rankText = "Ranked \(rank)"
        }
        let trendText: String
        switch stats.trend {
        case .up:     trendText = "improving vs last week"
        case .down:   trendText = "declining vs last week"
        case .stable: trendText = "stable vs last week"
        case .new:    trendText = "new this week"
        }
        return "\(stats.memberName), \(rankText), \(metricFormatted), \(stats.totalRides) rides, \(trendText)"
    }
}

// MARK: - Hero card (right panel)

struct TVLeaderboardHeroCard: View {

    let stats: TVMemberStats?
    let rank: Int
    let allStats: [TVMemberStats]

    @State private var animateNumbers = false

    var body: some View {
        ZStack {
            // Panel background
            LinearGradient(
                colors: [Color.tvCard, Color.tvSurface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Rank color ambient glow
            if rank <= 3 {
                Circle()
                    .fill(tvRankColor(rank).opacity(0.10))
                    .frame(width: 500, height: 500)
                    .blur(radius: 80)
                    .offset(x: 0, y: -80)
            } else {
                Circle()
                    .fill(Color.tvAccent.opacity(0.06))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: 0, y: -60)
            }

            if let stats = stats {
                VStack(spacing: 0) {
                    // Rank badge
                    ZStack {
                        Circle()
                            .fill(tvRankColor(rank).opacity(0.20))
                            .frame(width: 110, height: 110)
                        Circle()
                            .strokeBorder(tvRankColor(rank).opacity(0.55), lineWidth: 2)
                            .frame(width: 110, height: 110)
                        Text("\(rank)")
                            .font(TVFont.rankNumber())
                            .foregroundStyle(tvRankColor(rank))
                    }
                    .padding(.top, TVLayout.sectionGap)

                    // Name
                    Text(stats.memberName)
                        .font(TVFont.sectionHeader())
                        .foregroundStyle(Color.tvTextPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.top, 22)
                        .padding(.horizontal, TVLayout.cardPadding)

                    // Trend badge
                    HeroTrendBadge(stats: stats)
                        .padding(.top, 14)

                    Spacer()

                    // 2×2 stat grid with counting animation
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: TVLayout.cardGap),
                            GridItem(.flexible(), spacing: TVLayout.cardGap)
                        ],
                        spacing: TVLayout.cardGap
                    ) {
                        HeroStatBox(
                            target: stats.totalKM,
                            format: "%.1f",
                            unit: "Kilometres",
                            animate: animateNumbers
                        )
                        HeroStatBox(
                            target: Double(stats.totalRides),
                            format: "%.0f",
                            unit: "Rides",
                            animate: animateNumbers
                        )
                        HeroStatBox(
                            target: stats.totalElevation,
                            format: "%.0f",
                            unit: "Metres elev",
                            animate: animateNumbers
                        )
                        HeroStatBox(
                            target: stats.avgSpeed,
                            format: "%.1f",
                            unit: "Avg km/h",
                            animate: animateNumbers
                        )
                    }
                    .padding(.horizontal, TVLayout.cardPadding)
                    .padding(.bottom, TVLayout.sectionGap)
                }
            } else {
                VStack(spacing: TVLayout.cardGap) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.tvTextTertiary)
                    Text("Select a rider")
                        .font(TVFont.cardHeadline())
                        .foregroundStyle(Color.tvTextTertiary)
                }
            }
        }
        .clipShape(Rectangle())
        .overlay(
            Rectangle()
                .fill(Color.tvDivider)
                .frame(width: 1),
            alignment: .leading
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(heroAccessibilityLabel)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.easeOut(duration: 0.7)) {
                    animateNumbers = true
                }
            }
        }
        .onChange(of: stats?.id) { _, _ in
            animateNumbers = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                withAnimation(.easeOut(duration: 0.55)) {
                    animateNumbers = true
                }
            }
        }
    }

    private var heroAccessibilityLabel: String {
        guard let s = stats else { return "No rider selected" }
        let rankText: String
        switch rank {
        case 1: rankText = "1st place"
        case 2: rankText = "2nd place"
        case 3: rankText = "3rd place"
        default: rankText = "Ranked \(rank)"
        }
        return "\(s.memberName), \(rankText). \(String(format: "%.1f", s.totalKM)) kilometres, \(s.totalRides) rides, \(String(format: "%.1f", s.avgSpeed)) km/h average speed, \(String(format: "%.0f", s.totalElevation)) metres elevation."
    }
}

// MARK: - Hero stat box

private struct HeroStatBox: View {
    let target: Double
    let format: String
    let unit: String
    let animate: Bool

    @State private var displayed: Double = 0

    var body: some View {
        VStack(spacing: 10) {
            Text(String(format: format, displayed))
                .font(TVFont.heroStat())
                .foregroundStyle(Color.tvTextPrimary)
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(unit)
                .font(TVFont.caption())
                .foregroundStyle(Color.tvTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(TVLayout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: TVLayout.cardCornerRadius)
                .fill(Color.tvBackground.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: TVLayout.cardCornerRadius)
                        .strokeBorder(Color.tvDivider, lineWidth: 1)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(unit): \(String(format: format, target))")
    }
}

// MARK: - Hero trend badge

private struct HeroTrendBadge: View {
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
        case .stable:
            return "→ On par with last week"
        case .new:
            return "★ First rides this week"
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
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
                    .overlay(Capsule().strokeBorder(color.opacity(0.3), lineWidth: 1))
            )
    }
}

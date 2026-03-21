//
//  TVInsightsView.swift
//  DCC Weekly Activities TV
//
//  "Performance Analysis" tab — rebuilt to UX spec:
//  — 3-column grid of 6 award cards, each highlighting a category winner
//  — Categories: Climber, Speed, Consistent, Distance, Rising Star, Club Champion
//  — Staggered card entrance animation (0.05s delay between cards)
//  — Focus: Strava orange glow + scale per spec
//  — Composite "Club Champion" score: 50% distance, 30% rides, 20% elevation
//
//  Depends on TVDesignSystem.swift.
//  Uses TVMemberStats / TVTrendDirection from TVRootView.swift.
//

import SwiftUI

// MARK: - Award definition

private struct InsightAward: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let color: Color
    let rider: TVMemberStats?
    let statValue: String
    let comparisonLabel: String
    let comparisonIsPositive: Bool?   // nil = neutral
}

// MARK: - Root view

struct TVInsightsView: View {

    let memberStats: [TVMemberStats]

    @State private var animateCards = false

    private var awards: [InsightAward] {
        guard !memberStats.isEmpty else { return [] }

        // 1. Top Climber
        let topClimber = memberStats.max(by: { $0.totalElevation < $1.totalElevation })

        // 2. Speed Demon (min 1 ride)
        let speedDemon = memberStats.filter { $0.totalRides > 0 }
                                    .max(by: { $0.avgSpeed < $1.avgSpeed })

        // 3. Most Consistent
        let mostConsistent = memberStats.max(by: { $0.totalRides < $1.totalRides })

        // 4. Distance King
        let distanceKing = memberStats.max(by: { $0.totalKM < $1.totalKM })

        // 5. Rising Star — biggest % improvement vs last week
        let risingStarData: (TVMemberStats?, Double) = {
            let candidates = memberStats.filter { $0.previousWeekKM > 0 }
            guard let best = candidates.max(by: {
                let a = ($0.totalKM - $0.previousWeekKM) / $0.previousWeekKM
                let b = ($1.totalKM - $1.previousWeekKM) / $1.previousWeekKM
                return a < b
            }) else { return (nil, 0) }
            let pct = ((best.totalKM - best.previousWeekKM) / best.previousWeekKM) * 100
            return (best, pct)
        }()

        // 6. Club Champion (composite score)
        let maxKM   = memberStats.map { $0.totalKM }.max() ?? 1
        let maxRide = Double(memberStats.map { $0.totalRides }.max() ?? 1)
        let maxElev = memberStats.map { $0.totalElevation }.max() ?? 1

        let champion = memberStats.max(by: { a, b in
            let scoreA = 0.5 * (a.totalKM / maxKM)
                       + 0.3 * (Double(a.totalRides) / maxRide)
                       + 0.2 * (a.totalElevation / maxElev)
            let scoreB = 0.5 * (b.totalKM / maxKM)
                       + 0.3 * (Double(b.totalRides) / maxRide)
                       + 0.2 * (b.totalElevation / maxElev)
            return scoreA < scoreB
        })

        return [
            InsightAward(
                icon: "mountain.2.fill",
                title: "Top Climber",
                color: .tvSaffron,
                rider: topClimber,
                statValue: topClimber.map { String(format: "%.0f m", $0.totalElevation) } ?? "—",
                comparisonLabel: "Total elevation gain",
                comparisonIsPositive: nil
            ),
            InsightAward(
                icon: "bolt.fill",
                title: "Speed Demon",
                color: .tvAccent,
                rider: speedDemon,
                statValue: speedDemon.map { String(format: "%.1f km/h", $0.avgSpeed) } ?? "—",
                comparisonLabel: "Average speed",
                comparisonIsPositive: nil
            ),
            InsightAward(
                icon: "calendar.badge.checkmark",
                title: "Most Consistent",
                color: .tvGreen,
                rider: mostConsistent,
                statValue: mostConsistent.map { "\($0.totalRides) rides" } ?? "—",
                comparisonLabel: "Total rides this week",
                comparisonIsPositive: nil
            ),
            InsightAward(
                icon: "road.lanes",
                title: "Distance King",
                color: .tvBlue,
                rider: distanceKing,
                statValue: distanceKing.map { String(format: "%.1f km", $0.totalKM) } ?? "—",
                comparisonLabel: "Total distance this week",
                comparisonIsPositive: nil
            ),
            InsightAward(
                icon: "arrow.up.right.circle.fill",
                title: "Rising Star",
                color: Color(red: 0.7, green: 0.4, blue: 1.0),
                rider: risingStarData.0,
                statValue: risingStarData.0 != nil
                    ? String(format: "+%.0f%%", risingStarData.1)
                    : "—",
                comparisonLabel: "Improvement vs last week",
                comparisonIsPositive: risingStarData.1 > 0 ? true : nil
            ),
            InsightAward(
                icon: "rosette",
                title: "Club Champion",
                color: .tvGold,
                rider: champion,
                statValue: champion.map { String(format: "%.1f km", $0.totalKM) } ?? "—",
                comparisonLabel: "Distance · Rides · Elevation composite",
                comparisonIsPositive: nil
            )
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            TVSectionLabel(eyebrow: "PERFORMANCE ANALYSIS", title: "This Week's Awards")
                .padding(.top, 28)
                .padding(.leading, TVLayout.screenMargin)
                .padding(.bottom, 28)

            Rectangle()
                .fill(Color.tvDivider)
                .frame(height: 1)
                .padding(.horizontal, TVLayout.screenMargin)

            if awards.isEmpty {
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 72))
                        .foregroundStyle(Color.tvTextTertiary)
                    Text("No data for insights yet")
                        .font(TVFont.sectionHeader())
                        .foregroundStyle(Color.tvTextSecondary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                // 3-column award grid
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: TVLayout.cardGap),
                        GridItem(.flexible(), spacing: TVLayout.cardGap),
                        GridItem(.flexible(), spacing: TVLayout.cardGap)
                    ],
                    spacing: TVLayout.cardGap
                ) {
                    ForEach(Array(awards.enumerated()), id: \.element.id) { index, award in
                        InsightAwardCard(award: award, animateDelay: Double(index) * 0.065)
                            .offset(y: animateCards ? 0 : 30)
                            .opacity(animateCards ? 1 : 0)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.065),
                                value: animateCards
                            )
                    }
                }
                .padding(.horizontal, TVLayout.screenMargin)
                .padding(.top, TVLayout.cardGap)
                .padding(.bottom, TVLayout.sectionGap)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                animateCards = true
            }
        }
    }
}

// MARK: - Award card

private struct InsightAwardCard: View {
    let award: InsightAward
    let animateDelay: Double

    @FocusState private var isFocused: Bool

    private var initials: String {
        guard let rider = award.rider else { return "?" }
        let parts = rider.memberName.split(separator: " ")
        let first = parts.first.map { String($0.prefix(1)) } ?? "?"
        let last  = parts.dropFirst().first.map { String($0.prefix(1)) } ?? ""
        return (first + last).uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Top: icon + title bar
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(award.color.opacity(isFocused ? 0.25 : 0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: award.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(award.color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(award.title.uppercased())
                        .font(TVFont.caption())
                        .tracking(2)
                        .foregroundStyle(award.color)
                    if let rider = award.rider {
                        Text(rider.memberName)
                            .font(TVFont.cardHeadline())
                            .foregroundStyle(Color.tvTextPrimary)
                            .lineLimit(1)
                    } else {
                        Text("No data")
                            .font(TVFont.cardHeadline())
                            .foregroundStyle(Color.tvTextTertiary)
                    }
                }
                Spacer()

                // Initials avatar
                if award.rider != nil {
                    ZStack {
                        Circle()
                            .fill(award.color.opacity(0.15))
                            .frame(width: 56, height: 56)
                        Text(initials)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(award.color)
                    }
                }
            }
            .padding(.horizontal, TVLayout.cardPadding)
            .padding(.top, TVLayout.cardPadding)

            // Divider
            Rectangle()
                .fill(award.color.opacity(0.15))
                .frame(height: 1)
                .padding(.horizontal, TVLayout.cardPadding)
                .padding(.vertical, 20)

            // Stat value
            VStack(alignment: .leading, spacing: 8) {
                Text(award.statValue)
                    .font(TVFont.heroStat())
                    .foregroundStyle(Color.tvTextPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack(spacing: 8) {
                    if let positive = award.comparisonIsPositive {
                        Image(systemName: positive ? "arrow.up" : "arrow.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(positive ? Color.tvGreen : Color.tvRed)
                    }
                    Text(award.comparisonLabel)
                        .font(TVFont.caption())
                        .foregroundStyle(Color.tvTextSecondary)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, TVLayout.cardPadding)
            .padding(.bottom, TVLayout.cardPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: TVLayout.cardCornerRadius)
                .fill(Color.tvCard)
                .overlay(
                    RoundedRectangle(cornerRadius: TVLayout.cardCornerRadius)
                        .strokeBorder(
                            isFocused ? award.color.opacity(0.55) : Color.tvDivider,
                            lineWidth: isFocused ? 2 : 1
                        )
                )
        )
        .shadow(
            color: isFocused ? award.color.opacity(0.25) : .black.opacity(0.3),
            radius: isFocused ? 24 : 8,
            y: isFocused ? 10 : 3
        )
        .scaleEffect(isFocused ? TVLayout.focusedScale : 1.0)
        .animation(
            isFocused ? .easeOut(duration: 0.12) : .easeOut(duration: 0.35),
            value: isFocused
        )
        .focusable()
        .focused($isFocused)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            award.rider.map {
                "\(award.title): \($0.memberName), \(award.statValue)"
            } ?? "\(award.title): No data"
        )
    }
}

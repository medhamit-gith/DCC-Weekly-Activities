//
//  TVMemberStatsView.swift
//  DCC-Weekly-Activities
//
//  tvOS-optimised member statistics view.
//
//  10-Foot UI compliance (tvOS HIG):
//  - Minimum body font size 31pt
//  - Focus states via @FocusState with visual highlight (scale + border glow)
//  - .focusSection() groups stat cards for Siri Remote D-pad navigation
//  - No gesture-only interactions; all interactions work via Select button
//  - Trend emojis replaced with text labels for VoiceOver / TVML readability
//

import SwiftUI

#if os(tvOS)

// MARK: - Club Summary View

struct TVMemberStatsView: View {
    let stats: [MemberStats]

    var body: some View {
        ScrollView {
            VStack(spacing: 60) {

                // Week summary cards — grouped as a focus section so the
                // Siri Remote can navigate between them with the D-pad.
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 40
                ) {
                    TVLegacyStatCard(
                        title: "Total Distance",
                        value: String(format: "%.1f km", stats.reduce(0) { $0 + $1.totalKM }),
                        icon: "road.lanes",
                        color: .dccBlue
                    )

                    TVLegacyStatCard(
                        title: "Total Rides",
                        value: "\(stats.reduce(0) { $0 + $1.totalRides })",
                        icon: "bicycle",
                        color: .dccGreen
                    )

                    TVLegacyStatCard(
                        title: "Total Elevation",
                        value: String(format: "%.0f m", stats.reduce(0) { $0 + $1.totalElevation }),
                        icon: "mountain.2.fill",
                        color: .dccSaffron
                    )

                    TVLegacyStatCard(
                        title: "Active Members",
                        value: "\(stats.count)",
                        icon: "person.3.fill",
                        color: .dccBlue
                    )
                }
                .focusSection()   // D-pad navigates within this grid as a unit
                .padding(.horizontal, 80)
                .padding(.top, 60)

                // Top performers list
                VStack(alignment: .leading, spacing: 30) {
                    Text("Top Performers")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(Color.dccBlue)
                        .padding(.horizontal, 80)

                    ForEach(Array(stats.sorted { $0.totalKM > $1.totalKM }.prefix(10).enumerated()), id: \.element.id) { index, stat in
                        TVMemberRow(rank: index + 1, stat: stat)
                            .padding(.horizontal, 80)
                    }
                }
                .focusSection()
                .padding(.bottom, 60)
            }
        }
    }
}

// MARK: - Stat Card (legacy iOS-target tvOS component)
// Renamed to TVLegacyStatCard to avoid collision with TVOverviewView's TVStatCard
// in the tvOS app target.

struct TVLegacyStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(color)
                .accessibilityHidden(true)

            Text(value)
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(Color.primary)

            // tvOS HIG: body text minimum 31pt
            Text(title)
                .font(.system(size: 31))
                .foregroundStyle(Color.primary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(50)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .strokeBorder(
                            isFocused ? color.opacity(0.8) : Color.clear,
                            lineWidth: 3
                        )
                )
        )
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .shadow(
            color: isFocused ? color.opacity(0.4) : .clear,
            radius: isFocused ? 24 : 0
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .focusable()
        .focused($isFocused)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Member Row

struct TVMemberRow: View {
    let rank: Int
    let stat: MemberStats

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 40) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                Text("#\(rank)")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(rankColor)
            }
            .frame(width: 100)
            .accessibilityHidden(true)

            // Name and trend text (emoji hidden, text label shown)
            VStack(alignment: .leading, spacing: 8) {
                Text(stat.memberName)
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(Color.primary)

                // Show text label instead of raw emoji so it reads on screen
                // and is announced clearly by VoiceOver.
                HStack(spacing: 6) {
                    Text(stat.trendEmoji)
                        .font(.system(size: 28))
                        .accessibilityHidden(true)
                    Text(trendTextLabel)
                        .font(.system(size: 31))  // ≥31pt body minimum
                        .foregroundStyle(Color.primary.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Stats
            VStack(alignment: .trailing, spacing: 8) {
                Text(String(format: "%.1f km", stat.totalKM))
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(Color.dccSaffron)

                // ≥31pt for body sub-text
                Text("\(stat.totalRides) rides  ·  \(String(format: "%.1f", stat.avgSpeed)) km/h")
                    .font(.system(size: 31))
                    .foregroundStyle(Color.primary.opacity(0.7))
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            isFocused ? Color.dccSaffron.opacity(0.8) : Color.clear,
                            lineWidth: 3
                        )
                )
        )
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .shadow(
            color: isFocused ? Color.dccSaffron.opacity(0.4) : .clear,
            radius: isFocused ? 24 : 0
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .focusable()
        .focused($isFocused)
        // Single natural-language accessibility label
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rowAccessibilityLabel)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return DCCColors.gold    // #B8860B — visible on dark/light
        case 2: return DCCColors.silver  // #6B7280
        case 3: return DCCColors.bronze  // #92400E
        default: return Color.dccBlue
        }
    }

    private var trendTextLabel: String {
        switch stat.currentWeekTrend {
        case .up:     return "Improving"
        case .down:   return "Declining"
        case .stable: return "Stable"
        case .new:    return "New member"
        }
    }

    private var rowAccessibilityLabel: String {
        let rankText: String
        switch rank {
        case 1: rankText = "1st place"
        case 2: rankText = "2nd place"
        case 3: rankText = "3rd place"
        default: rankText = "Ranked \(rank)"
        }
        return "\(stat.memberName), \(rankText), \(String(format: "%.1f", stat.totalKM)) kilometres, \(stat.totalRides) rides, trend: \(trendTextLabel)"
    }
}

// MARK: - Activities List

struct TVActivitiesListView: View {
    let activities: [Activity]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 30) {
                ForEach(activities) { activity in
                    TVActivityRow(activity: activity)
                        .padding(.horizontal, 80)
                }
            }
            .focusSection()
            .padding(.vertical, 60)
        }
    }
}

// MARK: - Activity Row

struct TVActivityRow: View {
    let activity: Activity

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 40) {
            // Member info
            VStack(alignment: .leading, spacing: 8) {
                Text(activity.memberName)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(Color.primary)

                // ≥31pt body minimum
                Text(activity.activityName)
                    .font(.system(size: 31))
                    .foregroundStyle(Color.primary.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Stats
            VStack(alignment: .trailing, spacing: 8) {
                Text(String(format: "%.1f km", activity.distance))
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(Color.dccSaffron)

                HStack(spacing: 20) {
                    Label(String(format: "%.1f km/h", activity.averageSpeed), systemImage: "speedometer")
                    Label(String(format: "%.0f m", activity.elevationGain), systemImage: "mountain.2")
                }
                .font(.system(size: 31))   // ≥31pt
                .foregroundStyle(Color.primary.opacity(0.7))
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            isFocused ? Color.dccGreen.opacity(0.8) : Color.clear,
                            lineWidth: 3
                        )
                )
        )
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .shadow(
            color: isFocused ? Color.dccGreen.opacity(0.4) : .clear,
            radius: isFocused ? 24 : 0
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .focusable()
        .focused($isFocused)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(activity.memberName), \(activity.activityName), \(String(format: "%.1f", activity.distance)) kilometres at \(String(format: "%.1f", activity.averageSpeed)) km/h")
    }
}

#endif

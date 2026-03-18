//
//  IPadGlassComponents.swift
//  DCC-Weekly-Activities
//
//  Reusable Liquid Glass components sized for iPad.
//  Polished with entrance animations, proper typography, and visual hierarchy.
//

import SwiftUI

// MARK: - iPad Glass Stat Card

struct IPadGlassStatCard: View {
    let value: String
    let unit: String
    let label: String
    let icon: String
    let color: Color

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Text(unit)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
            }

            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .glassEffect(
            .regular.tint(color.opacity(0.10)),
            in: .rect(cornerRadius: IPadLayout.cardCornerRadius)
        )
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.94)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                appeared = true
            }
        }
    }
}

// MARK: - iPad Glass Hero Card

/// Full-width hero card showing club total distance.
struct IPadGlassHeroCard: View {
    let totalDistance: Double
    let riderCount: Int
    let totalRides: Int

    @State private var appeared = false
    @State private var countedDistance: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header row
            HStack {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "figure.outdoor.cycle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.accent)
                    Text("Club Total This Week")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                        .tracking(0.3)
                }
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "person.3.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.dccSaffron)
                    Text("\(riderCount) riders")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .glassEffect(.regular.tint(Color.dccSaffron.opacity(0.12)), in: .capsule)
            }

            // Hero distance
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text(String(format: "%.1f", countedDistance))
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accent, Color.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .contentTransition(.numericText(value: countedDistance))
                Text("km")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.textSecondary)
                    .padding(.bottom, 8)
                Spacer()
                // Rides badge
                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(totalRides)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.dccGreen)
                    Text("total rides")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                }
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.lg + 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(
            .regular.tint(Color.accent.opacity(0.08)),
            in: .rect(cornerRadius: IPadLayout.panelCornerRadius)
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
            withAnimation(.easeOut(duration: 1.2).delay(0.2)) {
                countedDistance = totalDistance
            }
        }
    }
}

// MARK: - iPad Rider Row (Leaderboard sidebar)

struct IPadRiderRow: View {
    let rank: Int
    let rider: MemberStats

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(Color.rankColor(for: rank).opacity(0.18))
                    .frame(width: 38, height: 38)
                Text("\(rank)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.rankColor(for: rank))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(rider.memberName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text("\(rider.totalRides) ride\(rider.totalRides == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    if rider.currentWeekTrend != .stable {
                        Text(rider.trendEmoji)
                            .font(.caption)
                            .foregroundStyle(
                                rider.currentWeekTrend == .up ? Color.dccGreen :
                                rider.currentWeekTrend == .new ? Color.dccSaffron : Color.error
                            )
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(String(format: "%.1f", rider.totalKM))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dccSaffron)
                Text("km")
                    .font(.caption2)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

// MARK: - iPad Best Ride Card

struct IPadBestRideCard: View {
    let activity: Activity

    @State private var appeared = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Rider name + date
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.dccSaffron.opacity(0.18))
                            .frame(width: 40, height: 40)
                        Image(systemName: "bicycle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.dccSaffron)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(activity.memberName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                        Text(activity.activityName)
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Text(Self.dateFormatter.string(from: activity.date))
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .glassEffect(.regular.tint(.white.opacity(0.05)), in: .capsule)
            }

            Divider()
                .background(Color.dccSaffron.opacity(0.25))

            // Stats row
            HStack(spacing: 0) {
                bestRideStat(
                    value: String(format: "%.1f", activity.distance),
                    unit: "km",
                    label: "Distance",
                    icon: "arrow.forward.circle.fill",
                    color: .dccSaffron
                )
                Divider()
                    .frame(height: 44)
                    .background(Color.white.opacity(0.08))
                    .padding(.horizontal, Spacing.md)
                bestRideStat(
                    value: String(format: "%.1f", activity.averageSpeed),
                    unit: "km/h",
                    label: "Avg Speed",
                    icon: "speedometer",
                    color: .dccGreen
                )
                Divider()
                    .frame(height: 44)
                    .background(Color.white.opacity(0.08))
                    .padding(.horizontal, Spacing.md)
                bestRideStat(
                    value: String(format: "%.0f", activity.elevationGain),
                    unit: "m",
                    label: "Elevation",
                    icon: "mountain.2.fill",
                    color: .dccBlue
                )
                if activity.movingTime > 0 {
                    Divider()
                        .frame(height: 44)
                        .background(Color.white.opacity(0.08))
                        .padding(.horizontal, Spacing.md)
                    bestRideStat(
                        value: formattedTime(activity.movingTime),
                        unit: "",
                        label: "Moving Time",
                        icon: "clock.fill",
                        color: .accent
                    )
                }
                Spacer()
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(
            .regular.tint(Color.dccSaffron.opacity(0.07)),
            in: .rect(cornerRadius: IPadLayout.cardCornerRadius)
        )
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.97)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }

    private func bestRideStat(value: String, unit: String, label: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(color.opacity(0.8))
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                }
            }
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
    }

    private func formattedTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

// MARK: - iPad Section Header

struct IPadSectionHeader: View {
    let title: String
    let icon: String
    var color: Color = .textPrimary

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 7))
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.textPrimary)
            Spacer()
        }
    }
}

// MARK: - iPad Podium Card (top 3 on leaderboard)

struct IPadPodiumCard: View {
    let rank: Int
    let rider: MemberStats

    @State private var appeared = false

    private var rankColor: Color {
        switch rank {
        case 1: return Color(hex: "#FFD700")
        case 2: return Color(hex: "#C0C0C0")
        case 3: return Color(hex: "#CD7F32")
        default: return Color.textSecondary
        }
    }

    private var rankLabel: String {
        switch rank {
        case 1: return "Champion"
        case 2: return "Runner-up"
        case 3: return "Third Place"
        default: return "Rider"
        }
    }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Crown / medal
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.18))
                    .frame(width: 56, height: 56)
                Text(rank == 1 ? "👑" : rank == 2 ? "🥈" : "🥉")
                    .font(.system(size: 28))
            }

            Text(rider.memberName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(rankLabel)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(rankColor)
                .tracking(0.8)
                .textCase(.uppercase)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(String(format: "%.1f", rider.totalKM))
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(rankColor)
                Text("km")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
            }

            Text("\(rider.totalRides) ride\(rider.totalRides == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .padding(.horizontal, Spacing.md)
        .glassEffect(
            .regular.tint(rankColor.opacity(0.10)),
            in: .rect(cornerRadius: IPadLayout.cardCornerRadius)
        )
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.9)
        .onAppear {
            let delay = Double(rank - 1) * 0.12
            withAnimation(.spring(response: 0.55, dampingFraction: 0.75).delay(delay)) {
                appeared = true
            }
        }
    }
}

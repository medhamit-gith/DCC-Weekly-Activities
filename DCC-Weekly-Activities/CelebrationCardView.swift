//
//  CelebrationCardView.swift
//  DCC-Weekly-Activities
//
//  Animated hero moment card
//

import SwiftUI

struct CelebrationCardView: View {
    let rider: MemberStats
    let rank: Int
    let topAchievement: String
    let motivationalMessage: String
    var onViewFullAnalysis: (() -> Void)? = nil
    
    @State private var isVisible = false
    @State private var counters = AnimatedCounters()
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Headline
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Great week \(rider.memberName)! 🔥")
                        .font(.sectionTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.textPrimary)
                    
                    Text(topAchievement)
                        .font(.cardTitle)
                        .foregroundStyle(Color.accent)
                }
                
                Spacer()
                
                // Rank badge
                ZStack {
                    Circle()
                        .fill(rankGradient)
                        .frame(width: 56, height: 56)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    
                    Text("\(rank)")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            
            Divider()
                .background(Color.textSecondary.opacity(0.2))
            
            // Key stats with animated counters
            HStack(spacing: Spacing.lg) {
                StatCounter(
                    value: counters.distance,
                    target: rider.totalKM,
                    unit: "km",
                    label: "Distance"
                )
                
                StatCounter(
                    value: counters.rides,
                    target: Double(rider.totalRides),
                    unit: "rides",
                    label: "Rides"
                )
                
                StatCounter(
                    value: counters.elevation,
                    target: rider.totalElevation,
                    unit: "m",
                    label: "Climbing"
                )
            }
            
            Divider()
                .background(Color.textSecondary.opacity(0.2))
            
            // Motivational message
            Text(motivationalMessage)
                .font(.bodyDefault)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.leading)
            
            // View Full Analysis button (optional - for Insights screen)
            if let action = onViewFullAnalysis {
                Button(action: action) {
                    HStack {
                        Text("View Full Analysis")
                            .font(.bodyDefault)
                            .fontWeight(.semibold)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(Color.accent.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.accent.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.lg)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .fill(Color.surfaceElevated)
                
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .fill(
                        LinearGradient(
                            colors: [Color.accent.opacity(0.15), Color.accent.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(
                    LinearGradient(
                        colors: [Color.accent.opacity(0.4), Color.accent.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: Color.accent.opacity(0.3), radius: 20, x: 0, y: 10)
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .offset(y: isVisible ? 0 : 100)
        .opacity(isVisible ? 1.0 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
            }
            
            // Animate counters
            withAnimation(.easeOut(duration: 0.8)) {
                counters.distance = rider.totalKM
                counters.rides = Double(rider.totalRides)
                counters.elevation = rider.totalElevation
            }
        }
    }
    
    private var rankGradient: LinearGradient {
        switch rank {
        case 1:
            return LinearGradient(
                colors: [Color(hex: "#FFD700"), Color(hex: "#FFA500")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 2:
            return LinearGradient(
                colors: [Color(hex: "#C0C0C0"), Color(hex: "#808080")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 3:
            return LinearGradient(
                colors: [Color(hex: "#CD7F32"), Color(hex: "#8B4513")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [Color.accent, Color.accentSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private struct StatCounter: View {
    let value: Double
    let target: Double
    let unit: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: target >= 100 ? "%.0f" : "%.1f", value))
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                    .monospacedDigit()
                
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(Color.textSecondary)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.textSecondary)
        }
    }
}

@Observable
private class AnimatedCounters {
    var distance: Double = 0
    var rides: Double = 0
    var elevation: Double = 0
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        CelebrationCardView(
            rider: MemberStats(
                memberName: "Alice",
                activities: []
            ),
            rank: 1,
            topAchievement: "Most Distance: 150.5km",
            motivationalMessage: "You're leading the pack. Defend your crown! 👑"
        )
        .padding()
    }
}

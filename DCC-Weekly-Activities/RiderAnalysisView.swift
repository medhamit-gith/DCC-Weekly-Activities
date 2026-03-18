//
//  RiderAnalysisView.swift
//  DCC-Weekly-Activities
//
//  Full-screen dedicated rider performance analysis with animated transitions
//

import SwiftUI

struct RiderAnalysisView: View {
    let rider: MemberStats
    let allStats: [MemberStats]
    let activities: [Activity]
    
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = InsightsViewModel()
    
    // MARK: - Entrance Animation State
    @State private var showHeader = false
    @State private var showCharts = false
    @State private var showTips = false
    @State private var backHaptic = false
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            
            // Section 1 — Celebration card
            CelebrationCardView(
                rider: rider,
                rank: viewModel.rank(for: rider),
                topAchievement: viewModel.topAchievement(for: rider),
                motivationalMessage: viewModel.motivationalMessage(for: viewModel.rank(for: rider))
            )
            .opacity(showHeader ? 1 : 0)
            .offset(y: showHeader ? 0 : 30)
            .padding(.horizontal, Spacing.md)
            .id("celebration-\(rider.id)")
            
            // Section 2 — Charts
            VStack(spacing: Spacing.lg) {
                DistanceBarChart(
                    stats: allStats,
                    selectedRider: rider,
                    viewModel: viewModel
                )
                
                SpeedElevationScatter(
                    stats: allStats,
                    selectedRider: rider
                )
                
                RadarChartView(
                    rider: rider,
                    viewModel: viewModel
                )
                .id(rider.id)
            }
            .opacity(showCharts ? 1 : 0)
            .offset(y: showCharts ? 0 : 40)
            .padding(.horizontal, Spacing.md)
            
            // Section 3 — Coaching tips
            CoachingTipsSection(
                tips: viewModel.generateCoachingTips(for: rider)
            )
            .opacity(showTips ? 1 : 0)
            .offset(y: showTips ? 0 : 30)
            .padding(.horizontal, Spacing.md)
        }
        .padding(.vertical, Spacing.md)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                backButton
            }
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(rider.memberName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.textPrimary)
                        .opacity(showHeader ? 1 : 0)
                    
                    Text("Performance Analysis")
                        .font(.caption2)
                        .foregroundStyle(Color.textSecondary)
                        .opacity(showHeader ? 1 : 0)
                }
            }
        }
        .onAppear {
            // Initialize view model with data
            viewModel.stats = allStats
            viewModel.selectedRiderName = rider.memberName
            
            // Trigger entrance animations
            triggerEntranceAnimations()
        }
    }
    
    // MARK: - Custom Back Button
    
    private var backButton: some View {
        Button(action: {
            backHaptic.toggle()
            dismiss()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                Text("Back")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(Color.accent)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                Capsule()
                    .fill(Color.accent.opacity(0.12))
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.accent.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: backHaptic)
    }
    
    // MARK: - Trigger Staggered Entrance Animations
    
    private func triggerEntranceAnimations() {
        // Reset state first (important for back-then-re-enter)
        showHeader = false
        showCharts = false
        showTips = false
        
        // Staggered reveal with spring animations
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) {
            showHeader = true  // Celebration card appears first
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.35)) {
            showCharts = true  // Charts reveal second
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.55)) {
            showTips = true    // Coaching tips appear last
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RiderAnalysisView(
            rider: MemberStats(
                memberName: "Alice",
                activities: [
                    Activity(
                        memberName: "Alice",
                        activityName: "Morning Ride",
                        distance: 50.0,
                        date: Date(),
                        averageSpeed: 25.5,
                        elevationGain: 450,
                        movingTime: 7200
                    )
                ]
            ),
            allStats: [
                MemberStats(
                    memberName: "Alice",
                    activities: [
                        Activity(
                            memberName: "Alice",
                            activityName: "Morning Ride",
                            distance: 50.0,
                            date: Date(),
                            averageSpeed: 25.5,
                            elevationGain: 450,
                            movingTime: 7200
                        )
                    ]
                ),
                MemberStats(
                    memberName: "Bob",
                    activities: [
                        Activity(
                            memberName: "Bob",
                            activityName: "Evening Ride",
                            distance: 45.0,
                            date: Date(),
                            averageSpeed: 23.0,
                            elevationGain: 380,
                            movingTime: 6800
                        )
                    ]
                )
            ],
            activities: []
        )
    }
}

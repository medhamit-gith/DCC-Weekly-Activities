//
//  InsightsView.swift
//  DCC-Weekly-Activities
//
//  Main Insights screen - Rider performance analysis
//

import SwiftUI

struct InsightsView: View {
    let stats: [MemberStats]
    let activities: [Activity]
    
    @State private var viewModel = InsightsViewModel()
    @State private var showConfetti = false
    @State private var confettiTrigger = false
    @State private var selectedRiderForNavigation: MemberStats? = nil
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            if stats.isEmpty {
                EmptyStateView(
                    icon: "chart.xyaxis.line",
                    title: "No Data Yet",
                    message: "Insights will appear once riders log activities"
                )
            } else if stats.count == 1 {
                EmptyStateView(
                    icon: "person.2.fill",
                    title: "Need More Riders",
                    message: "Comparisons will appear when 2+ riders have logged activities"
                )
            } else {
                mainContent
            }
        }
        .navigationDestination(for: MemberStats.self) { rider in
            RiderAnalysisView(
                rider: rider,
                allStats: stats,
                activities: activities
            )
        }
        .navigationDestination(isPresented: .init(
            get: { selectedRiderForNavigation != nil },
            set: { if !$0 { selectedRiderForNavigation = nil } }
        )) {
            if let rider = selectedRiderForNavigation {
                RiderAnalysisView(
                    rider: rider,
                    allStats: stats,
                    activities: activities
                )
            }
        }
        .onAppear {
            viewModel.stats = stats
            if viewModel.selectedRiderName == nil, let first = viewModel.sortedStats.first {
                viewModel.selectedRiderName = first.memberName
            }
        }
        .onChange(of: stats) { _, newStats in
            viewModel.stats = newStats
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Rider Selector
                RiderChipSelector(
                    stats: stats,
                    selectedRiderName: $viewModel.selectedRiderName,
                    viewModel: viewModel
                )
                
                if let selectedRider = viewModel.selectedRider {
                    VStack(spacing: Spacing.lg) {
                        // Confetti effect (centered on screen)
                        ZStack {
                            ConfettiBurstView(trigger: confettiTrigger)
                                .frame(maxWidth: .infinity)
                                .frame(height: 1)
                                .allowsHitTesting(false) // CRITICAL - prevents blocking taps
                        }
                        
                        // Celebration Card (includes "View Full Analysis" button)
                        CelebrationCardView(
                            rider: selectedRider,
                            rank: viewModel.rank(for: selectedRider),
                            topAchievement: viewModel.topAchievement(for: selectedRider),
                            motivationalMessage: viewModel.motivationalMessage(for: viewModel.rank(for: selectedRider)),
                            onViewFullAnalysis: {
                                selectedRiderForNavigation = selectedRider
                            }
                        )
                        .padding(.horizontal, Spacing.md)
                        .id("celebration-\(selectedRider.id)")
                    }
                }
            }
            .padding(.vertical, Spacing.md)
        }
        .onChange(of: viewModel.selectedRiderName) { _, newValue in
            if newValue != nil {
                // Trigger confetti burst on rider selection
                confettiTrigger.toggle()
            }
        }
    }
}

#Preview {
    InsightsView(
        stats: [
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
                        distance: 35.0,
                        date: Date(),
                        averageSpeed: 22.0,
                        elevationGain: 320,
                        movingTime: 5400
                    )
                ]
            ),
            MemberStats(
                memberName: "Charlie",
                activities: [
                    Activity(
                        memberName: "Charlie",
                        activityName: "Hill Climb",
                        distance: 42.0,
                        date: Date(),
                        averageSpeed: 18.5,
                        elevationGain: 680,
                        movingTime: 8100
                    )
                ]
            )
        ],
        activities: []
    )
}

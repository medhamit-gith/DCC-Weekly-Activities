//
//  MetricModeSelectionView.swift
//  DCC-Weekly-Activities
//
//  Mode selection sheet triggered by tapping a metric card
//

import SwiftUI

struct MetricModeSelectionView: View {
    let metric: MemberStatsChartView.MetricType
    let athleteProfile: AthleteProfile
    let stats: [MemberStats]
    let activities: [Activity]
    let dateRange: (start: Date, end: Date)?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.dccBlue.opacity(0.15), Color.dccSaffron.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header with metric name
                        headerSection
                        
                        // Mode selection cards
                        VStack(spacing: 20) {
                            ForEach([DashboardMode.justMyStats, .meVsTop3, .worstPerformer]) { mode in
                                NavigationLink {
                                    modeDestinationView(mode: mode)
                                } label: {
                                    ModeSelectionCard(mode: mode)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(metric.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Date range at the top
            DateRangeHeaderView(dateRange: dateInterval, showWeekLabel: false)
                .padding(.top, 8)
            
            Divider()
                .padding(.horizontal, 40)
            
            // Metric icon and value
            VStack(spacing: 12) {
                Image(systemName: metric.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [metric.color, metric.color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(metric.getValue(from: stats))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(metric.color)
                
                Text(metric.rawValue)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
                .padding(.horizontal, 40)
            
            // Greeting
            VStack(spacing: 8) {
                Text("Hi, \(athleteProfile.firstname)! 👋")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("How would you like to explore this metric?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var dateInterval: DateInterval? {
        guard let range = dateRange else { return nil }
        return DateInterval(start: range.start, end: range.end)
    }
    
    // MARK: - Mode Destination View
    
    @ViewBuilder
    private func modeDestinationView(mode: DashboardMode) -> some View {
        switch mode {
        case .justMyStats:
            JustMyStatsView(
                athleteProfile: athleteProfile,
                stats: stats,
                activities: activities,
                dateRange: dateRange
            )
            .navigationTitle(mode.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            
        case .meVsTop3:
            MeVsTop3View(
                athleteProfile: athleteProfile,
                stats: stats,
                dateRange: dateRange
            )
            .navigationTitle(mode.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            
        case .worstPerformer:
            WorstPerformerView(
                stats: stats,
                activities: activities,
                dateRange: dateRange
            )
            .navigationTitle(mode.rawValue)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Mode Selection Card

struct ModeSelectionCard: View {
    let mode: DashboardMode
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: mode.icon)
                .font(.system(size: 32))
                .foregroundStyle(mode.color)
                .frame(width: 60, height: 60)
                .background(mode.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Text content
            VStack(alignment: .leading, spacing: 6) {
                Text(mode.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(mode.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .imageScale(.small)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview

#Preview {
    let sampleActivities = [
        Activity(
            memberName: "John Doe",
            activityName: "Morning Ride",
            distance: 45.5,
            date: Date(),
            averageSpeed: 28.5,
            elevationGain: 450,
            movingTime: 5400,
            type: "Ride"
        ),
        Activity(
            memberName: "Jane Smith",
            activityName: "Evening Ride",
            distance: 32.0,
            date: Date().addingTimeInterval(-86400),
            averageSpeed: 25.0,
            elevationGain: 320,
            movingTime: 4600,
            type: "Ride"
        )
    ]
    
    let stats = [
        MemberStats(memberName: "John Doe", activities: [sampleActivities[0]]),
        MemberStats(memberName: "Jane Smith", activities: [sampleActivities[1]])
    ]
    
    let profile = AthleteProfile(
        id: 12345,
        firstname: "John",
        lastname: "Doe",
        profile: nil,
        city: "Delhi",
        state: nil,
        country: "India"
    )
    
    let dateRange = (
        start: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
        end: Date()
    )
    
    return MetricModeSelectionView(
        metric: .totalDistance,
        athleteProfile: profile,
        stats: stats,
        activities: sampleActivities,
        dateRange: dateRange
    )
}

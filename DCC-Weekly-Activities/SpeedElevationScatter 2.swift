//
//  SpeedElevationScatter.swift (DUPLICATE - DELETE THIS FILE)
//  DCC-Weekly-Activities
//
//  ⚠️ WARNING: This is a duplicate file. Use SpeedElevationScatter.swift instead.
//  This file should be deleted from the Xcode project.
//
//  Speed vs Elevation scatter plot using Swift Charts
//

import SwiftUI
import Charts

// DEPRECATED: Use the version in SpeedElevationScatter.swift
struct SpeedElevationScatterDUPLICATE: View {
    let stats: [MemberStats]
    let selectedRider: MemberStats?
    
    @State private var animateChart = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Speed vs Elevation", systemImage: "chart.scatter")
                .font(.cardTitle)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)
            
            Chart {
                ForEach(stats, id: \.id) { rider in
                    let isSelected = rider.id == selectedRider?.id
                    
                    // Guard against NaN and invalid values
                    let safeSpeed = rider.avgSpeed.isFinite ? rider.avgSpeed : 0.0
                    let safeElevation = rider.totalElevation.isFinite ? rider.totalElevation : 0.0
                    
                    PointMark(
                        x: .value("Avg Speed (km/h)", animateChart ? safeSpeed : 0),
                        y: .value("Total Elevation (m)", animateChart ? safeElevation : 0)
                    )
                    .foregroundStyle(isSelected ? Color.accent : Color.textSecondary.opacity(0.6))
                    .symbolSize(isSelected ? 120 : 80)
                    .annotation(position: .top, alignment: .center) {
                        if isSelected {
                            Text(rider.memberName)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.accent)
                                .opacity(animateChart ? 1 : 0)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(position: .bottom) { value in
                    AxisGridLine()
                    AxisValueLabel()
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel()
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .frame(height: 280)
        }
        .padding(Spacing.md)
        .background(Color.surface)
        .cornerRadius(CornerRadius.lg)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateChart = true
                }
            }
        }
        .onChange(of: selectedRider?.id) { _, _ in
            animateChart = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: 0.6)) {
                    animateChart = true
                }
            }
        }
    }
}

// DEPRECATED Preview - remove this file
#Preview("DEPRECATED - Delete This File") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        ScrollView {
            SpeedElevationScatter(
                stats: [
                    MemberStats(
                        memberName: "Alice",
                        activities: [
                            Activity(
                                memberName: "Alice",
                                activityName: "Test",
                                distance: 50,
                                date: Date(),
                                averageSpeed: 25,
                                elevationGain: 500,
                                movingTime: 7200
                            )
                        ]
                    ),
                    MemberStats(
                        memberName: "Bob",
                        activities: [
                            Activity(
                                memberName: "Bob",
                                activityName: "Test",
                                distance: 40,
                                date: Date(),
                                averageSpeed: 22,
                                elevationGain: 400,
                                movingTime: 6000
                            )
                        ]
                    )
                ],
                selectedRider: MemberStats(memberName: "Alice", activities: [])
            )
            .padding()
        }
    }
}

//
//  SpeedElevationScatter.swift
//  DCC-Weekly-Activities
//
//  Scatter plot comparing speed vs elevation
//

import SwiftUI
import Charts

struct SpeedElevationScatter: View {
    let stats: [MemberStats]
    let selectedRider: MemberStats?
    
    @State private var animateChart = false
    @State private var highlightedRider: MemberStats?
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Chart header with help button
            HStack {
                Label("Speed vs Climbing Profile", systemImage: "chart.xyaxis.line")
                    .font(.cardTitle)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                ChartHelpButton(content: .speedElevation)
            }
            
            Chart {
                ForEach(stats, id: \.id) { rider in
                    let isSelected = rider.id == selectedRider?.id
                    let isHighlighted = rider.id == highlightedRider?.id
                    let size = isSelected ? 120 : (isHighlighted ? 80 : 40)
                    
                    PointMark(
                        x: .value("Avg Speed", rider.avgSpeed),
                        y: .value("Elevation", rider.totalElevation)
                    )
                    .symbolSize(animateChart ? CGFloat(size) : 0)
                    .foregroundStyle(isSelected ? Color.accent : Color.surface.opacity(0.7))
                    
                    if isSelected {
                        PointMark(
                            x: .value("Avg Speed", rider.avgSpeed),
                            y: .value("Elevation", rider.totalElevation)
                        )
                        .annotation(position: .top, alignment: .center) {
                            Text(rider.memberName)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.accent)
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.accent.opacity(0.2))
                                )
                                .opacity(animateChart ? 1 : 0)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(position: .bottom) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let speed = value.as(Double.self) {
                            Text("\(Int(speed)) km/h")
                                .font(.caption2)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let elevation = value.as(Double.self) {
                            Text("\(Int(elevation))m")
                                .font(.caption2)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }
            }
            .frame(height: 300)
            
            // Quadrant labels
            HStack {
                QuadrantLabel(text: "Steady Climber", color: .dccBlue)
                Spacer()
                QuadrantLabel(text: "Fast & Climbing", color: .dccGreen)
            }
            
            HStack {
                QuadrantLabel(text: "Endurance Base", color: .textSecondary)
                Spacer()
                QuadrantLabel(text: "Fast & Flat", color: .dccSaffron)
            }
        }
        .padding(Spacing.md)
        .background(Color.surface)
        .cornerRadius(CornerRadius.lg)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    animateChart = true
                }
            }
        }
        .onChange(of: selectedRider?.id) { _, _ in
            animateChart = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    animateChart = true
                }
            }
        }
    }
}

private struct QuadrantLabel: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(color)
    }
}

#Preview("Speed vs Elevation - With Quadrants") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        ScrollView {
            SpeedElevationScatter(
                stats: [
                    MemberStats(memberName: "Alice", activities: []),
                    MemberStats(memberName: "Bob", activities: []),
                    MemberStats(memberName: "Charlie", activities: [])
                ],
                selectedRider: MemberStats(memberName: "Alice", activities: [])
            )
            .padding()
        }
    }
}

//
//  DistanceBarChart.swift
//  DCC-Weekly-Activities
//
//  Horizontal comparative bar chart using Swift Charts
//

import SwiftUI
import Charts

struct DistanceBarChart: View {
    let stats: [MemberStats]
    let selectedRider: MemberStats?
    let viewModel: InsightsViewModel
    
    @State private var animateChart = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Chart header with help button
            HStack {
                Label("Weekly Distance", systemImage: "figure.outdoor.cycle")
                    .font(.cardTitle)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                ChartHelpButton(content: .distanceBar)
            }
            
            Chart {
                ForEach(viewModel.sortedStats, id: \.id) { rider in
                    let isSelected = rider.id == selectedRider?.id
                    
                    // Guard against NaN values
                    let safeDistance = rider.totalKM.safeValue
                    
                    BarMark(
                        x: .value("Distance", animateChart ? safeDistance : 0),
                        y: .value("Rider", rider.memberName)
                    )
                    .foregroundStyle(isSelected ? Color.accent : Color.surface)
                    .annotation(position: .trailing, alignment: .leading) {
                        Text(String(format: "%.1f km", safeDistance))
                            .font(.caption)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .foregroundStyle(isSelected ? Color.accent : Color.textSecondary)
                            .opacity(animateChart ? 1 : 0)
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
                AxisMarks { value in
                    if let name = value.as(String.self),
                       let rider = stats.first(where: { $0.memberName == name }) {
                        let isSelected = rider.id == selectedRider?.id
                        AxisValueLabel {
                            Text(name)
                                .font(.bodyDefault)
                                .fontWeight(isSelected ? .bold : .regular)
                                .foregroundStyle(isSelected ? Color.textPrimary : Color.textSecondary)
                        }
                    }
                }
            }
            .frame(height: CGFloat(max(200, stats.count * 40)))
        }
        .padding(Spacing.md)
        .background(Color.surface)
        .cornerRadius(CornerRadius.lg)
        .onAppear {
            // Stagger animation with delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateChart = true
                }
            }
        }
        .onChange(of: selectedRider?.id) { _, _ in
            // Reset and re-animate on selection change
            animateChart = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: 0.6)) {
                    animateChart = true
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        ScrollView {
            DistanceBarChart(
                stats: [
                    MemberStats(memberName: "Alice", activities: []),
                    MemberStats(memberName: "Bob", activities: []),
                    MemberStats(memberName: "Charlie", activities: [])
                ],
                selectedRider: MemberStats(memberName: "Alice", activities: []),
                viewModel: InsightsViewModel()
            )
            .padding()
        }
    }
}

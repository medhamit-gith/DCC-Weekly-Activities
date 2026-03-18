//
//  RadarChartView.swift
//  DCC-Weekly-Activities
//
//  Custom Canvas-based radar/spider chart
//

import SwiftUI

struct RadarChartView: View {
    let rider: MemberStats
    let viewModel: InsightsViewModel
    
    @State private var progress: Double = 0.0
    
    private let axes = ["Distance", "Speed", "Elevation", "Rides", "Consistency"]
    
    // Computed properties for values (fixes type-checking timeout)
    private var riderValues: [Double] {
        [
            viewModel.normalizedDistance(for: rider).safeValue,
            viewModel.normalizedSpeed(for: rider).safeValue,
            viewModel.normalizedElevation(for: rider).safeValue,
            viewModel.normalizedRides(for: rider).safeValue,
            viewModel.normalizedConsistency(for: rider).safeValue
        ]
    }
    
    private var averageValues: [Double] {
        let maxDistance = viewModel.stats.map(\.totalKM).max() ?? 1
        let maxSpeed = viewModel.stats.map(\.avgSpeed).max() ?? 1
        let maxElevation = viewModel.stats.map(\.totalElevation).max() ?? 1
        let maxRides = Double(viewModel.stats.map(\.totalRides).max() ?? 1)
        let maxConsistency = viewModel.stats.map { stat in
            stat.totalRides > 0 ? stat.totalKM / Double(stat.totalRides) : 0.0
        }.max() ?? 1
        
        return [
            (maxDistance > 0 ? viewModel.clubAverageDistance / maxDistance : 0).safeValue,
            (maxSpeed > 0 ? viewModel.clubAverageSpeed / maxSpeed : 0).safeValue,
            (maxElevation > 0 ? viewModel.clubAverageElevation / maxElevation : 0).safeValue,
            (maxRides > 0 ? viewModel.clubAverageRides / maxRides : 0).safeValue,
            (maxConsistency > 0 ? viewModel.clubAverageConsistency / maxConsistency : 0).safeValue
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            headerView
            chartCanvas
        }
        .padding(Spacing.md)
        .background(Color.surface)
        .cornerRadius(CornerRadius.lg)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                progress = 1.0
            }
        }
        .onChange(of: rider.id) { _, _ in
            progress = 0
            withAnimation(.easeInOut(duration: 0.8).delay(0.1)) {
                progress = 1.0
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Label("Performance Profile", systemImage: "chart.bar.xaxis")
                .font(.cardTitle)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)
            
            Spacer()
            
            HStack(spacing: Spacing.sm) {
                ChartHelpButton(content: .radar)
                
                LegendItem(color: .accent, label: rider.memberName)
                LegendItem(color: .textSecondary, label: "Club Avg", isDashed: true)
            }
        }
    }
    
    // MARK: - Chart Canvas
    
    private var chartCanvas: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: size / 2)
            let radius = size * 0.35
            
            ZStack {
                canvasView(center: center, radius: radius)
                labelsOverlay(center: center, radius: radius)
            }
        }
        .frame(height: 320)
    }
    
    private func canvasView(center: CGPoint, radius: CGFloat) -> some View {
        Canvas { context, size in
            // Guard against empty or invalid data
            guard !riderValues.isEmpty,
                  !riderValues.contains(where: { !$0.isFinite }),
                  !averageValues.isEmpty,
                  !averageValues.contains(where: { !$0.isFinite }) else {
                return
            }
            
            drawGridLines(context: context, center: center, radius: radius)
            drawAveragePath(context: context, center: center, radius: radius)
            drawRiderPath(context: context, center: center, radius: radius)
        }
    }
    
    private func labelsOverlay(center: CGPoint, radius: CGFloat) -> some View {
        ForEach(0..<axes.count, id: \.self) { index in
            let labelPos = labelPosition(center: center, radius: radius, index: index)
            Text(axes[index])
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.textPrimary)
                .position(labelPos)
                .opacity(progress)
        }
    }
    
    // MARK: - Point Calculator (fixes ambiguous cos/sin)
    
    private func point(
        center: CGPoint,
        radius: CGFloat,
        index: Int,
        value: Double,
        count: Int
    ) -> CGPoint {
        let angleValue = (2.0 * Double.pi / Double(count)) * Double(index) - Double.pi / 2.0
        let safeValue = value.safeValue
        let radiusValue = radius * CGFloat(safeValue * progress)
        let xOffset = radiusValue * CGFloat(cos(angleValue))
        let yOffset = radiusValue * CGFloat(sin(angleValue))
        return CGPoint(
            x: center.x + xOffset.safeValue,
            y: center.y + yOffset.safeValue
        )
    }
    
    private func labelPosition(center: CGPoint, radius: CGFloat, index: Int) -> CGPoint {
        let angleValue = (2.0 * Double.pi / Double(axes.count)) * Double(index) - Double.pi / 2.0
        let labelRadius = radius * 1.25
        let xOffset = labelRadius * CGFloat(cos(angleValue))
        let yOffset = labelRadius * CGFloat(sin(angleValue))
        return CGPoint(
            x: center.x + xOffset,
            y: center.y + yOffset
        )
    }
    
    // MARK: - Draw Grid
    
    private func drawGridLines(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let count = axes.count
        
        // Draw concentric circles
        for level in stride(from: 0.2, through: 1.0, by: 0.2) {
            var path = Path()
            for i in 0..<count {
                let pt = point(center: center, radius: radius, index: i, value: level, count: count)
                if i == 0 {
                    path.move(to: pt)
                } else {
                    path.addLine(to: pt)
                }
            }
            path.closeSubpath()
            context.stroke(path, with: .color(Color.textSecondary.opacity(0.1)), lineWidth: 1)
        }
        
        // Draw axis spokes
        for i in 0..<count {
            var spoke = Path()
            spoke.move(to: center)
            let pt = point(center: center, radius: radius, index: i, value: 1.0, count: count)
            spoke.addLine(to: pt)
            context.stroke(spoke, with: .color(Color.textSecondary.opacity(0.3)), lineWidth: 1)
        }
    }
    
    // MARK: - Draw Club Average
    
    private func drawAveragePath(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let count = axes.count
        var path = Path()
        
        for i in 0..<count {
            let pt = point(center: center, radius: radius, index: i, value: averageValues[i], count: count)
            if i == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
        }
        path.closeSubpath()
        
        let strokeStyle = StrokeStyle(lineWidth: 2, dash: [5, 3])
        context.stroke(path, with: .color(Color.textSecondary), style: strokeStyle)
    }
    
    // MARK: - Draw Selected Rider
    
    private func drawRiderPath(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let count = axes.count
        var path = Path()
        
        for i in 0..<count {
            let pt = point(center: center, radius: radius, index: i, value: riderValues[i], count: count)
            if i == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
        }
        path.closeSubpath()
        
        context.fill(path, with: .color(Color.accent.opacity(0.35)))
        context.stroke(path, with: .color(Color.accent), lineWidth: 2)
    }
}

// MARK: - Legend Item

private struct LegendItem: View {
    let color: Color
    let label: String
    var isDashed: Bool = false
    
    var body: some View {
        HStack(spacing: 4) {
            if isDashed {
                Rectangle()
                    .fill(color)
                    .frame(width: 12, height: 2)
                    .overlay(
                        Rectangle()
                            .fill(Color.surface)
                            .frame(width: 2, height: 2)
                    )
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    // Create sample activities
    let sampleActivities = [
        Activity(
            memberName: "Alice",
            activityName: "Morning Ride",
            distance: 45.5,
            date: Date(),
            averageSpeed: 28.5,
            elevationGain: 450,
            movingTime: 3600
        ),
        Activity(
            memberName: "Alice",
            activityName: "Evening Ride",
            distance: 35.0,
            date: Date().addingTimeInterval(-86400),
            averageSpeed: 26.0,
            elevationGain: 320,
            movingTime: 3200
        )
    ]
    
    let sampleRider = MemberStats(memberName: "Alice", activities: sampleActivities)
    
    // Create view model with sample data
    let viewModel = InsightsViewModel()
    viewModel.stats = [
        sampleRider,
        MemberStats(memberName: "Bob", activities: [
            Activity(
                memberName: "Bob",
                activityName: "Weekend Ride",
                distance: 60.0,
                date: Date(),
                averageSpeed: 30.0,
                elevationGain: 600,
                movingTime: 4500
            )
        ]),
        MemberStats(memberName: "Charlie", activities: [
            Activity(
                memberName: "Charlie",
                activityName: "Training Ride",
                distance: 50.0,
                date: Date(),
                averageSpeed: 27.0,
                elevationGain: 500,
                movingTime: 4000
            )
        ])
    ]
    
    return ZStack {
        Color.appBackground.ignoresSafeArea()
        
        ScrollView {
            RadarChartView(
                rider: sampleRider,
                viewModel: viewModel
            )
            .padding()
        }
    }
}

#Preview {
    // Create sample activities
    let sampleActivities = [
        Activity(
            memberName: "Alice",
            activityName: "Morning Ride",
            distance: 45.5,
            date: Date(),
            averageSpeed: 28.5,
            elevationGain: 450,
            movingTime: 3600
        ),
        Activity(
            memberName: "Alice",
            activityName: "Evening Ride",
            distance: 35.0,
            date: Date().addingTimeInterval(-86400),
            averageSpeed: 26.0,
            elevationGain: 320,
            movingTime: 3200
        )
    ]
    
    let sampleRider = MemberStats(memberName: "Alice", activities: sampleActivities)
    
    // Create view model with sample data
    let viewModel = InsightsViewModel()
    viewModel.stats = [
        sampleRider,
        MemberStats(memberName: "Bob", activities: [
            Activity(
                memberName: "Bob",
                activityName: "Weekend Ride",
                distance: 60.0,
                date: Date(),
                averageSpeed: 30.0,
                elevationGain: 600,
                movingTime: 4500
            )
        ]),
        MemberStats(memberName: "Charlie", activities: [
            Activity(
                memberName: "Charlie",
                activityName: "Training Ride",
                distance: 50.0,
                date: Date(),
                averageSpeed: 27.0,
                elevationGain: 500,
                movingTime: 4000
            )
        ])
    ]
    
    return ZStack {
        Color.appBackground.ignoresSafeArea()
        
        ScrollView {
            RadarChartView(
                rider: sampleRider,
                viewModel: viewModel
            )
            .padding()
        }
    }
}

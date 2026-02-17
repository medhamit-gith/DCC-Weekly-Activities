//
//  MemberStatsChartView.swift
//  DCC-Weekly-Activities
//
//  Graphical view displaying member statistics using Swift Charts
//

import SwiftUI
import Charts

struct MemberStatsChartView: View {
    let stats: [MemberStats]
    @State private var selectedMetric: ChartMetric = .totalKM
    
    enum ChartMetric: String, CaseIterable {
        case totalKM = "Total KM"
        case totalRides = "Total Rides"
        case avgSpeed = "Avg Speed"
        case elevation = "Elevation"
        
        var icon: String {
            switch self {
            case .totalKM: return "road.lanes"
            case .totalRides: return "number"
            case .avgSpeed: return "speedometer"
            case .elevation: return "mountain.2.fill"
            }
        }
        
        var unit: String {
            switch self {
            case .totalKM: return "km"
            case .totalRides: return "rides"
            case .avgSpeed: return "km/h"
            case .elevation: return "m"
            }
        }
    }
    
    var topPerformers: [MemberStats] {
        // Show top 10 or all if less than 10
        let sorted = stats.sorted { stat1, stat2 in
            switch selectedMetric {
            case .totalKM:
                return stat1.totalKM > stat2.totalKM
            case .totalRides:
                return stat1.totalRides > stat2.totalRides
            case .avgSpeed:
                return stat1.avgSpeed > stat2.avgSpeed
            case .elevation:
                return stat1.totalElevation > stat2.totalElevation
            }
        }
        return Array(sorted.prefix(10))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Metric selector
                Picker("Metric", selection: $selectedMetric) {
                    ForEach(ChartMetric.allCases, id: \.self) { metric in
                        Label(metric.rawValue, systemImage: metric.icon)
                            .tag(metric)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Main bar chart
                VStack(alignment: .leading) {
                    Text("Top Performers")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Chart(topPerformers) { stat in
                        BarMark(
                            x: .value("Member", stat.memberName),
                            y: .value(selectedMetric.rawValue, getValue(for: stat))
                        )
                        .foregroundStyle(by: .value("Trend", stat.currentWeekTrend.rawValue))
                        .annotation(position: .top) {
                            Text(stat.trendEmoji)
                                .font(.caption2)
                        }
                    }
                    .chartForegroundStyleScale([
                        "↑": .green,
                        "↓": .red,
                        "→": .gray,
                        "★": .orange
                    ])
                    .frame(height: 300)
                    .padding(.horizontal)
                }
                
                Divider()
                
                // Summary statistics
                VStack(spacing: 16) {
                    Text("Week Summary")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(
                            title: "Total Distance",
                            value: String(format: "%.1f km", stats.reduce(0) { $0 + $1.totalKM }),
                            icon: "road.lanes",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Total Rides",
                            value: "\(stats.reduce(0) { $0 + $1.totalRides })",
                            icon: "bicycle",
                            color: .green
                        )
                        
                        StatCard(
                            title: "Total Elevation",
                            value: String(format: "%.0f m", stats.reduce(0) { $0 + $1.totalElevation }),
                            icon: "mountain.2.fill",
                            color: .orange
                        )
                        
                        StatCard(
                            title: "Active Members",
                            value: "\(stats.count)",
                            icon: "person.3.fill",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                
                // Distance distribution chart
                VStack(alignment: .leading) {
                    Text("Distance Distribution")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Chart(topPerformers) { stat in
                        SectorMark(
                            angle: .value("Distance", stat.totalKM)
                        )
                        .foregroundStyle(by: .value("Member", stat.memberName))
                    }
                    .frame(height: 300)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    private func getValue(for stat: MemberStats) -> Double {
        switch selectedMetric {
        case .totalKM:
            return stat.totalKM
        case .totalRides:
            return Double(stat.totalRides)
        case .avgSpeed:
            return stat.avgSpeed
        case .elevation:
            return stat.totalElevation
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

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
        ),
        Activity(
            memberName: "Bob Wilson",
            activityName: "Hill Climb",
            distance: 28.5,
            date: Date(),
            averageSpeed: 22.0,
            elevationGain: 800,
            movingTime: 4200,
            type: "Ride"
        )
    ]
    
    let stats = [
        MemberStats(memberName: "John Doe", activities: [sampleActivities[0]]),
        MemberStats(memberName: "Jane Smith", activities: [sampleActivities[1]]),
        MemberStats(memberName: "Bob Wilson", activities: [sampleActivities[2]]),
    ]
    
    return MemberStatsChartView(stats: stats)
}

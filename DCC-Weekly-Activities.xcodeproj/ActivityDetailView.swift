//
//  ActivityDetailView.swift
//  DCC-Weekly-Activities
//
//  Detailed view for individual activity with comparisons
//

import SwiftUI
import Charts

struct ActivityDetailView: View {
    let activity: Activity
    let allActivities: [Activity] // All activities from the week
    
    // Computed properties for comparisons
    private var memberActivities: [Activity] {
        allActivities.filter { $0.memberName == activity.memberName }
    }
    
    private var averageDistanceForMember: Double {
        guard !memberActivities.isEmpty else { return 0 }
        return memberActivities.reduce(0) { $0 + $1.distance } / Double(memberActivities.count)
    }
    
    private var averageSpeedForMember: Double {
        guard !memberActivities.isEmpty else { return 0 }
        return memberActivities.reduce(0) { $0 + $1.averageSpeed } / Double(memberActivities.count)
    }
    
    private var averageElevationForMember: Double {
        guard !memberActivities.isEmpty else { return 0 }
        return memberActivities.reduce(0) { $0 + $1.elevationGain } / Double(memberActivities.count)
    }
    
    private var clubAverageDistance: Double {
        guard !allActivities.isEmpty else { return 0 }
        return allActivities.reduce(0) { $0 + $1.distance } / Double(allActivities.count)
    }
    
    private var clubAverageSpeed: Double {
        guard !allActivities.isEmpty else { return 0 }
        return allActivities.reduce(0) { $0 + $1.averageSpeed } / Double(allActivities.count)
    }
    
    private var clubAverageElevation: Double {
        guard !allActivities.isEmpty else { return 0 }
        return allActivities.reduce(0) { $0 + $1.elevationGain } / Double(allActivities.count)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Activity Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: activityIcon)
                            .font(.title)
                            .foregroundStyle(.orange)
                        
                        VStack(alignment: .leading) {
                            Text(activity.activityName)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(activity.memberName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Text(activity.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Key Stats
                Text("Activity Stats")
                    .font(.headline)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatsBox(
                        title: "Distance",
                        value: String(format: "%.2f km", activity.distance),
                        icon: "road.lanes",
                        color: .blue
                    )
                    
                    StatsBox(
                        title: "Duration",
                        value: formatDuration(activity.movingTime),
                        icon: "clock.fill",
                        color: .green
                    )
                    
                    StatsBox(
                        title: "Avg Speed",
                        value: String(format: "%.1f km/h", activity.averageSpeed),
                        icon: "speedometer",
                        color: .orange
                    )
                    
                    StatsBox(
                        title: "Elevation",
                        value: String(format: "%.0f m", activity.elevationGain),
                        icon: "mountain.2.fill",
                        color: .purple
                    )
                }
                
                Divider()
                
                // Comparison to Personal Average
                Text("Compared to Your Average")
                    .font(.headline)
                
                ComparisonRow(
                    title: "Distance",
                    value: activity.distance,
                    average: averageDistanceForMember,
                    unit: "km",
                    icon: "road.lanes"
                )
                
                ComparisonRow(
                    title: "Speed",
                    value: activity.averageSpeed,
                    average: averageSpeedForMember,
                    unit: "km/h",
                    icon: "speedometer"
                )
                
                ComparisonRow(
                    title: "Elevation",
                    value: activity.elevationGain,
                    average: averageElevationForMember,
                    unit: "m",
                    icon: "mountain.2.fill"
                )
                
                Divider()
                
                // Comparison to Club Average
                Text("Compared to Club Average")
                    .font(.headline)
                
                ComparisonRow(
                    title: "Distance",
                    value: activity.distance,
                    average: clubAverageDistance,
                    unit: "km",
                    icon: "road.lanes",
                    color: .orange
                )
                
                ComparisonRow(
                    title: "Speed",
                    value: activity.averageSpeed,
                    average: clubAverageSpeed,
                    unit: "km/h",
                    icon: "speedometer",
                    color: .orange
                )
                
                ComparisonRow(
                    title: "Elevation",
                    value: activity.elevationGain,
                    average: clubAverageElevation,
                    unit: "m",
                    icon: "mountain.2.fill",
                    color: .orange
                )
                
                Divider()
                
                // Other rides by this member this week
                if memberActivities.count > 1 {
                    Text("Your Other Rides This Week")
                        .font(.headline)
                    
                    VStack(spacing: 8) {
                        ForEach(memberActivities.filter { $0.id != activity.id }) { ride in
                            OtherRideRow(activity: ride)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Activity Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var activityIcon: String {
        switch activity.type.lowercased() {
        case "ride", "cycling":
            return "bicycle"
        case "run", "running":
            return "figure.run"
        case "walk", "walking":
            return "figure.walk"
        default:
            return "figure.outdoor.cycle"
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Supporting Views

struct StatsBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct ComparisonRow: View {
    let title: String
    let value: Double
    let average: Double
    let unit: String
    let icon: String
    var color: Color = .blue
    
    private var difference: Double {
        value - average
    }
    
    private var percentDifference: Double {
        guard average != 0 else { return 0 }
        return ((value - average) / average) * 100
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Your avg: \(String(format: "%.1f", average)) \(unit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: difference >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundStyle(difference >= 0 ? .green : .red)
                    
                    Text(String(format: "%.1f%%", abs(percentDifference)))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(difference >= 0 ? .green : .red)
                }
                
                Text(String(format: "%+.1f %@", difference, unit))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct OtherRideRow: View {
    let activity: Activity
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.activityName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(activity.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f km", activity.distance))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(String(format: "%.1f km/h", activity.averageSpeed))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        ActivityDetailView(
            activity: Activity(
                memberName: "John Doe",
                activityName: "Morning Hill Climb",
                distance: 45.5,
                date: Date(),
                averageSpeed: 28.5,
                elevationGain: 650,
                movingTime: 5400,
                type: "Ride"
            ),
            allActivities: [
                Activity(
                    memberName: "John Doe",
                    activityName: "Morning Hill Climb",
                    distance: 45.5,
                    date: Date(),
                    averageSpeed: 28.5,
                    elevationGain: 650,
                    movingTime: 5400,
                    type: "Ride"
                ),
                Activity(
                    memberName: "John Doe",
                    activityName: "Evening Ride",
                    distance: 32.0,
                    date: Date().addingTimeInterval(-86400),
                    averageSpeed: 25.0,
                    elevationGain: 320,
                    movingTime: 4600,
                    type: "Ride"
                ),
                Activity(
                    memberName: "Jane Smith",
                    activityName: "Long Ride",
                    distance: 60.0,
                    date: Date(),
                    averageSpeed: 30.0,
                    elevationGain: 800,
                    movingTime: 7200,
                    type: "Ride"
                )
            ]
        )
    }
}

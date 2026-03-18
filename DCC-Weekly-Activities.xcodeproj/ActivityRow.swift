//
//  ActivityRow.swift
//  DCC-Weekly-Activities
//
//  Row view for displaying activities in a list
//

import SwiftUI

struct ActivityRow: View {
    let activity: Activity
    
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
    
    var body: some View {
        HStack(spacing: 12) {
            // Activity icon
            Image(systemName: activityIcon)
                .font(.title2)
                .foregroundStyle(.orange)
                .frame(width: 40)
            
            // Main info
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.memberName)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(activity.activityName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label(activity.date, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Label(formatDuration(activity.movingTime), systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "road.lanes")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text(String(format: "%.1f km", activity.distance))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                if activity.averageSpeed > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "speedometer")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Text(String(format: "%.1f km/h", activity.averageSpeed))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if activity.elevationGain > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "mountain.2.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text(String(format: "%.0f m", activity.elevationGain))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    List {
        ActivityRow(
            activity: Activity(
                memberName: "John Doe",
                activityName: "Morning Hill Climb",
                distance: 45.5,
                date: Date(),
                averageSpeed: 28.5,
                elevationGain: 650,
                movingTime: 5400,
                type: "Ride"
            )
        )
        
        ActivityRow(
            activity: Activity(
                memberName: "Jane Smith",
                activityName: "Evening Recovery Ride",
                distance: 32.0,
                date: Date().addingTimeInterval(-86400),
                averageSpeed: 25.0,
                elevationGain: 320,
                movingTime: 4600,
                type: "Ride"
            )
        )
        
        ActivityRow(
            activity: Activity(
                memberName: "Bob Wilson",
                activityName: "Long Weekend Ride",
                distance: 85.5,
                date: Date().addingTimeInterval(-172800),
                averageSpeed: 30.5,
                elevationGain: 1200,
                movingTime: 10200,
                type: "Ride"
            )
        )
    }
}

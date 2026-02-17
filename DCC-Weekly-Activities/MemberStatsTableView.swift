//
//  MemberStatsTableView.swift
//  DCC-Weekly-Activities
//
//  Table view displaying member statistics
//

import SwiftUI

struct MemberStatsTableView: View {
    let stats: [MemberStats]
    @State private var sortOrder: SortOrder = .totalKM
    @State private var isAscending = false
    
    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case totalKM = "Total KM"
        case totalRides = "Rides"
        case avgSpeed = "Avg Speed"
        case elevation = "Elevation"
        
        var icon: String {
            switch self {
            case .name: return "person.fill"
            case .totalKM: return "road.lanes"
            case .totalRides: return "number"
            case .avgSpeed: return "speedometer"
            case .elevation: return "mountain.2.fill"
            }
        }
    }
    
    var sortedStats: [MemberStats] {
        let sorted = stats.sorted { stat1, stat2 in
            let comparison: Bool
            switch sortOrder {
            case .name:
                comparison = stat1.memberName < stat2.memberName
            case .totalKM:
                comparison = stat1.totalKM > stat2.totalKM
            case .totalRides:
                comparison = stat1.totalRides > stat2.totalRides
            case .avgSpeed:
                comparison = stat1.avgSpeed > stat2.avgSpeed
            case .elevation:
                comparison = stat1.totalElevation > stat2.totalElevation
            }
            return isAscending ? !comparison : comparison
        }
        return sorted
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Sort controls
            HStack {
                Text("Sort by:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Picker("Sort", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Label(order.rawValue, systemImage: order.icon)
                            .tag(order)
                    }
                }
                .pickerStyle(.menu)
                
                Button {
                    isAscending.toggle()
                } label: {
                    Image(systemName: isAscending ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            // Table header
            HStack {
                Text("Member")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Trend")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(width: 40)
                
                Text("Rides")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(width: 50)
                
                Text("KM")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(width: 60, alignment: .trailing)
                
                Text("Avg Spd")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(width: 60, alignment: .trailing)
                
                Text("Elev")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(width: 60, alignment: .trailing)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            // Table rows
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(sortedStats) { stat in
                        MemberStatsRow(stat: stat)
                        Divider()
                    }
                }
            }
        }
    }
}

struct MemberStatsRow: View {
    let stat: MemberStats
    
    var trendColor: Color {
        switch stat.currentWeekTrend {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        case .new: return .orange
        }
    }
    
    var body: some View {
        HStack {
            Text(stat.memberName)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(stat.trendEmoji)
                .font(.title3)
                .foregroundStyle(trendColor)
                .frame(width: 40)
            
            Text("\(stat.totalRides)")
                .font(.subheadline)
                .frame(width: 50)
            
            Text(String(format: "%.1f", stat.totalKM))
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 60, alignment: .trailing)
            
            Text(String(format: "%.1f", stat.avgSpeed))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)
            
            Text(String(format: "%.0f", stat.totalElevation))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
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
            memberName: "John Doe",
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
        MemberStats(memberName: "John Doe", activities: sampleActivities),
        MemberStats(memberName: "Jane Smith", activities: [sampleActivities[0]]),
    ]
    
    return MemberStatsTableView(stats: stats)
}

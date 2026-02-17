//
//  TVMemberStatsView.swift
//  DCC-Weekly-Activities
//
//  tvOS-optimized member statistics view
//

import SwiftUI

#if os(tvOS)
struct TVMemberStatsView: View {
    let stats: [MemberStats]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 60) {
                // Week summary cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 40) {
                    TVStatCard(
                        title: "Total Distance",
                        value: String(format: "%.1f km", stats.reduce(0) { $0 + $1.totalKM }),
                        icon: "road.lanes",
                        color: .dccBlue
                    )
                    
                    TVStatCard(
                        title: "Total Rides",
                        value: "\(stats.reduce(0) { $0 + $1.totalRides })",
                        icon: "bicycle",
                        color: .dccGreen
                    )
                    
                    TVStatCard(
                        title: "Total Elevation",
                        value: String(format: "%.0f m", stats.reduce(0) { $0 + $1.totalElevation }),
                        icon: "mountain.2.fill",
                        color: .dccSaffron
                    )
                    
                    TVStatCard(
                        title: "Active Members",
                        value: "\(stats.count)",
                        icon: "person.3.fill",
                        color: .dccBlue
                    )
                }
                .padding(.horizontal, 80)
                .padding(.top, 60)
                
                // Top performers list
                VStack(alignment: .leading, spacing: 30) {
                    Text("Top Performers")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(Color.dccBlue)
                        .padding(.horizontal, 80)
                    
                    ForEach(Array(stats.prefix(10).enumerated()), id: \.element.id) { index, stat in
                        TVMemberRow(rank: index + 1, stat: stat)
                            .padding(.horizontal, 80)
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }
}

struct TVStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 52, weight: .bold))
            
            Text(title)
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(50)
        .background(Color(.systemGray6))
        .cornerRadius(30)
    }
}

struct TVMemberRow: View {
    let rank: Int
    let stat: MemberStats
    
    var body: some View {
        HStack(spacing: 40) {
            // Rank
            Text("#\(rank)")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(rankColor)
                .frame(width: 100)
            
            // Name and trend
            VStack(alignment: .leading, spacing: 8) {
                Text(stat.memberName)
                    .font(.system(size: 38, weight: .semibold))
                Text(stat.trendEmoji)
                    .font(.system(size: 32))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Stats
            VStack(alignment: .trailing, spacing: 8) {
                Text(String(format: "%.1f km", stat.totalKM))
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(Color.dccSaffron)
                Text("\(stat.totalRides) rides • \(String(format: "%.1f", stat.avgSpeed)) km/h")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(40)
        .background(Color(.systemGray6))
        .cornerRadius(20)
    }
    
    var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return Color.dccBlue
        }
    }
}

struct TVActivitiesListView: View {
    let activities: [Activity]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 30) {
                ForEach(activities) { activity in
                    TVActivityRow(activity: activity)
                        .padding(.horizontal, 80)
                }
            }
            .padding(.vertical, 60)
        }
    }
}

struct TVActivityRow: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: 40) {
            // Member info
            VStack(alignment: .leading, spacing: 8) {
                Text(activity.memberName)
                    .font(.system(size: 36, weight: .semibold))
                Text(activity.activityName)
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Stats
            VStack(alignment: .trailing, spacing: 8) {
                Text(String(format: "%.1f km", activity.distance))
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(Color.dccSaffron)
                
                HStack(spacing: 20) {
                    Label(String(format: "%.1f km/h", activity.averageSpeed), systemImage: "speedometer")
                    Label(String(format: "%.0f m", activity.elevationGain), systemImage: "mountain.2")
                }
                .font(.system(size: 24))
                .foregroundStyle(.secondary)
            }
        }
        .padding(40)
        .background(Color(.systemGray6))
        .cornerRadius(20)
    }
}
#endif

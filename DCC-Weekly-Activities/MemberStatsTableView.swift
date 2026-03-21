//
//  MemberStatsTableView.swift
//  DCC-Weekly-Activities
//
//  Simple table view for displaying member statistics.
//  Used in the original/legacy dashboard view.
//

import SwiftUI

struct MemberStatsTableView: View {
    let stats: [MemberStats]
    
    var body: some View {
        Group {
            if stats.isEmpty {
                EmptyStateView(
                    icon: "figure.outdoor.cycle",
                    title: "No Activities Yet",
                    message: "Activity data will appear here once members log their rides"
                )
                .padding()
            } else {
                List {
                    ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
                        MemberStatRow(rank: index + 1, stat: stat)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(DCCColors.background.ignoresSafeArea())
    }
}

struct MemberStatRow: View {
    let rank: Int
    let stat: MemberStats
    
    var rankColor: Color {
        switch rank {
        case 1: return DCCColors.gold    // #B8860B — 3.9:1 on white, AA Large
        case 2: return DCCColors.silver  // #6B7280 — 4.6:1 on white, AA
        case 3: return DCCColors.bronze  // #92400E — 7.1:1 on white, AAA
        default: return Color.textSecondary
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rank <= 3 ? rankColor.opacity(0.2) : Color.surfaceElevated)
                    .frame(width: 40, height: 40)
                
                Text("\(rank)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(rankColor)
            }
            
            // Member info
            VStack(alignment: .leading, spacing: 4) {
                Text(stat.memberName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    Label("\(stat.totalRides)", systemImage: "flag.checkered")
                        .font(.caption)
                        .foregroundStyle(DCCColors.textSecondary)

                    Label(String(format: "%.0f m", stat.totalElevation), systemImage: "mountain.2.fill")
                        .font(.caption)
                        .foregroundStyle(DCCColors.textSecondary)
                }
            }
            
            Spacer()
            
            // Distance
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f", stat.totalKM))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.dccSaffron)
                    .monospacedDigit()
                
                Text("km")
                    .font(.caption2)
                    .foregroundStyle(DCCColors.textSecondary)
            }
        }
        .padding(.vertical, 4)
        .background(Color.surface.opacity(0.5))
        .cornerRadius(12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rowAccessibilityLabel)
    }

    private var rowAccessibilityLabel: String {
        let rankText: String
        switch rank {
        case 1: rankText = "1st place"
        case 2: rankText = "2nd place"
        case 3: rankText = "3rd place"
        default: rankText = "Ranked \(rank)"
        }
        return "\(stat.memberName), \(rankText), \(String(format: "%.1f", stat.totalKM)) kilometers in \(stat.totalRides) rides, \(String(format: "%.0f", stat.totalElevation)) metres elevation"
    }
}


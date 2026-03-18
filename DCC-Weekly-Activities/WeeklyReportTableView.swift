//
//  WeeklyReportTableView.swift
//  DCC-Weekly-Activities
//
//  Weekly activity report table matching official DCC format
//

import SwiftUI

struct WeeklyReportTableView: View {
    let stats: [MemberStats]
    
    // Sort by current week KM descending
    private var sortedStats: [MemberStats] {
        stats.sorted { $0.totalKM > $1.totalKM }
    }
    
    // Totals row calculations
    private var totalCurrentKM: Double {
        stats.map { $0.totalKM }.reduce(0, +)
    }
    private var totalPreviousKM: Double {
        stats.map { $0.previousWeekKM }.reduce(0, +)
    }
    private var totalRidesThisWeek: Int {
        stats.map { $0.totalRides }.reduce(0, +)
    }
    private var totalRidesPreviousWeek: Int {
        stats.map { $0.previousWeekRides }.reduce(0, +)
    }
    private var totalAllTimeKM: Double {
        stats.map { $0.totalKM }.reduce(0, +)
    }
    private var totalAllTimeRides: Int {
        stats.map { $0.totalRides }.reduce(0, +)
    }
    private var avgSpeedOverall: Double {
        let speeds = stats.map { $0.avgSpeed }.filter { $0 > 0 }
        guard !speeds.isEmpty else { return 0 }
        return speeds.reduce(0, +) / Double(speeds.count)
    }
    private var totalElevation: Double {
        stats.map { $0.totalElevation }.reduce(0, +)
    }
    
    // Max values for mini bar scaling
    private var maxCurrentKM: Double {
        stats.map { $0.totalKM }.max() ?? 1
    }
    private var maxTotalKM: Double {
        stats.map { $0.totalKM }.max() ?? 1
    }
    private var maxElevation: Double {
        stats.map { $0.totalElevation }.max() ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // Table title
            HStack {
                Text("DCC Weekly Activity Report")
                    .font(.sectionTitle)
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("Week \(currentWeekNumber())")
                    .font(.labelDefault)
                    .foregroundColor(.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.accent.opacity(0.15))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Horizontally scrollable table
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(spacing: 0) {
                    
                    // Header row
                    tableHeaderRow
                    
                    Divider()
                        .background(Color.surfaceElevated)
                    
                    // Data rows
                    ForEach(Array(sortedStats.enumerated()), 
                            id: \.element.id) { index, member in
                        tableDataRow(member: member, index: index)
                        Divider()
                            .background(Color.surface.opacity(0.5))
                    }
                    
                    // Total row
                    tableTotalRow
                }
            }
        }
        .background(Color.surfaceElevated)
        .cornerRadius(16)
    }
    
    // MARK: - Header Row
    private var tableHeaderRow: some View {
        HStack(spacing: 0) {
            TableHeaderCell(text: "Member Name",        width: 110, alignment: .leading)
            TableHeaderCell(text: "Current\nWeek",      width: 90,  alignment: .trailing)
            TableHeaderCell(text: "Previous\nWeek",     width: 90,  alignment: .trailing)
            TableHeaderCell(text: "Trend",              width: 55,  alignment: .center)
            TableHeaderCell(text: "Rides",              width: 55,  alignment: .center)
            TableHeaderCell(text: "Rides\nPrev Wk",     width: 70,  alignment: .center)
            TableHeaderCell(text: "Total KM",           width: 90,  alignment: .trailing)
            TableHeaderCell(text: "Total\nRides",       width: 65,  alignment: .center)
            TableHeaderCell(text: "Avg Speed\n(km/h)",  width: 85,  alignment: .trailing)
            TableHeaderCell(text: "Elevation\n(m)",     width: 90,  alignment: .trailing)
        }
        .background(Color.accent.opacity(0.15))
        .padding(.vertical, 8)
    }
    
    // MARK: - Data Row
    private func tableDataRow(member: MemberStats, index: Int) -> some View {
        let currentKM     = member.totalKM
        let previousKM    = member.previousWeekKM
        let ridesThisWeek = member.totalRides
        let ridesPrevWeek = member.previousWeekRides
        let allTimeKM     = member.totalKM
        let allTimeRides  = member.totalRides
        let avgSpd        = member.avgSpeed
        let elevation     = member.totalElevation
        let name          = member.memberName
        let trend         = member.currentWeekTrend
        
        let rowBg = index % 2 == 0 
            ? Color.surface.opacity(0.3) 
            : Color.clear
        
        return HStack(spacing: 0) {
            
            // Member Name
            Text(name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textPrimary)
                .frame(width: 110, alignment: .leading)
                .padding(.horizontal, 8)
            
            // Current Week — number + mini green bar
            VStack(alignment: .trailing, spacing: 2) {
                Text(currentKM > 0 ? "\(String(format: "%.1f", currentKM))" : "0")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textPrimary)
                if currentKM > 0 {
                    MiniBarView(
                        value: currentKM,
                        max: maxCurrentKM,
                        color: .dccGreen,
                        width: 60,
                        height: 4
                    )
                }
            }
            .frame(width: 90, alignment: .trailing)
            .padding(.horizontal, 8)
            
            // Previous Week
            Text(previousKM > 0 ? "\(String(format: "%.1f", previousKM))" : "0")
                .font(.system(size: 13))
                .foregroundColor(.textSecondary)
                .frame(width: 90, alignment: .trailing)
                .padding(.horizontal, 8)
            
            // Trend arrow
            TrendIndicatorView(trend: trend)
                .frame(width: 55, alignment: .center)
            
            // Rides this week
            Text("\(ridesThisWeek)")
                .font(.system(size: 13))
                .foregroundColor(.textPrimary)
                .frame(width: 55, alignment: .center)
            
            // Rides previous week
            Text("\(ridesPrevWeek)")
                .font(.system(size: 13))
                .foregroundColor(.textSecondary)
                .frame(width: 70, alignment: .center)
            
            // Total KM — number + mini blue bar
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f", allTimeKM))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textPrimary)
                MiniBarView(
                    value: allTimeKM,
                    max: maxTotalKM,
                    color: .dccBlue,
                    width: 60,
                    height: 4
                )
            }
            .frame(width: 90, alignment: .trailing)
            .padding(.horizontal, 8)
            
            // Total Rides
            Text("\(allTimeRides)")
                .font(.system(size: 13))
                .foregroundColor(.textPrimary)
                .frame(width: 65, alignment: .center)
            
            // Avg Speed
            Text(avgSpd > 0 ? String(format: "%.1f", avgSpd) : "-")
                .font(.system(size: 13))
                .foregroundColor(.textPrimary)
                .frame(width: 85, alignment: .trailing)
                .padding(.horizontal, 8)
            
            // Elevation — number + mini orange bar
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(elevation))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textPrimary)
                MiniBarView(
                    value: elevation,
                    max: maxElevation,
                    color: .dccSaffron,
                    width: 60,
                    height: 4
                )
            }
            .frame(width: 90, alignment: .trailing)
            .padding(.horizontal, 8)
        }
        .padding(.vertical, 10)
        .background(rowBg)
    }
    
    // MARK: - Total Row
    private var tableTotalRow: some View {
        HStack(spacing: 0) {
            Text("Total")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.dccBlue)
                .frame(width: 110, alignment: .leading)
                .padding(.horizontal, 8)
            
            Text(String(format: "%.1f", totalCurrentKM))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.textPrimary)
                .frame(width: 90, alignment: .trailing)
                .padding(.horizontal, 8)
            
            Text(String(format: "%.1f", totalPreviousKM))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.textPrimary)
                .frame(width: 90, alignment: .trailing)
                .padding(.horizontal, 8)
            
            // Trend total — show up arrow if total improved
            Image(systemName: totalCurrentKM >= totalPreviousKM 
                  ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                .foregroundColor(totalCurrentKM >= totalPreviousKM 
                                  ? .dccGreen : .accent)
                .font(.system(size: 12))
                .frame(width: 55, alignment: .center)
            
            Text("\(totalRidesThisWeek)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.textPrimary)
                .frame(width: 55, alignment: .center)
            
            Text("\(totalRidesPreviousWeek)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.textPrimary)
                .frame(width: 70, alignment: .center)
            
            Text(String(format: "%.1f", totalAllTimeKM))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.textPrimary)
                .frame(width: 90, alignment: .trailing)
                .padding(.horizontal, 8)
            
            Text("\(totalAllTimeRides)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.textPrimary)
                .frame(width: 65, alignment: .center)
            
            Text(String(format: "%.1f", avgSpeedOverall))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.textPrimary)
                .frame(width: 85, alignment: .trailing)
                .padding(.horizontal, 8)
            
            Text("\(Int(totalElevation))")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.textPrimary)
                .frame(width: 90, alignment: .trailing)
                .padding(.horizontal, 8)
        }
        .padding(.vertical, 10)
        .background(Color.dccBlue.opacity(0.12))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.dccBlue.opacity(0.3)),
            alignment: .top
        )
    }
    
    // MARK: - Week Number Helper
    private func currentWeekNumber() -> Int {
        Calendar.current.component(.weekOfYear, from: Date())
    }
}

// MARK: - Supporting Components

// Mini bar indicator — used for Current Week (green), Total KM (blue), Elevation (orange)
struct MiniBarView: View {
    let value: Double
    let max: Double
    let color: Color
    let width: CGFloat
    let height: CGFloat
    @State private var animProgress: Double = 0
    
    private var ratio: Double {
        guard max > 0 else { return 0 }
        let r = value / max
        return r.isFinite ? min(r, 1.0) : 0
    }
    
    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color.opacity(0.2))
                    .frame(width: width, height: height)
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(
                        width: Swift.max(width * ratio * animProgress, 0),
                        height: height
                    )
            }
        }
        .frame(width: width, height: height)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animProgress = 1.0
            }
        }
    }
}

// Table header cell — consistent styling
struct TableHeaderCell: View {
    let text: String
    let width: CGFloat
    let alignment: HorizontalAlignment
    
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.textSecondary)
            .multilineTextAlignment(alignment == .leading ? .leading 
                                    : alignment == .trailing ? .trailing 
                                    : .center)
            .frame(width: width, alignment: Alignment(
                horizontal: alignment, vertical: .center)
            )
            .padding(.horizontal, 8)
    }
}

// Trend indicator — ▲ green, ▼ red, - grey, ★ for new
struct TrendIndicatorView: View {
    let trend: MemberStats.TrendDirection
    
    private var icon: String {
        switch trend {
        case .up:      return "arrowtriangle.up.fill"
        case .down:    return "arrowtriangle.down.fill"
        case .stable:  return "minus"
        case .new:     return "star.fill"
        }
    }
    
    private var color: Color {
        switch trend {
        case .up:      return .dccGreen
        case .down:    return .accent
        case .stable:  return .textSecondary
        case .new:     return .dccSaffron
        }
    }
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(color)
    }
}

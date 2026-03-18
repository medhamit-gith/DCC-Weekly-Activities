//
//  MeVsTop3View.swift
//  DCC-Weekly-Activities
//
//  Comparison view: authenticated user vs top 3 riders by distance
//  Shows grouped bar charts for all available parameters with plain-English insights
//
//  REWRITE: 2026-02-24
//  Reason: Accumulated 4+ cascading errors from patches. Clean rewrite with explicit types.
//

import SwiftUI
import Charts

struct MeVsTop3View: View {
    // MARK: - Properties
    
    let athleteProfile: AthleteProfile
    let stats: [MemberStats]
    let dateRange: (start: Date, end: Date)?
    
    @State private var selectedMember: MemberStats?
    
    // MARK: - Computed Properties (All above body)
    
    private var fullName: String {
        "\(athleteProfile.firstname) \(athleteProfile.lastname)"
    }
    
    private var myStats: MemberStats? {
        let matches: [MemberStats] = stats.filter { (stat: MemberStats) -> Bool in
            stat.memberName == fullName
        }
        return matches.first
    }
    
    private var myRanking: Int {
        let sortedStats: [MemberStats] = stats.sorted { (a: MemberStats, b: MemberStats) -> Bool in
            a.totalKM > b.totalKM
        }
        
        if let index = sortedStats.firstIndex(where: { (stat: MemberStats) -> Bool in
            stat.memberName == fullName
        }) {
            return index + 1
        }
        
        return 0
    }
    
    private var top3Stats: [MemberStats] {
        let sortedStats: [MemberStats] = stats.sorted { (a: MemberStats, b: MemberStats) -> Bool in
            a.totalKM > b.totalKM
        }
        return Array(sortedStats.prefix(3))
    }
    
    private var comparisonStats: [MemberStats] {
        var result: [MemberStats] = top3Stats
        
        if myRanking > 3, let userStats = myStats {
            result.append(userStats)
        }
        
        return result
    }
    
    private var dateInterval: DateInterval? {
        guard let range = dateRange else { return nil }
        return DateInterval(start: range.start, end: range.end)
    }
    
    private var rankingColor: Color {
        switch myRanking {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .dccBlue
        }
    }
    
    private var rankingIcon: String {
        switch myRanking {
        case 1: return "trophy.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return "person.fill"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if stats.isEmpty {
                emptyStatsView
            } else if myStats == nil {
                userNotFoundView
            } else {
                mainContentView
            }
        }
        .background(backgroundGradient)
        .navigationDestination(item: $selectedMember) { (member: MemberStats) in
            MemberDetailView(memberStats: member, allStats: stats)
        }
    }
    
    // MARK: - Main Views
    
    private var emptyStatsView: some View {
        ContentUnavailableView(
            "No Club Data Available",
            systemImage: "figure.outdoor.cycle",
            description: Text("There are no activities to display for this week.")
        )
    }
    
    private var userNotFoundView: some View {
        ScrollView {
            VStack(spacing: 24) {
                DateRangeHeaderView(dateRange: dateInterval, showWeekLabel: false)
                    .padding(.top, 8)
                
                Divider()
                    .padding(.horizontal)
                
                ContentUnavailableView(
                    "Your Data Not Found",
                    systemImage: "person.crop.circle.badge.xmark",
                    description: Text("We couldn't match your Strava profile (\(fullName)) with any club member activities. Make sure your name in Strava matches your club registration.")
                )
                .padding(.vertical, 40)
                
                Divider()
                    .padding(.horizontal)
                
                top3FallbackList
            }
            .padding(.vertical, 24)
        }
    }
    
    private var top3FallbackList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top 3 This Week")
                .font(.headline)
                .padding(.horizontal, 24)
            
            ForEach(top3Stats) { (stat: MemberStats) in
                HStack {
                    Text("#\(rankingFor(stat: stat))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .frame(width: 40)
                    
                    Text(stat.memberName)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(formatDistance(stat.totalKM))
                        .font(.headline)
                        .foregroundStyle(Color.dccSaffron)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                DateRangeHeaderView(dateRange: dateInterval, showWeekLabel: false)
                    .padding(.top, 8)
                
                Divider()
                    .padding(.horizontal)
                
                headerSection
                
                if let userStats = myStats {
                    rankingCard(stats: userStats)
                }
                
                Divider()
                    .padding(.horizontal)
                
                // Comparison header with avatars
                comparisonHeader
                
                Divider()
                    .padding(.horizontal)
                
                chartsSection
                
                Divider()
                    .padding(.horizontal)
                
                // Stat comparison table
                statComparisonTable
                
                Divider()
                    .padding(.horizontal)
                
                // Insights section
                insightsSection
            }
            .padding(.vertical, 24)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.dccGreen, Color.dccSaffron],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("You vs Top Performers")
                .font(.title2)
                .fontWeight(.bold)
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.dccBlue.opacity(0.15),
                Color.dccSaffron.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Ranking Card
    
    private func rankingCard(stats: MemberStats) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Ranking")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("#\(myRanking)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(rankingColor)
                        
                        Text("of \(self.stats.count)")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: rankingIcon)
                    .font(.system(size: 60))
                    .foregroundStyle(rankingColor.gradient)
            }
            
            Divider()
            
            HStack(spacing: 20) {
                quickStatWithTrend(
                    label: "Distance",
                    currentValue: formatDistance(stats.totalKM),
                    previousValue: formatDistance(stats.previousWeekKM),
                    icon: "road.lanes",
                    trend: stats.currentWeekTrend
                )
                
                quickStatWithTrend(
                    label: "Rides",
                    currentValue: "\(stats.totalRides)",
                    previousValue: "\(stats.previousWeekRides)",
                    icon: "bicycle",
                    trend: stats.currentWeekTrend
                )
                
                quickStat(
                    label: "Avg Speed",
                    value: formatSpeed(stats.avgSpeed),
                    icon: "speedometer"
                )
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: rankingColor.opacity(0.2), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 24)
    }
    
    private func quickStat(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.dccSaffron)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func quickStatWithTrend(
        label: String,
        currentValue: String,
        previousValue: String,
        icon: String,
        trend: MemberStats.TrendDirection
    ) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.dccSaffron)
                
                Image(systemName: trendIcon(trend: trend))
                    .font(.caption)
                    .foregroundStyle(trendColor(trend: trend))
            }
            
            Text(currentValue)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Text("Last: \(previousValue)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Comparison Header
    
    private var comparisonHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week's Top Performers")
                .font(.headline)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(comparisonStats) { stat in
                        let isCurrentUser = stat.memberName == fullName
                        
                        VStack(spacing: 8) {
                            // Trend icon
                            Image(systemName: trendIcon(trend: stat.currentWeekTrend))
                                .font(.title2)
                                .foregroundStyle(trendColor(trend: stat.currentWeekTrend))
                            
                            // Name
                            Text(shortName(fullName: stat.memberName))
                                .font(isCurrentUser ? .headline : .subheadline)
                                .fontWeight(isCurrentUser ? .bold : .regular)
                                .lineLimit(1)
                            
                            // Distance
                            Text(formatDistance(stat.totalKM))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if isCurrentUser {
                                Text("You")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.dccBlue)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(width: 90)
                        .padding()
                        .background(
                            isCurrentUser ?
                                Color.dccBlue.opacity(0.12) :
                                Color(.systemGray6)
                        )
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    // MARK: - Stat Comparison Table
    
    private var statComparisonTable: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Full Comparison")
                .font(.headline)
                .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                comparisonTableRow(
                    metric: "This Week KM",
                    values: comparisonStats.map { $0.totalKM },
                    formatter: { formatDistance($0) }
                )
                
                comparisonTableRow(
                    metric: "Last Week KM",
                    values: comparisonStats.map { $0.previousWeekKM },
                    formatter: { formatDistance($0) }
                )
                
                comparisonTableRow(
                    metric: "Week Change",
                    values: comparisonStats.map { $0.totalKM - $0.previousWeekKM },
                    formatter: { 
                        let sign = $0 >= 0 ? "+" : ""
                        return "\(sign)\(formatDistance($0))"
                    },
                    isChange: true
                )
                
                comparisonTableRow(
                    metric: "Total Rides",
                    values: comparisonStats.map { Double($0.totalRides) },
                    formatter: { String(format: "%.0f", $0) }
                )
                
                comparisonTableRow(
                    metric: "Avg Speed",
                    values: comparisonStats.map { $0.avgSpeed },
                    formatter: { formatSpeed($0) }
                )
                
                comparisonTableRow(
                    metric: "Elevation",
                    values: comparisonStats.map { $0.totalElevation },
                    formatter: { formatElevation($0) }
                )
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }
    
    private func comparisonTableRow(metric: String, values: [Double], formatter: @escaping (Double) -> String, isChange: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(metric)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                ForEach(Array(zip(comparisonStats, values).enumerated()), id: \.offset) { index, pair in
                    let (stat, value) = pair
                    let isCurrentUser = stat.memberName == fullName
                    let rank = getRank(value: value, in: values)
                    let isHighest = rank == 1 && values.count > 1
                    let isLowest = rank == values.count && values.count > 1
                    
                    VStack(spacing: 4) {
                        Text(formatter(value))
                            .font(.caption)
                            .fontWeight(isCurrentUser ? .bold : .regular)
                            .foregroundStyle(
                                isChange ?
                                    (value >= 0 ? Color.green : Color.red) :
                                    .primary
                            )
                        
                        Text(ordinal(rank))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        isCurrentUser && isHighest ? Color.green.opacity(0.15) :
                        isCurrentUser && isLowest ? Color.red.opacity(0.15) :
                        isCurrentUser ? Color.dccBlue.opacity(0.08) :
                        Color.clear
                    )
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func getRank(value: Double, in values: [Double]) -> Int {
        let sorted = values.sorted(by: >)
        return (sorted.firstIndex(of: value) ?? 0) + 1
    }
    
    private func ordinal(_ rank: Int) -> String {
        switch rank {
        case 1: return "1st"
        case 2: return "2nd"
        case 3: return "3rd"
        default: return "\(rank)th"
        }
    }
    
    // MARK: - Insights Section
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Competitive Insights")
                .font(.headline)
                .padding(.horizontal, 24)
            
            if let userStats = myStats {
                let insights = RiderInsightEngine.insights(
                    for: userStats,
                    against: comparisonStats,
                    mode: .vsTop3
                )
                
                if insights.isEmpty {
                    ContentUnavailableView(
                        "Not enough data yet",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Keep riding to unlock competitive insights")
                    )
                    .padding(.vertical, 40)
                } else {
                    ForEach(Array(insights.prefix(4))) { insight in
                        insightCard(insight: insight)
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }
    
    private func insightCard(insight: RiderInsight) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.icon)
                .foregroundStyle(insight.iconColor)
                .font(.title2)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.headline)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(insight.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(
            insight.sentiment == .positive ?
                Color.green.opacity(0.08) :
            insight.sentiment == .negative ?
                Color.red.opacity(0.08) :
            insight.sentiment == .remarkable ?
                Color.purple.opacity(0.08) :
                Color.orange.opacity(0.08)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
    }
    
    // MARK: - Charts Section
    
    private var chartsSection: some View {
        VStack(spacing: 24) {
            comparisonChart(
                title: "Total Distance",
                unit: "km",
                color: .dccSaffron,
                getValue: { (stat: MemberStats) -> Double in stat.totalKM },
                insight: distanceInsightText
            )
            
            comparisonChart(
                title: "Number of Rides",
                unit: "rides",
                color: .dccGreen,
                getValue: { (stat: MemberStats) -> Double in Double(stat.totalRides) },
                insight: ridesInsightText,
                decimals: 0
            )
            
            comparisonChart(
                title: "Total Elevation Gain",
                unit: "m",
                color: .dccBlue,
                getValue: { (stat: MemberStats) -> Double in stat.totalElevation },
                insight: elevationInsightText,
                decimals: 0
            )
            
            comparisonChart(
                title: "Average Speed",
                unit: "km/h",
                color: .purple,
                getValue: { (stat: MemberStats) -> Double in stat.avgSpeed },
                insight: speedInsightText
            )
            
            if myStats != nil {
                movingTimeChartView
            }
        }
    }
    
    private func comparisonChart(
        title: String,
        unit: String,
        color: Color,
        getValue: @escaping (MemberStats) -> Double,
        insight: String,
        decimals: Int = 1
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .padding(.horizontal, 24)
            
            Chart(comparisonStats) { (stat: MemberStats) in
                let shortNameValue: String = shortName(fullName: stat.memberName)
                let value: Double = getValue(stat)
                let isCurrentUserValue: Bool = stat.memberName == fullName
                
                BarMark(
                    x: .value("Member", shortNameValue),
                    y: .value(title, value)
                )
                .foregroundStyle(
                    isCurrentUserValue ? color.gradient : Color.gray.opacity(0.4).gradient
                )
                .annotation(position: .top) {
                    Text(formatValue(value: value, decimals: decimals))
                        .font(.caption2)
                        .fontWeight(isCurrentUserValue ? .bold : .regular)
                        .foregroundStyle(isCurrentUserValue ? color : .primary)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let name = value.as(String.self) {
                            VStack(spacing: 2) {
                                Text(name)
                                    .font(.caption2)
                                    .lineLimit(1)
                                
                                if isCurrentUserShortName(shortName: name) {
                                    Text("(You)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(color)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
            insightBox(text: insight)
            
            riderButtonsScroll(color: color)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }
    
    private var movingTimeChartView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Total Moving Time")
                .font(.headline)
                .padding(.horizontal, 24)
            
            Chart(comparisonStats) { (stat: MemberStats) in
                let shortNameValue: String = shortName(fullName: stat.memberName)
                let hours: Double = calculateMovingTimeHours(stat: stat)
                let isCurrentUserValue: Bool = stat.memberName == fullName
                
                BarMark(
                    x: .value("Member", shortNameValue),
                    y: .value("Hours", hours)
                )
                .foregroundStyle(
                    isCurrentUserValue ? Color.orange.gradient : Color.gray.opacity(0.4).gradient
                )
                .annotation(position: .top) {
                    Text(formatHours(hours: hours))
                        .font(.caption2)
                        .fontWeight(isCurrentUserValue ? .bold : .regular)
                        .foregroundStyle(isCurrentUserValue ? .orange : .primary)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let name = value.as(String.self) {
                            VStack(spacing: 2) {
                                Text(name)
                                    .font(.caption2)
                                    .lineLimit(1)
                                
                                if isCurrentUserShortName(shortName: name) {
                                    Text("(You)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
            insightBox(text: movingTimeInsightText)
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }
    
    private func insightBox(text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.title3)
                .foregroundStyle(.orange)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal, 24)
    }
    
    private func riderButtonsScroll(color: Color) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(comparisonStats) { (stat: MemberStats) in
                    Button {
                        selectedMember = stat
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(stat.memberName == fullName ? color : .gray)
                            
                            Text(shortName(fullName: stat.memberName))
                                .font(.caption)
                                .fontWeight(stat.memberName == fullName ? .bold : .regular)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("View \(stat.memberName)'s details")
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Insights (Computed)
    
    private var distanceInsightText: String {
        guard let userStats = myStats,
              let topRider = top3Stats.first else {
            return "No data available for comparison."
        }
        
        let diff: Double = topRider.totalKM - userStats.totalKM
        let top3Avg: Double = calculateTop3Average { (stat: MemberStats) -> Double in stat.totalKM }
        let avgDiff: Double = userStats.totalKM - top3Avg
        
        if myRanking == 1 {
            return "You're the distance leader this week with \(formatDistance(userStats.totalKM))!"
        } else if diff < 5 {
            return "You rode \(formatDistance(abs(diff))) less than the top rider. You're very close to the lead!"
        } else if avgDiff >= 0 {
            return "You rode \(formatDistance(diff)) less than the top rider but \(formatDistance(avgDiff)) more than the top 3 average."
        } else {
            return "You rode \(formatDistance(abs(avgDiff))) less than the top 3 average of \(formatDistance(top3Avg))."
        }
    }
    
    private var ridesInsightText: String {
        guard let userStats = myStats,
              let topRider = top3Stats.first else {
            return "No data available for comparison."
        }
        
        let diff: Int = topRider.totalRides - userStats.totalRides
        let top3Avg: Double = calculateTop3Average { (stat: MemberStats) -> Double in Double(stat.totalRides) }
        
        if myRanking == 1 {
            return "You completed the most rides this week with \(userStats.totalRides) activities!"
        } else if diff == 0 {
            return "You matched the top rider with \(userStats.totalRides) rides this week."
        } else {
            let pluralSuffix: String = diff == 1 ? "" : "s"
            return "You completed \(diff) fewer ride\(pluralSuffix) than the top rider. The top 3 average is \(String(format: "%.1f", top3Avg)) rides."
        }
    }
    
    private var elevationInsightText: String {
        guard let userStats = myStats,
              let topRider = top3Stats.first else {
            return "No data available for comparison."
        }
        
        let diff: Double = topRider.totalElevation - userStats.totalElevation
        let top3Avg: Double = calculateTop3Average { (stat: MemberStats) -> Double in stat.totalElevation }
        
        if myRanking == 1 {
            return "You conquered the most elevation this week with \(formatElevation(userStats.totalElevation))!"
        } else if diff < 100 {
            return "You climbed \(formatElevation(abs(diff))) less than the top rider. Nearly matched their climbing!"
        } else if userStats.totalElevation > top3Avg {
            let aboveAvg: Double = userStats.totalElevation - top3Avg
            return "You climbed \(formatElevation(userStats.totalElevation)), which is \(formatElevation(aboveAvg)) above the top 3 average."
        } else {
            let belowAvg: Double = top3Avg - userStats.totalElevation
            return "You climbed \(formatElevation(abs(diff))) less than the top rider and \(formatElevation(belowAvg)) below the top 3 average."
        }
    }
    
    private var speedInsightText: String {
        guard let userStats = myStats,
              let topRider = top3Stats.first else {
            return "No data available for comparison."
        }
        
        let diff: Double = userStats.avgSpeed - topRider.avgSpeed
        let top3Avg: Double = calculateTop3Average { (stat: MemberStats) -> Double in stat.avgSpeed }
        
        if myRanking == 1 {
            return "You had the highest average speed this week at \(formatSpeed(userStats.avgSpeed))!"
        } else if abs(diff) < 2 {
            return "Your average speed of \(formatSpeed(userStats.avgSpeed)) is very close to the top rider's \(formatSpeed(topRider.avgSpeed))."
        } else if userStats.avgSpeed > top3Avg {
            let faster: Double = userStats.avgSpeed - top3Avg
            return "Your average speed of \(formatSpeed(userStats.avgSpeed)) is \(formatSpeed(faster)) faster than the top 3 average."
        } else {
            return "Your average speed was \(formatSpeed(abs(diff))) slower than the top rider at \(formatSpeed(userStats.avgSpeed))."
        }
    }
    
    private var movingTimeInsightText: String {
        guard let userStats = myStats else {
            return "No data available."
        }
        
        let myHours: Double = calculateMovingTimeHours(stat: userStats)
        let top3Hours: [Double] = top3Stats.map { (stat: MemberStats) -> Double in
            calculateMovingTimeHours(stat: stat)
        }
        
        guard !top3Hours.isEmpty else {
            return "No comparison data available."
        }
        
        let top3Avg: Double = top3Hours.reduce(0.0) { (sum: Double, hours: Double) -> Double in
            sum + hours
        } / Double(top3Hours.count)
        
        if myHours > top3Avg {
            let more: Double = myHours - top3Avg
            return "You spent \(formatHours(hours: more)) more hours riding than the top 3 average of \(formatHours(hours: top3Avg))."
        } else {
            let less: Double = top3Avg - myHours
            return "You spent \(formatHours(hours: myHours)) on the bike, which is \(formatHours(hours: less)) less than the top 3 average."
        }
    }
    
    // MARK: - Helper Functions
    
    private func rankingFor(stat: MemberStats) -> Int {
        let sortedStats: [MemberStats] = stats.sorted { (a: MemberStats, b: MemberStats) -> Bool in
            a.totalKM > b.totalKM
        }
        
        if let index = sortedStats.firstIndex(where: { (s: MemberStats) -> Bool in
            s.id == stat.id
        }) {
            return index + 1
        }
        
        return 0
    }
    
    private func shortName(fullName: String) -> String {
        let components: [String] = fullName.components(separatedBy: " ")
        
        if components.count >= 2 {
            let firstName: String = components[0]
            let lastInitial: String = String(components[1].prefix(1))
            return "\(firstName) \(lastInitial)."
        }
        
        return fullName
    }
    
    private func isCurrentUserShortName(shortName: String) -> Bool {
        let userShortName: String = self.shortName(fullName: fullName)
        return shortName == userShortName
    }
    
    private func calculateTop3Average(getValue: (MemberStats) -> Double) -> Double {
        guard !top3Stats.isEmpty else { return 0 }
        
        let total: Double = top3Stats.reduce(0.0) { (sum: Double, stat: MemberStats) -> Double in
            sum + getValue(stat)
        }
        
        return total / Double(top3Stats.count)
    }
    
    private func calculateMovingTimeHours(stat: MemberStats) -> Double {
        let totalSeconds: Int = stat.rides.reduce(0) { (sum: Int, activity: Activity) -> Int in
            sum + activity.movingTime
        }
        return Double(totalSeconds) / 3600.0
    }
    
    private func trendIcon(trend: MemberStats.TrendDirection) -> String {
        switch trend {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        case .new: return "star.circle.fill"
        }
    }
    
    private func trendColor(trend: MemberStats.TrendDirection) -> Color {
        switch trend {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        case .new: return .orange
        }
    }
    
    // MARK: - Formatters
    
    private func formatDistance(_ km: Double) -> String {
        String(format: "%.1f km", km)
    }
    
    private func formatSpeed(_ kmh: Double) -> String {
        String(format: "%.1f km/h", kmh)
    }
    
    private func formatElevation(_ meters: Double) -> String {
        String(format: "%.0f m", meters)
    }
    
    private func formatHours(hours: Double) -> String {
        String(format: "%.1fh", hours)
    }
    
    private func formatValue(value: Double, decimals: Int) -> String {
        String(format: "%.\(decimals)f", value)
    }
}

// MARK: - Preview

#Preview {
    let sampleActivities: [Activity] = [
        Activity(
            memberName: "Alice Smith",
            activityName: "Morning Ride",
            distance: 65.5,
            date: Date(),
            averageSpeed: 32.5,
            elevationGain: 650,
            movingTime: 6400,
            type: "Ride"
        ),
        Activity(
            memberName: "Bob Wilson",
            activityName: "Evening Ride",
            distance: 52.0,
            date: Date().addingTimeInterval(-86400),
            averageSpeed: 28.0,
            elevationGain: 420,
            movingTime: 5600,
            type: "Ride"
        ),
        Activity(
            memberName: "Charlie Brown",
            activityName: "Hill Climb",
            distance: 48.5,
            date: Date(),
            averageSpeed: 24.0,
            elevationGain: 900,
            movingTime: 5200,
            type: "Ride"
        ),
        Activity(
            memberName: "John Doe",
            activityName: "Weekend Ride",
            distance: 35.0,
            date: Date(),
            averageSpeed: 26.0,
            elevationGain: 320,
            movingTime: 4400,
            type: "Ride"
        )
    ]
    
    let stats: [MemberStats] = [
        MemberStats(memberName: "Alice Smith", activities: [sampleActivities[0]]),
        MemberStats(memberName: "Bob Wilson", activities: [sampleActivities[1]]),
        MemberStats(memberName: "Charlie Brown", activities: [sampleActivities[2]]),
        MemberStats(memberName: "John Doe", activities: [sampleActivities[3]])
    ]
    
    let interval: DateInterval = DateRangeProvider.getLastCompletedWeek()
    let dateRange: (start: Date, end: Date) = (start: interval.start, end: interval.end)
    
    let profile: AthleteProfile = AthleteProfile(
        id: 12345,
        firstname: "John",
        lastname: "Doe",
        profile: nil,
        city: "Delhi",
        state: nil,
        country: "India"
    )
    
    return NavigationStack {
        MeVsTop3View(
            athleteProfile: profile,
            stats: stats,
            dateRange: dateRange
        )
        .navigationTitle("Me vs Top 3")
        .navigationBarTitleDisplayMode(.inline)
    }
}

//
//  PersonalInsightsView.swift
//  DCC-Weekly-Activities
//
//  Personal performance dashboard for the logged-in user
//

import SwiftUI

struct PersonalInsightsView: View {
    let athleteProfile: AthleteProfile
    let allStats: [MemberStats]
    let allActivities: [Activity]
    
    // Computed properties to extract logged-in user's data
    private var myFullName: String {
        "\(athleteProfile.firstname) \(athleteProfile.lastname)"
    }
    
    private var myStats: MemberStats? {
        // Normalize names for robust matching
        let firstName = athleteProfile.firstname.lowercased().trimmingCharacters(in: .whitespaces)
        let lastName = athleteProfile.lastname.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Try exact match first (firstname + lastname in memberName)
        if let exactMatch = allStats.first(where: { stat in
            let name = stat.memberName.lowercased().trimmingCharacters(in: .whitespaces)
            return name.contains(firstName) && name.contains(lastName)
        }) {
            return exactMatch
        }
        
        // Fallback: Try matching just lastname (more reliable)
        if let lastNameMatch = allStats.first(where: { stat in
            let name = stat.memberName.lowercased().trimmingCharacters(in: .whitespaces)
            return name.contains(lastName) && lastName.count >= 3  // Avoid false positives on short names
        }) {
            return lastNameMatch
        }
        
        // Final fallback: Return first stat (assumes PersonalInsightsView is user-specific)
        return allStats.first
    }
    
    private var myActivities: [Activity] {
        // Normalize names for robust matching
        let firstName = athleteProfile.firstname.lowercased().trimmingCharacters(in: .whitespaces)
        let lastName = athleteProfile.lastname.lowercased().trimmingCharacters(in: .whitespaces)
        
        return allActivities.filter { activity in
            let name = activity.memberName.lowercased().trimmingCharacters(in: .whitespaces)
            // Match by both names, or just lastname if firstname fails
            return (name.contains(firstName) && name.contains(lastName)) ||
                   (name.contains(lastName) && lastName.count >= 3)
        }
    }
    
    private var rankedRiders: [MemberStats] {
        allStats.sorted { $0.totalKM > $1.totalKM }
    }
    
    private var myRank: Int {
        guard let stats = myStats else { return allStats.count }
        return (rankedRiders.firstIndex(where: { $0.memberName == stats.memberName }) ?? 0) + 1
    }
    
    @State private var showSection1 = false
    @State private var selectedCompareRider: MemberStats?
    @State private var showSection2 = false
    @State private var showSection3 = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Header with rank badge
                personalHeader
                
                // Section 1: My Performance
                section1Performance
                
                // Section 2: Compare With
                section2Compare
                
                // Section 3: Performance Zones
                section3Zones
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.lg)
        }
        .navigationTitle("My Insights")
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) {
                showSection1 = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.4)) {
                showSection2 = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.7)) {
                showSection3 = true
            }
        }
    }
    
    // MARK: - Personal Header
    
    @ViewBuilder
    private var personalHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("YOUR WEEK")
                    .font(.labelDefault)
                    .foregroundColor(.textSecondary)
                Text(myStats?.memberName ?? myFullName)
                    .font(.cardTitle)
                    .foregroundColor(.textPrimary)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(rankGradient(myRank))
                    .frame(width: 52, height: 52)
                Text(rankEmoji(myRank))
                    .font(.system(size: 24))
            }
        }
        .padding(Spacing.md)
        .background(Color.surfaceElevated)
        .cornerRadius(CornerRadius.lg)
    }
    
    private func rankEmoji(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(rank)"
        }
    }
    
    private func rankGradient(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color.yellow.opacity(0.3)
        case 2: return Color.gray.opacity(0.3)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2).opacity(0.3)
        default: return Color.accent.opacity(0.2)
        }
    }
    
    // MARK: - Section 1: My Performance
    
    @ViewBuilder
    private var section1Performance: some View {
        if let stats = myStats {
            VStack(alignment: .leading, spacing: Spacing.md) {
                
                // Section header
                HStack(spacing: 8) {
                    Text("⚡").font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("My Performance")
                            .font(.sectionTitle)
                            .foregroundColor(.textPrimary)
                        Text("What's working and what to improve")
                            .font(.labelDefault)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                // 4 animated rings — distance, speed, elevation, rides
                AnimatedRingsView(metrics: ringMetrics(stats: stats))
                    .frame(height: 100)
                    .opacity(showSection1 ? 1 : 0)
                    .scaleEffect(showSection1 ? 1 : 0.85)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7)
                        .delay(0.1), value: showSection1)
                
                // Strength bars — one per metric
                VStack(spacing: Spacing.sm) {
                    ForEach(strengthMetrics(stats: stats)) { metric in
                        StrengthBarRow(metric: metric)
                    }
                }
                .opacity(showSection1 ? 1 : 0)
                .offset(y: showSection1 ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.75)
                    .delay(0.25), value: showSection1)
                
                // 2 insight callouts side by side
                HStack(spacing: Spacing.sm) {
                    InsightCallout(
                        type: .strength,
                        icon: "✅",
                        title: topStrength(stats: stats).label,
                        message: topStrength(stats: stats).message
                    )
                    InsightCallout(
                        type: .improve,
                        icon: "📈",
                        title: topImprovement(stats: stats).label,
                        message: topImprovement(stats: stats).message
                    )
                }
                .opacity(showSection1 ? 1 : 0)
                .offset(y: showSection1 ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.75)
                    .delay(0.4), value: showSection1)
            }
            .padding(Spacing.md)
            .background(Color.surfaceElevated)
            .cornerRadius(CornerRadius.lg)
        } else {
            // Fallback if myStats is somehow still nil
            VStack {
                Text("Unable to load your stats")
                    .font(.bodyDefault)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
            .background(Color.surfaceElevated)
            .cornerRadius(CornerRadius.lg)
        }
    }
    
    // MARK: - Data Helpers for Section 1
    
    // NaN-safe division
    private func safeDiv(_ a: Double, _ b: Double) -> Double {
        guard b != 0 else { return 0 }
        let result = a / b
        return result.isFinite ? result : 0
    }
    
    // Ring metrics — value vs club best
    private func ringMetrics(stats: MemberStats) -> [RingMetric] {
        let maxKM   = rankedRiders.map(\.totalKM).max() ?? 1
        let maxSpd  = rankedRiders.map(\.avgSpeed).max() ?? 1
        let maxElev = rankedRiders.map(\.totalElevation).max() ?? 1
        let maxRide = Double(rankedRiders.map(\.totalRides).max() ?? 1)
        return [
            RingMetric(label: "Distance",  
                       value: stats.totalKM, target: maxKM,  color: .accent),
            RingMetric(label: "Speed",     
                       value: stats.avgSpeed, target: maxSpd, color: .dccSaffron),
            RingMetric(label: "Elevation", 
                       value: stats.totalElevation, target: maxElev, color: .dccGreen),
            RingMetric(label: "Rides",     
                       value: Double(stats.totalRides), target: maxRide, color: .dccBlue)
        ]
    }
    
    // Percentile ranking 0.0 to 1.0
    private func percentile(_ value: Double, in values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let pos = sorted.filter { $0 <= value }.count
        return safeDiv(Double(pos), Double(sorted.count))
    }
    
    private func strengthMetrics(stats: MemberStats) -> [PersonalPerformanceMetric] {
        let maxKM   = rankedRiders.map(\.totalKM).max() ?? 1
        let maxSpd  = rankedRiders.map(\.avgSpeed).max() ?? 1
        let maxElev = rankedRiders.map(\.totalElevation).max() ?? 1
        let maxRide = Double(rankedRiders.map(\.totalRides).max() ?? 1)
        let distPct  = percentile(stats.totalKM, in: rankedRiders.map(\.totalKM))
        let spdPct   = percentile(stats.avgSpeed, in: rankedRiders.map(\.avgSpeed))
        let elevPct  = percentile(stats.totalElevation, in: rankedRiders.map(\.totalElevation))
        let ridePct  = percentile(Double(stats.totalRides), 
                                  in: rankedRiders.map { Double($0.totalRides) })
        return [
            PersonalPerformanceMetric(
                label: "Distance",
                message: distPct >= 0.7
                    ? "Top \(Int((1 - distPct) * 100))% of the club"
                    : "+\(String(format: "%.1f", maxKM - stats.totalKM))km to reach the top",
                percentile: distPct
            ),
            PersonalPerformanceMetric(
                label: "Speed",
                message: spdPct >= 0.7
                    ? "Faster than \(Int(spdPct * 100))% of riders"
                    : "+\(String(format: "%.1f", maxSpd - stats.avgSpeed))km/h off the pace",
                percentile: spdPct
            ),
            PersonalPerformanceMetric(
                label: "Elevation",
                message: elevPct >= 0.7
                    ? "One of the top climbers!"
                    : "+\(Int(maxElev - stats.totalElevation))m behind the leader",
                percentile: elevPct
            ),
            PersonalPerformanceMetric(
                label: "Consistency",
                message: ridePct >= 0.7
                    ? "Most consistent rider this week"
                    : "Add \(Int(maxRide) - stats.totalRides) more ride(s) to lead",
                percentile: ridePct
            )
        ]
    }
    
    private func topStrength(stats: MemberStats) -> PersonalPerformanceMetric {
        strengthMetrics(stats: stats).max(by: { $0.percentile < $1.percentile })
            ?? PersonalPerformanceMetric(label: "Riding", message: "Keep it up!", percentile: 0.5)
    }
    
    private func topImprovement(stats: MemberStats) -> PersonalPerformanceMetric {
        strengthMetrics(stats: stats).min(by: { $0.percentile < $1.percentile })
            ?? PersonalPerformanceMetric(label: "Distance", message: "Push further", percentile: 0.3)
    }
    
    // MARK: - Section 2: Compare With
    
    private var section2Compare: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            
            // Section header
            HStack(spacing: 8) {
                Text("⚔️").font(.system(size: 20))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Compare With")
                        .font(.sectionTitle).foregroundColor(.textPrimary)
                    Text("Head-to-head stats against any rider")
                        .font(.labelDefault).foregroundColor(.textSecondary)
                }
            }
            
            // Rider picker — other riders only
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(otherRiders(), id: \.memberName) { rider in
                        let isSelected = selectedCompareRider?.memberName == rider.memberName
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedCompareRider = rider
                            }
                        }) {
                            Text(rider.memberName)
                                .font(.labelDefault)
                                .fontWeight(isSelected ? .bold : .medium)
                                .foregroundColor(isSelected ? .white : .textSecondary)
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .background(Capsule()
                                    .fill(isSelected ? Color.accent : Color.surface))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4).padding(.vertical, 4)
            }
            .sensoryFeedback(.impact(weight: .light), trigger: selectedCompareRider?.memberName)
            
            // Comparison content — appears when rider selected
            if let compareRider = selectedCompareRider, let me = myStats {
                HeadToHeadView(me: me, them: compareRider)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                HStack {
                    Image(systemName: "hand.tap")
                        .foregroundColor(.textSecondary)
                    Text("Tap a rider above to compare stats")
                        .font(.bodyDefault).foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
            }
        }
        .padding(Spacing.md)
        .background(Color.surfaceElevated)
        .cornerRadius(CornerRadius.lg)
        .opacity(showSection2 ? 1 : 0)
        .offset(y: showSection2 ? 0 : 30)
    }
    
    private func otherRiders() -> [MemberStats] {
        // Guard against nil myStats
        guard let myStatsName = myStats?.memberName else {
            // If we can't determine logged-in user, return all riders
            return rankedRiders
        }
        
        // Filter out the logged-in user by name comparison
        return rankedRiders.filter { rider in
            rider.memberName.lowercased().trimmingCharacters(in: .whitespaces) !=
            myStatsName.lowercased().trimmingCharacters(in: .whitespaces)
        }
    }
    
    // MARK: - Section 3: Performance Zones
    
    private var section3Zones: some View {
        PerformanceZonesView(
            allStats: allStats,
            athleteProfile: athleteProfile
        )
        .opacity(showSection3 ? 1 : 0)
        .offset(y: showSection3 ? 0 : 40)
    }
}

// MARK: - Supporting Models

struct PersonalPerformanceMetric: Identifiable {
    let id = UUID()
    let label: String
    let message: String
    let percentile: Double
}

struct RingMetric {
    let label: String
    let value: Double
    let target: Double
    let color: Color
}

// MARK: - Animated Rings View

struct AnimatedRingsView: View {
    let metrics: [RingMetric]
    @State private var progress: Double = 0
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(metrics, id: \.label) { m in
                let pct = m.target == 0 ? 0 : min(m.value / m.target, 1.0)
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .stroke(m.color.opacity(0.2), lineWidth: 7)
                        Circle()
                            .trim(from: 0, to: pct.isFinite ? pct * progress : 0)
                            .stroke(m.color, 
                                    style: StrokeStyle(lineWidth: 7, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(Int((pct * progress * 100).isFinite ? pct * progress * 100 : 0))%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(m.color)
                    }
                    .frame(width: 60, height: 60)
                    Text(m.label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) { progress = 1.0 }
        }
    }
}

// MARK: - Strength Bar Row

struct StrengthBarRow: View {
    let metric: PersonalPerformanceMetric
    @State private var animProgress: Double = 0
    
    private var barColor: Color {
        metric.percentile >= 0.7 ? .dccGreen
            : metric.percentile >= 0.4 ? .dccSaffron : .accent
    }
    private var statusLabel: String {
        metric.percentile >= 0.7 ? "Strength"
            : metric.percentile >= 0.4 ? "On Track" : "Focus Here"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(metric.label)
                    .font(.labelDefault)
                    .foregroundColor(.textPrimary)
                Spacer()
                Text(statusLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(barColor)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(barColor.opacity(0.15))
                    .cornerRadius(CornerRadius.sm)
            }
            Text(metric.message)
                .font(.system(size: 12))
                .foregroundColor(.textSecondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.surface).frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(
                            width: (geo.size.width * metric.percentile * animProgress)
                                .isFinite ? geo.size.width * metric.percentile * animProgress : 0,
                            height: 6
                        )
                }
            }
            .frame(height: 6)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { animProgress = 1.0 }
        }
    }
}

// MARK: - Insight Callout

struct InsightCallout: View {
    enum CalloutType { case strength, improve }
    let type: CalloutType
    let icon: String
    let title: String
    let message: String
    
    private var bg: Color {
        type == .strength ? Color.dccGreen.opacity(0.12) : Color.dccSaffron.opacity(0.12)
    }
    private var border: Color {
        type == .strength ? Color.dccGreen.opacity(0.4) : Color.dccSaffron.opacity(0.4)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(icon).font(.system(size: 13))
                Text(title)
                    .font(.labelDefault).fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
            }
            Text(message)
                .font(.system(size: 12))
                .foregroundColor(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bg)
        .cornerRadius(CornerRadius.md)
        .overlay(RoundedRectangle(cornerRadius: CornerRadius.md).strokeBorder(border, lineWidth: 1))
    }
}

// MARK: - Head To Head View

struct HeadToHeadView: View {
    let me: MemberStats
    let them: MemberStats
    
    var body: some View {
        VStack(spacing: 12) {
            
            // Name header
            HStack {
                Text(me.memberName)
                    .font(.bodyDefault).fontWeight(.bold).foregroundColor(.accent)
                Spacer()
                Text("VS")
                    .font(.labelDefault).foregroundColor(.textSecondary)
                Spacer()
                Text(them.memberName)
                    .font(.bodyDefault).fontWeight(.bold).foregroundColor(.dccSaffron)
            }
            
            Divider().background(Color.surface)
            
            // One row per metric
            DuelBarRow(
                label: "Distance",
                myValue: me.totalKM, theirValue: them.totalKM,
                myFormatted: "\(Int(me.totalKM))km",
                theirFormatted: "\(Int(them.totalKM))km"
            )
            DuelBarRow(
                label: "Avg Speed",
                myValue: me.avgSpeed, theirValue: them.avgSpeed,
                myFormatted: "\(String(format: "%.1f", me.avgSpeed))",
                theirFormatted: "\(String(format: "%.1f", them.avgSpeed))"
            )
            DuelBarRow(
                label: "Elevation",
                myValue: me.totalElevation, theirValue: them.totalElevation,
                myFormatted: "\(Int(me.totalElevation))m",
                theirFormatted: "\(Int(them.totalElevation))m"
            )
            DuelBarRow(
                label: "Rides",
                myValue: Double(me.totalRides), theirValue: Double(them.totalRides),
                myFormatted: "\(me.totalRides)",
                theirFormatted: "\(them.totalRides)"
            )
        }
        .padding(14)
        .background(Color.surface)
        .cornerRadius(12)
    }
}

// MARK: - Duel Bar Row

struct DuelBarRow: View {
    let label: String
    let myValue: Double
    let theirValue: Double
    let myFormatted: String
    let theirFormatted: String
    @State private var animProgress: Double = 0
    
    private var total: Double { myValue + theirValue }
    private var myRatio: Double {
        guard total > 0 else { return 0.5 }
        let r = myValue / total
        return r.isFinite ? r : 0.5
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(myFormatted).font(.labelDefault).fontWeight(.semibold)
                    .foregroundColor(.accent)
                Spacer()
                Text(label).font(.labelDefault).foregroundColor(.textSecondary)
                Spacer()
                Text(theirFormatted).font(.labelDefault).fontWeight(.semibold)
                    .foregroundColor(.dccSaffron)
            }
            GeometryReader { geo in
                HStack(spacing: 2) {
                    let myW = (geo.size.width * myRatio * animProgress)
                    let thW = (geo.size.width * (1 - myRatio) * animProgress)
                    RoundedRectangle(cornerRadius: 3).fill(Color.accent)
                        .frame(
                            width: myW.isFinite && myW >= 0 ? myW : 0,
                            height: 8
                        )
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    RoundedRectangle(cornerRadius: 3).fill(Color.dccSaffron)
                        .frame(
                            width: thW.isFinite && thW >= 0 ? thW : 0,
                            height: 8
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: 8)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { animProgress = 1.0 }
        }
    }
}



// MARK: - Preview

#Preview {
    NavigationStack {
        PersonalInsightsView(
            athleteProfile: AthleteProfile(
                id: 1,
                firstname: "John",
                lastname: "Doe",
                profile: nil,
                city: nil,
                state: nil,
                country: nil
            ),
            allStats: [
                MemberStats(
                    memberName: "John Doe",
                    activities: [
                        Activity(
                            memberName: "John Doe",
                            activityName: "Morning Ride",
                            distance: 45.0,
                            date: Date(),
                            averageSpeed: 24.5,
                            elevationGain: 380,
                            movingTime: 6600
                        ),
                        Activity(
                            memberName: "John Doe",
                            activityName: "Evening Ride",
                            distance: 35.0,
                            date: Date().addingTimeInterval(-86400),
                            averageSpeed: 22.0,
                            elevationGain: 250,
                            movingTime: 5400
                        )
                    ]
                ),
                MemberStats(
                    memberName: "Alice Smith",
                    activities: [
                        Activity(
                            memberName: "Alice Smith",
                            activityName: "Weekend Long Ride",
                            distance: 120.0,
                            date: Date(),
                            averageSpeed: 28.5,
                            elevationGain: 850,
                            movingTime: 15000
                        )
                    ]
                ),
                MemberStats(
                    memberName: "Bob Johnson",
                    activities: [
                        Activity(
                            memberName: "Bob Johnson",
                            activityName: "Hill Climb",
                            distance: 55.0,
                            date: Date(),
                            averageSpeed: 19.5,
                            elevationGain: 920,
                            movingTime: 10000
                        )
                    ]
                )
            ],
            allActivities: []
        )
    }
}

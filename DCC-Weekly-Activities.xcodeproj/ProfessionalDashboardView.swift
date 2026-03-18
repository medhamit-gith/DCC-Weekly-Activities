//
//  ProfessionalDashboardView.swift
//  DCC-Weekly-Activities
//
//  Professional sports app dashboard with hero section and podium leaderboard
//  Design inspired by Strava, Apple Fitness, and Whoop
//

import SwiftUI
import Charts

struct ProfessionalDashboardView: View {
    let stats: [MemberStats]
    let dateRange: DateInterval?
    let athleteProfile: AthleteProfile
    let activities: [Activity]
    
    @State private var selectedTab: DashboardTab = .overview
    @State private var isRefreshing = false
    @State private var animationPhase: CGFloat = 0
    
    enum DashboardTab: String, CaseIterable {
        case overview = "Overview"
        case leaderboard = "Leaderboard"
        case insights = "Insights"
        
        var icon: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .leaderboard: return "list.number"
            case .insights: return "chart.xyaxis.line"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Date Range Header
                        dateHeader
                        
                        // Hero Section - Total Club Distance
                        heroSection
                        
                        // Quick Stats Grid
                        quickStatsGrid
                        
                        // Tab Selector
                        tabSelector
                        
                        // Content based on selected tab
                        switch selectedTab {
                        case .overview:
                            overviewContent
                        case .leaderboard:
                            leaderboardContent
                        case .insights:
                            insightsContent
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.xl)
                }
                .refreshable {
                    await performRefresh()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "figure.outdoor.cycle")
                            .font(.headline)
                            .foregroundStyle(Color.accent)
                        
                        Text("DCC Weekly")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.textPrimary)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    profileButton
                }
            }
        }
    }
    
    // MARK: - Date Header
    
    @ViewBuilder
    private var dateHeader: some View {
        if let range = dateRange {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text("CURRENT WEEK")
                        .font(.labelSmall)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.textSecondary)
                        .tracking(1.2)
                    
                    Text(DateRangeProvider.formatDateRange(range))
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                }
                
                Spacer()
                
                // Week number
                Text("Week \(DateRangeProvider.weekNumber())")
                    .font(.labelDefault)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accent)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(
                        Capsule()
                            .fill(Color.accent.opacity(0.15))
                    )
            }
            .padding(Spacing.md)
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        let totalDistance = stats.reduce(0) { $0 + $1.totalKM }
        
        return VStack(alignment: .leading, spacing: Spacing.md) {
            // Title
            HStack {
                Label("Club Total", systemImage: "figure.2.and.child.holdinghands")
                    .font(.sectionTitle)
                    .foregroundStyle(Color.textPrimary)
                
                Spacer()
                
                // Trend badge (mock data - you can calculate vs previous week)
                TrendBadge(percentage: 12.5, isPositive: true)
            }
            
            // Hero number with animated counter
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                AnimatedCounter(
                    value: totalDistance,
                    duration: 1.8,
                    format: { String(format: "%.1f", $0) }
                )
                .font(.heroStat)
                .fontWeight(.black)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accent, Color.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                Text("km")
                    .font(.sectionTitle)
                    .foregroundStyle(Color.textSecondary)
            }
            
            // Subtitle
            Text("Total distance ridden this week")
                .font(.bodyDefault)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(
            ZStack {
                // Base gradient
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.surface,
                                Color.surfaceElevated
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Accent overlay
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accent.opacity(0.1),
                                Color.accent.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(
                    LinearGradient(
                        colors: [Color.accent.opacity(0.3), Color.accent.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadowStyle(.glow)
    }
    
    // MARK: - Quick Stats Grid
    
    private var quickStatsGrid: some View {
        let totalRides = stats.reduce(0) { $0 + $1.totalRides }
        let totalElevation = stats.reduce(0) { $0 + $1.totalElevation }
        let avgSpeed = stats.reduce(0.0) { $0 + $1.avgSpeed } / Double(max(stats.count, 1))
        let activeMembers = stats.count
        
        return LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: Spacing.sm),
                GridItem(.flexible(), spacing: Spacing.sm)
            ],
            spacing: Spacing.sm
        ) {
            QuickStatCard(
                value: "\(totalRides)",
                unit: "rides",
                label: "Total Rides",
                icon: "flag.checkered",
                color: Color.dccGreen
            )
            
            QuickStatCard(
                value: totalElevation.asElevation,
                unit: "m",
                label: "Elevation",
                icon: "mountain.2.fill",
                color: Color.dccBlue
            )
            
            QuickStatCard(
                value: avgSpeed.asSpeed,
                unit: "km/h",
                label: "Avg Speed",
                icon: "speedometer",
                color: Color.accent
            )
            
            QuickStatCard(
                value: "\(activeMembers)",
                unit: "riders",
                label: "Active",
                icon: "person.3.fill",
                color: Color.dccSaffron
            )
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(DashboardTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab
                        // Haptic feedback
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: tab.icon)
                            .font(.bodyDefault)
                        
                        if selectedTab == tab {
                            Text(tab.rawValue)
                                .font(.bodyDefault)
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundStyle(selectedTab == tab ? Color.textPrimary : Color.textSecondary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        Capsule()
                            .fill(selectedTab == tab ? Color.accent : Color.surface)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.xxs)
        .background(
            Capsule()
                .fill(Color.surfaceElevated)
        )
    }
    
    // MARK: - Overview Content
    
    @ViewBuilder
    private var overviewContent: some View {
        VStack(spacing: Spacing.lg) {
            // Top 3 Podium
            podiumSection
            
            // Performance insights
            performanceHighlight
        }
    }
    
    // MARK: - Leaderboard Content
    
    @ViewBuilder
    private var leaderboardContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Text("Full Rankings")
                    .font(.sectionTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.textPrimary)
                
                Spacer()
                
                Text("\(stats.count) riders")
                    .font(.labelDefault)
                    .foregroundStyle(Color.textSecondary)
            }
            
            // Top 3 Podium (compact)
            HStack(alignment: .top, spacing: Spacing.sm) {
                if stats.count >= 3 {
                    let topThree = Array(stats.sorted { $0.totalKM > $1.totalKM }.prefix(3))
                    
                    // 2nd place
                    RiderPodiumCard(rank: 2, rider: topThree[1])
                        .offset(y: Spacing.md)
                    
                    // 1st place (center, elevated)
                    RiderPodiumCard(rank: 1, rider: topThree[0])
                    
                    // 3rd place
                    RiderPodiumCard(rank: 3, rider: topThree[2])
                        .offset(y: Spacing.md)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, Spacing.md)
            
            // Positions 4+
            if stats.count > 3 {
                Text("Other Riders")
                    .font(.cardTitle)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                    .padding(.top, Spacing.sm)
                
                LazyVStack(spacing: Spacing.xs) {
                    ForEach(Array(stats.sorted { $0.totalKM > $1.totalKM }.enumerated()), id: \.element.id) { index, rider in
                        if index >= 3 {
                            RiderPodiumCard(rank: index + 1, rider: rider, isCompact: true)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Insights Content
    
    @ViewBuilder
    private var insightsContent: some View {
        VStack(spacing: Spacing.lg) {
            Text("Insights Coming Soon")
                .font(.sectionTitle)
                .foregroundStyle(Color.textSecondary)
        }
    }
    
    // MARK: - Podium Section
    
    private var podiumSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Top Performers")
                .font(.sectionTitle)
                .fontWeight(.bold)
                .foregroundStyle(Color.textPrimary)
            
            if stats.count >= 3 {
                let topThree = Array(stats.sorted { $0.totalKM > $1.totalKM }.prefix(3))
                
                HStack(alignment: .top, spacing: Spacing.sm) {
                    // 2nd place
                    RiderPodiumCard(rank: 2, rider: topThree[1])
                        .offset(y: Spacing.md)
                    
                    // 1st place (center, elevated)
                    RiderPodiumCard(rank: 1, rider: topThree[0])
                    
                    // 3rd place
                    RiderPodiumCard(rank: 3, rider: topThree[2])
                        .offset(y: Spacing.md)
                }
                .frame(maxWidth: .infinity)
            } else {
                EmptyStateView(
                    icon: "figure.outdoor.cycle",
                    title: "No riders yet",
                    message: "Check back after some activities are logged this week"
                )
                .frame(height: 200)
            }
        }
    }
    
    // MARK: - Performance Highlight
    
    private var performanceHighlight: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Best Ride of the Week")
                .font(.sectionTitle)
                .fontWeight(.bold)
                .foregroundStyle(Color.textPrimary)
            
            if let bestRide = activities.max(by: { $0.distance < $1.distance }) {
                BestRideCard(activity: bestRide)
            } else {
                EmptyStateView(
                    icon: "bicycle",
                    title: "No rides yet",
                    message: "The week's best ride will appear here"
                )
                .frame(height: 150)
            }
        }
    }
    
    // MARK: - Profile Button
    
    private var profileButton: some View {
        Button {
            // Handle profile tap
        } label: {
            ZStack {
                Circle()
                    .fill(Color.surfaceElevated)
                    .frame(width: 36, height: 36)
                
                Text(String(athleteProfile.firstName.prefix(1)))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
            }
        }
    }
    
    // MARK: - Actions
    
    private func performRefresh() async {
        isRefreshing = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isRefreshing = false
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Quick Stat Card

struct QuickStatCard: View {
    let value: String
    let unit: String
    let label: String
    let icon: String
    let color: Color
    
    @State private var isAnimated = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                
                Spacer()
            }
            
            Spacer()
            
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
                Text(value)
                    .font(.mediumStat)
                    .fontWeight(.black)
                    .monospacedDigit()
                    .foregroundStyle(Color.textPrimary)
                
                Text(unit)
                    .font(.labelSmall)
                    .foregroundStyle(Color.textSecondary)
            }
            
            Text(label)
                .font(.labelSmall)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(Spacing.md)
        .frame(height: 120)
        .background(Color.surface)
        .cornerRadius(CornerRadius.lg)
        .scaleEffect(isAnimated ? 1 : 0.9)
        .opacity(isAnimated ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                isAnimated = true
            }
        }
    }
}

// MARK: - Best Ride Card

struct BestRideCard: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Activity type icon
            ZStack {
                Circle()
                    .fill(Color.accent.opacity(0.2))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "bicycle")
                    .font(.title2)
                    .foregroundStyle(Color.accent)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(activity.activityName)
                    .font(.cardTitle)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                
                Text(activity.memberName)
                    .font(.bodyDefault)
                    .foregroundStyle(Color.textSecondary)
                
                HStack(spacing: Spacing.sm) {
                    Label(activity.distance.asDistance + " km", systemImage: "arrow.left.and.right")
                        .font(.labelDefault)
                        .foregroundStyle(Color.textSecondary)
                    
                    Label(activity.averageSpeed.asSpeed + " km/h", systemImage: "speedometer")
                        .font(.labelDefault)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            
            Spacer()
            
            // Trophy
            Image(systemName: "trophy.fill")
                .font(.title)
                .foregroundStyle(Color(hex: "#FFD700"))
        }
        .padding(Spacing.md)
        .background(Color.surface)
        .cornerRadius(CornerRadius.lg)
    }
}

#Preview {
    // Mock data for preview
    let mockStats = [
        MemberStats(memberName: "Amit K", activities: []),
        MemberStats(memberName: "John D", activities: []),
        MemberStats(memberName: "Sara M", activities: [])
    ]
    
    let mockProfile = AthleteProfile(
        id: 1,
        username: "rider123",
        firstName: "Test",
        lastName: "Rider",
        profile: "https://example.com"
    )
    
    ProfessionalDashboardView(
        stats: mockStats,
        dateRange: DateRangeProvider.getCurrentWeek(),
        athleteProfile: mockProfile,
        activities: []
    )
    .preferredColorScheme(.dark)
}

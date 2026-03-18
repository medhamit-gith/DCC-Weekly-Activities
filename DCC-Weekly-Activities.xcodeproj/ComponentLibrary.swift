//
//  ComponentLibrary.swift
//  DCC-Weekly-Activities
//
//  Reusable UI components for professional sports app design
//

import SwiftUI
import Charts

// MARK: - Animated Counter

struct AnimatedCounter: View {
    let value: Double
    let duration: Double
    let format: (Double) -> String
    
    @State private var displayValue: Double = 0
    
    init(
        value: Double,
        duration: Double = 1.0,
        format: @escaping (Double) -> String = { String(format: "%.0f", $0) }
    ) {
        self.value = value
        self.duration = duration
        self.format = format
    }
    
    var body: some View {
        Text(format(displayValue))
            .monospacedDigit()
            .onAppear {
                withAnimation(.easeOut(duration: duration)) {
                    displayValue = value
                }
            }
            .onChange(of: value) { oldValue, newValue in
                withAnimation(.easeOut(duration: duration / 2)) {
                    displayValue = newValue
                }
            }
    }
}

// MARK: - Trend Badge

struct TrendBadge: View {
    let percentage: Double
    let isPositive: Bool
    
    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.labelSmall)
            
            Text(abs(percentage).asPercentage)
                .font(.labelDefault)
                .fontWeight(.semibold)
        }
        .foregroundStyle(isPositive ? Color.success : Color.error)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(
            Capsule()
                .fill((isPositive ? Color.success : Color.error).opacity(0.15))
        )
    }
}

// MARK: - Performance Badge

enum BadgeType {
    case hotStreak
    case mostImproved
    case clubLeader
    case consistent
    
    var emoji: String {
        switch self {
        case .hotStreak: return "🔥"
        case .mostImproved: return "⚡"
        case .clubLeader: return "👑"
        case .consistent: return "💪"
        }
    }
    
    var title: String {
        switch self {
        case .hotStreak: return "Hot Streak"
        case .mostImproved: return "Most Improved"
        case .clubLeader: return "Club Leader"
        case .consistent: return "Consistent"
        }
    }
    
    var color: Color {
        switch self {
        case .hotStreak: return .accent
        case .mostImproved: return .success
        case .clubLeader: return Color(hex: "#FFD700")
        case .consistent: return .dccBlue
        }
    }
}

struct PerformanceBadge: View {
    let type: BadgeType
    
    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Text(type.emoji)
                .font(.caption)
            
            Text(type.title)
                .font(.labelSmall)
                .fontWeight(.semibold)
        }
        .foregroundStyle(type.color)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(
            Capsule()
                .fill(type.color.opacity(0.15))
        )
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let trend: Double?
    let icon: String
    let accentColor: Color
    let sparklineData: [Double]?
    
    init(
        title: String,
        value: String,
        unit: String,
        trend: Double? = nil,
        icon: String,
        accentColor: Color = .accent,
        sparklineData: [Double]? = nil
    ) {
        self.title = title
        self.value = value
        self.unit = unit
        self.trend = trend
        self.icon = icon
        self.accentColor = accentColor
        self.sparklineData = sparklineData
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Header with icon
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(accentColor)
                
                Spacer()
                
                if let trend = trend {
                    TrendBadge(percentage: trend, isPositive: trend >= 0)
                }
            }
            
            Spacer()
            
            // Value
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
                Text(value)
                    .font(.mediumStat)
                    .fontWeight(.black)
                    .monospacedDigit()
                    .foregroundStyle(Color.textPrimary)
                
                Text(unit)
                    .font(.labelDefault)
                    .foregroundStyle(Color.textSecondary)
            }
            
            // Title
            Text(title)
                .font(.labelDefault)
                .foregroundStyle(Color.textSecondary)
            
            // Optional sparkline
            if let data = sparklineData, !data.isEmpty {
                MiniSparkline(data: data, accentColor: accentColor)
                    .frame(height: 24)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Color.surface)
        .cornerRadius(CornerRadius.lg)
        .shadowStyle(.soft)
    }
}

// MARK: - Mini Sparkline

struct MiniSparkline: View {
    let data: [Double]
    let accentColor: Color
    
    var body: some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [accentColor.opacity(0.3), accentColor.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: data.min()! * 0.9...data.max()! * 1.1)
    }
}

// MARK: - Podium Card

struct RiderPodiumCard: View {
    let rank: Int
    let rider: MemberStats
    let isCompact: Bool
    
    init(rank: Int, rider: MemberStats, isCompact: Bool = false) {
        self.rank = rank
        self.rider = rider
        self.isCompact = isCompact
    }
    
    var podiumGradient: LinearGradient {
        switch rank {
        case 1: return Color.goldGradient()
        case 2: return Color.silverGradient()
        case 3: return Color.bronzeGradient()
        default: return LinearGradient(colors: [.surface], startPoint: .top, endPoint: .bottom)
        }
    }
    
    var rankColor: Color {
        switch rank {
        case 1: return Color(hex: "#FFD700")
        case 2: return Color(hex: "#C0C0C0")
        case 3: return Color(hex: "#CD7F32")
        default: return Color.textSecondary
        }
    }
    
    var body: some View {
        if isCompact {
            compactCard
        } else {
            podiumCard
        }
    }
    
    @ViewBuilder
    private var podiumCard: some View {
        VStack(spacing: Spacing.sm) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(podiumGradient)
                    .frame(width: 56, height: 56)
                    .shadowStyle(.medium)
                
                Text("\(rank)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            // Avatar placeholder
            ZStack {
                Circle()
                    .fill(Color.surfaceElevated)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle()
                            .stroke(podiumGradient, lineWidth: 3)
                    )
                
                Text(String(rider.memberName.prefix(1)))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
            }
            
            // Name
            Text(rider.memberName)
                .font(.cardTitle)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            // Main stat - Distance
            VStack(spacing: Spacing.xxxs) {
                Text(rider.totalKM.asDistance)
                    .font(.largeStat)
                    .fontWeight(.black)
                    .monospacedDigit()
                    .foregroundStyle(rankColor)
                
                Text("km")
                    .font(.labelDefault)
                    .foregroundStyle(Color.textSecondary)
            }
            
            Divider()
                .background(Color.textSecondary.opacity(0.2))
            
            // Secondary stats
            HStack(spacing: Spacing.md) {
                VStack(spacing: Spacing.xxxs) {
                    Image(systemName: "mountain.2.fill")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    
                    Text(rider.totalElevation.asElevation)
                        .font(.labelLarge)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .foregroundStyle(Color.textPrimary)
                    
                    Text("m")
                        .font(.captionSmall)
                        .foregroundStyle(Color.textSecondary)
                }
                
                VStack(spacing: Spacing.xxxs) {
                    Image(systemName: "flag.checkered")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    
                    Text("\(rider.totalRides)")
                        .font(.labelLarge)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .foregroundStyle(Color.textPrimary)
                    
                    Text("rides")
                        .font(.captionSmall)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .padding(Spacing.md)
        .frame(width: 160)
        .background(Color.surface)
        .cornerRadius(CornerRadius.xl)
        .shadowStyle(.medium)
    }
    
    @ViewBuilder
    private var compactCard: some View {
        HStack(spacing: Spacing.sm) {
            // Rank
            Text("\(rank)")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(rank <= 3 ? rankColor : Color.textSecondary)
                .frame(width: 32)
            
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.surfaceElevated)
                    .frame(width: 40, height: 40)
                
                Text(String(rider.memberName.prefix(1)))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
            }
            
            // Name
            Text(rider.memberName)
                .font(.bodyDefault)
                .fontWeight(.medium)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
            
            Spacer()
            
            // Distance bar indicator
            HStack(spacing: Spacing.xxs) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .fill(Color.surfaceElevated)
                            .frame(height: 8)
                        
                        // Progress (relative to top performer)
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .fill(Color.accent)
                            .frame(width: geometry.size.width, height: 8)
                    }
                }
                .frame(width: 60, height: 8)
                
                Text(rider.totalKM.asDistance)
                    .font(.labelLarge)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 50, alignment: .trailing)
            }
        }
        .padding(Spacing.sm)
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Hero Stat Card

struct HeroStatCard: View {
    let title: String
    let value: Double
    let unit: String
    let trend: Double?
    let icon: String
    
    @State private var isAnimated = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Label(title, systemImage: icon)
                    .font(.sectionTitle)
                    .foregroundStyle(Color.textPrimary)
                
                Spacer()
                
                if let trend = trend {
                    TrendBadge(percentage: trend, isPositive: trend >= 0)
                }
            }
            
            // Hero number
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                AnimatedCounter(
                    value: value,
                    duration: 1.5,
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
                
                Text(unit)
                    .font(.sectionTitle)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(
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
        .scaleEffect(isAnimated ? 1 : 0.95)
        .opacity(isAnimated ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimated = true
            }
        }
    }
}

// MARK: - Skeleton Loading View

struct SkeletonCard: View {
    let height: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: CornerRadius.lg)
            .fill(Color.surface)
            .frame(height: height)
            .shimmer()
    }
}


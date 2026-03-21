//
//  ChartHelpTooltip.swift
//  DCC-Weekly-Activities
//
//  Help tooltip system for analysis charts — provides context and interpretation guidance
//

import SwiftUI

// MARK: - Chart Help Content Model

struct ChartHelpContent {
    let title: String
    let whatItShows: String
    let whyItMatters: String
    let howToRead: String
    let proTip: String?
    
    // MARK: - Predefined content for each chart type
    
    static let distanceBar = ChartHelpContent(
        title: "Weekly Distance Chart",
        whatItShows: "Horizontal bars showing total distance ridden by each club member this week, sorted by distance.",
        whyItMatters: "Distance is the primary measure of riding volume. More km ridden generally builds fitness, and this chart shows exactly where you stand relative to every other club member.",
        howToRead: "Your bar is highlighted in the club accent color. Longer bar = more km. The number at the end of each bar shows the exact km ridden. The gap between your bar and the top bar is your distance target to reach #1.",
        proTip: "Focus on the gap to the rider just above you — closing one position at a time is more achievable than targeting the leader directly."
    )
    
    static let speedElevation = ChartHelpContent(
        title: "Speed vs Climbing Profile",
        whatItShows: "A scatter plot comparing average speed (horizontal axis) against total elevation gained (vertical axis). Each dot represents one club member. Dot size reflects total distance ridden.",
        whyItMatters: "This reveals your riding style and fitness profile. Fast riders who also climb well have the highest all-round fitness. It tells you whether you're a flat-road sprinter, a mountain climber, or a balanced rider.",
        howToRead: "Your dot is highlighted. The four quadrants classify riders: Fast & Flat (right, bottom), Fast & Climbing (right, top), Steady Climber (left, top), Endurance Base (left, bottom). The bigger the dot, the more total km ridden.",
        proTip: "If you're in the bottom-left quadrant, focus on one axis at a time — add one hilly route per week to move upward, or target pace intervals to move rightward."
    )
    
    static let radar = ChartHelpContent(
        title: "Performance Profile Radar",
        whatItShows: "A spider/radar chart with 5 axes — Distance, Speed, Elevation, Consistency, and Efficiency — showing your performance relative to the club maximum on each dimension.",
        whyItMatters: "This is your cycling fingerprint. It instantly reveals whether you're a well-rounded rider or have specific strengths and weaknesses. A larger filled area means better overall performance.",
        howToRead: "Your shape is filled in the accent color. The dashed outline is the club average. Each axis goes from 0 (center) to 100% (outer edge) of the club maximum. Where your shape dips inside the club average is your biggest opportunity for improvement.",
        proTip: "The most balanced riders have the most symmetrical shapes. Identify your shallowest axis — that's where targeted training has the biggest return on investment."
    )
    
    static let sportBreakdown = ChartHelpContent(
        title: "Ride Type Breakdown",
        whatItShows: "A breakdown of your rides by sport type — Road, Gravel, Mountain Bike, Virtual, or E-Bike — showing the mix of riding styles in your week.",
        whyItMatters: "Different ride types build different fitness. Road rides build speed, mountain biking builds technical skill and strength, gravel balances both. Understanding your mix helps explain your performance profile.",
        howToRead: "Each segment represents a sport type as a percentage of your total rides. Larger segments = more rides of that type.",
        proTip: nil
    )
    
    static let efficiencyTimeline = ChartHelpContent(
        title: "Efficiency Score",
        whatItShows: "Your speed-to-climbing ratio — how fast you ride relative to the elevation you tackle. Higher scores mean you generate more speed per metre of climbing.",
        whyItMatters: "Efficiency separates fit riders from simply high-volume riders. A low efficiency score means elevation is slowing you down significantly — improving climbing fitness will raise your speed without extra volume.",
        howToRead: "Higher bars = better efficiency. Compare your bar to the club leader to see the gap. This metric rewards riders who climb fast, not just riders who avoid hills.",
        proTip: "The most efficient climbers use a steady, sustainable power output rather than explosive efforts. Consistent cadence on hills builds this metric."
    )
    
    static let coachingTips = ChartHelpContent(
        title: "Personalised Coaching Tips",
        whatItShows: "AI-generated tips based on your gap analysis compared to the club leader across all 5 performance metrics.",
        whyItMatters: "Generic training advice is less effective than advice targeted to your specific weakness. These tips identify where you can gain the most ground with the least effort.",
        howToRead: "The badge shows your exact gap in km, km/h, or metres of elevation. The what-if scenario shows your projected result if you follow the tip this week.",
        proTip: "The tip targeting your weakest metric gives the highest return. But the strength tip reminds you what's already working — don't abandon your strengths while fixing weaknesses."
    )
}

// MARK: - Tooltip View Component

struct ChartHelpButton: View {
    let content: ChartHelpContent
    @State private var isShowingTooltip = false
    
    @State private var hapticTrigger = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isShowingTooltip = true
            }
            hapticTrigger.toggle()
        }) {
            Image(systemName: "info.circle")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary.opacity(0.7))
                .padding(6)
                .background(Circle().fill(Color.white.opacity(0.05)))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .sheet(isPresented: $isShowingTooltip) {
            ChartHelpSheet(content: content, isPresented: $isShowingTooltip)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
        }
    }
}

// MARK: - Help Sheet View

struct ChartHelpSheet: View {
    let content: ChartHelpContent
    @Binding var isPresented: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(content.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text("Chart Guide")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)
                
                Divider().background(Color.white.opacity(0.1))
                
                // What it shows
                HelpSection(
                    icon: "eye",
                    iconColor: .blue,
                    title: "What this shows",
                    bodyText: content.whatItShows
                )
                
                // Why it matters
                HelpSection(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: Color.accent,
                    title: "Why it matters",
                    bodyText: content.whyItMatters
                )
                
                // How to read it
                HelpSection(
                    icon: "hand.point.up.left",
                    iconColor: .green,
                    title: "How to read it",
                    bodyText: content.howToRead
                )
                
                // Pro tip (if available)
                if let tip = content.proTip {
                    HStack(alignment: .top, spacing: 12) {
                        Text("💡")
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Pro Tip")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.accent)
                            Text(tip)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accent.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.accent.opacity(0.25), lineWidth: 1)
                            )
                    )
                }
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Reusable Help Section

private struct HelpSection: View {
    let icon: String
    let iconColor: Color
    let title: String
    let bodyText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
            Text(bodyText)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
    }
}

// MARK: - Preview

#Preview("Distance Bar Help") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        VStack {
            ChartHelpButton(content: .distanceBar)
                .padding()
        }
    }
}

#Preview("Help Sheet") {
    ChartHelpSheet(
        content: .radar,
        isPresented: .constant(true)
    )
}

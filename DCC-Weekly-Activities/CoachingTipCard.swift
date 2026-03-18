//
//  CoachingTipCard.swift
//  DCC-Weekly-Activities
//
//  Smart tip cards with gap analysis and what-if scenarios
//  Updated 2026-03-02: Added what-if scenario display and chart help button
//
//  Dependencies:
//  - WhatIfEngine.swift: CoachingTip, WhatIfResult
//  - ChartHelpTooltip.swift: ChartHelpButton, ChartHelpContent
//  - DesignSystem.swift: Color, Spacing, CornerRadius extensions
//

import SwiftUI
import Foundation

struct CoachingTipCard: View {
    let tip: CoachingTip
    let index: Int
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Left accent border
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.accent)
                .frame(width: 4)
            
            // Icon
            Text(tip.icon)
                .font(.system(size: 28))
            
            // Content
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(tip.headline)
                        .font(.cardTitle)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                    
                    Spacer()
                    
                    if let gap = tip.gapBadge {
                        Text(gap)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.error)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.error.opacity(0.15))
                            )
                    }
                }
                
                Text(tip.detail)
                    .font(.bodyDefault)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                // What-if scenario section (NEW)
                if let whatIf = tip.whatIf {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("WHAT IF?")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(1.5)
                        
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .foregroundColor(Color.accent)
                                .font(.system(size: 13))
                            Text(whatIf.scenario)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            Text("+\(String(format: "%.0f", whatIf.distanceGain))km")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.accent.opacity(0.15)))
                        }
                    }
                    .padding(.top, 8)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accent.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.accent.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.surfaceElevated)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.accent.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            let delay = Double(index) * 0.1
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isVisible = true
                }
            }
        }
    }
}

struct CoachingTipsSection: View {
    let tips: [CoachingTip]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Label("Smart Coaching Tips", systemImage: "lightbulb.fill")
                    .font(.cardTitle)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                ChartHelpButton(content: ChartHelpContent.coachingTips)
            }
            
            VStack(spacing: Spacing.sm) {
                ForEach(Array(tips.enumerated()), id: \.element.id) { index, tip in
                    CoachingTipCard(tip: tip, index: index)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.surface)
        .cornerRadius(CornerRadius.lg)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        ScrollView {
            CoachingTipsSection(
                tips: [
                    CoachingTip(
                        icon: "📏",
                        type: CoachingTip.TipType.distance,
                        headline: "Close the Distance Gap",
                        detail: "Add one longer ride to close the 23.5km gap with Alice",
                        gapBadge: "-23.5km",
                        whatIf: WhatIfResult(
                            scenario: "If you ride 2 more times this week",
                            projectedDistance: 145.0,
                            distanceGain: 45.0,
                            newRank: 3
                        )
                    ),
                    CoachingTip(
                        icon: "⛰",
                        type: CoachingTip.TipType.elevation,
                        headline: "Target Hillier Routes",
                        detail: "You're 340m behind Alice on elevation",
                        gapBadge: "-340m",
                        whatIf: nil as WhatIfResult?
                    )
                ]
            )
            .padding()
        }
    }
}

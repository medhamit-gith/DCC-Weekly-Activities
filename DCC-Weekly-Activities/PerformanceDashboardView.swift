//
//  PerformanceDashboardView.swift
//  Created on 2026-03-05
//

import SwiftUI

// MARK: - PerfMiniStat

struct PerfMiniStat: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.35))
        }
    }
}

// MARK: - PerfCounterText

struct PerfCounterText: View {
    let target: Int
    let suffix: String
    let font: Font
    let color: Color
    
    @State private var displayed: Int = 0
    
    var body: some View {
        Text("\(displayed)\(suffix)")
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText())
            .onAppear {
                withAnimation(.easeOut(duration: 0.9)) {
                    displayed = target
                }
            }
            .onChange(of: target) { oldValue, newValue in
                withAnimation(.easeOut(duration: 0.5)) {
                    displayed = newValue
                }
            }
    }
}

// MARK: - PerfTimelineRow

struct PerfTimelineRow: View {
    let event: PerformanceEvent
    let index: Int
    let animate: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.category.icon)
                .font(.system(size: 14))
                .foregroundStyle(event.category.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                
                if let detail = event.detail {
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(event.formattedDuration)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(event.rating.color)
                
                Text(event.rating.dot)
                    .font(.system(size: 10))
                    .foregroundStyle(event.rating.color)
            }
        }
        .padding(.vertical, 6)
        .opacity(animate ? 1 : 0)
        .offset(x: animate ? 0 : 20)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.75)
                .delay(Double(index) * 0.05),
            value: animate
        )
    }
}

// MARK: - PerfCategoryCard

struct PerfCategoryCard: View {
    let category: PerformanceCategory
    let events: [PerformanceEvent]
    let avgMs: Double
    
    @State private var barProgress: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(category.color)
                
                Text(category.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                if let latestEvent = events.last {
                    Text(latestEvent.rating.dot)
                        .font(.system(size: 14))
                        .foregroundStyle(latestEvent.rating.color)
                }
            }
            
            if events.isEmpty {
                Text("No data yet")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                PerfCounterText(
                    target: Int(avgMs),
                    suffix: " ms",
                    font: .system(size: 20, weight: .bold, design: .monospaced),
                    color: .white
                )
                
                HStack(spacing: 4) {
                    ForEach(events.suffix(5).indices, id: \.self) { idx in
                        if let event = events.suffix(5)[safe: idx] {
                            let maxDuration = events.suffix(5).map(\.durationMs).max() ?? 1
                            let ratio = event.durationMs / maxDuration
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(event.success ? category.color : .red)
                                .frame(width: 9, height: 36 * ratio * barProgress)
                        }
                    }
                }
                .frame(height: 36, alignment: .bottom)
                .onAppear {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                        barProgress = 1.0
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(category.color.opacity(0.09))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(category.color.opacity(0.22), lineWidth: 1)
                )
        )
    }
}

// MARK: - PerfGlassCard

struct PerfGlassCard<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(.white.opacity(0.11), lineWidth: 1)
                    )
            )
    }
}

// MARK: - PerformanceDashboardView

struct PerformanceDashboardView: View {
    @ObservedObject var logger: PerformanceLogger
    let userName: String
    @Binding var isPresented: Bool
    
    @State private var showHeader = false
    @State private var showScore = false
    @State private var showCategory1 = false
    @State private var showCategory2 = false
    @State private var showCategory3 = false
    @State private var showCategory4 = false
    @State private var showTimeline = false
    @State private var clearHaptic = false
    
    var body: some View {
        ZStack {
            // Background dismissal
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Ambient orbs
            ambientOrbs
            
            // Main content
            ScrollView {
                VStack(spacing: 18) {
                    headerSection
                    healthSection
                    categoryGrid
                    timelineSection
                    clearButton
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 52)
            }
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .padding(.horizontal, 14)
            .padding(.vertical, 52)
        }
        .onAppear {
            animateAppearance()
        }
    }
    
    // MARK: - Ambient Orbs
    
    private var ambientOrbs: some View {
        ZStack {
            Circle()
                .fill(.blue.opacity(0.3))
                .blur(radius: 80)
                .frame(width: 200, height: 200)
                .offset(x: -100, y: -150)
            
            Circle()
                .fill(.purple.opacity(0.25))
                .blur(radius: 90)
                .frame(width: 250, height: 250)
                .offset(x: 120, y: 200)
            
            Circle()
                .fill(.orange.opacity(0.2))
                .blur(radius: 70)
                .frame(width: 180, height: 180)
                .offset(x: -80, y: 300)
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Performance")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Session · \(userName)")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.45))
            }
            
            Spacer()
            
            Text(sessionDurationText)
                .font(.system(size: 20, weight: .regular, design: .monospaced))
                .foregroundStyle(.white)
            
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(.white.opacity(0.1)))
            }
        }
        .opacity(showHeader ? 1 : 0)
        .offset(y: showHeader ? 0 : -20)
    }
    
    // MARK: - Health Section
    
    private var healthSection: some View {
        PerfGlassCard {
            HStack(spacing: 20) {
                // Health ring
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.08), lineWidth: 9)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(logger.healthScore) / 100.0)
                        .stroke(
                            AngularGradient(
                                colors: [logger.healthColor, logger.healthColor.opacity(0.5)],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 9, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8, dampingFraction: 0.75), value: logger.healthScore)
                    
                    PerfCounterText(
                        target: logger.healthScore,
                        suffix: "/100",
                        font: .system(size: 20, weight: .bold, design: .monospaced),
                        color: .white
                    )
                }
                .frame(width: 78, height: 78)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("App Health")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                    
                    Text(logger.healthLabel)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(logger.healthColor)
                    
                    HStack(spacing: 16) {
                        PerfMiniStat(
                            label: "EVENTS",
                            value: "\(logger.events.count)",
                            color: .white
                        )
                        
                        if let slowest = logger.slowestEvent {
                            PerfMiniStat(
                                label: "SLOWEST",
                                value: slowest.formattedDuration,
                                color: .red
                            )
                        }
                    }
                }
            }
        }
        .opacity(showScore ? 1 : 0)
        .scaleEffect(showScore ? 1 : 0.93)
    }
    
    // MARK: - Category Grid
    
    private var categoryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(Array(PerformanceCategory.allCases.enumerated()), id: \.element) { index, category in
                let categoryEvents = logger.eventsByCategory[category] ?? []
                let avgMs = logger.averageDuration(for: category) ?? 0
                
                PerfCategoryCard(
                    category: category,
                    events: categoryEvents,
                    avgMs: avgMs
                )
                .opacity(showStateForCategory(index) ? 1 : 0)
                .offset(y: showStateForCategory(index) ? 0 : 22)
            }
        }
    }
    
    // MARK: - Timeline Section
    
    private var timelineSection: some View {
        PerfGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Recent Events")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text("\(logger.events.count)")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                if logger.events.isEmpty {
                    Text("No events recorded yet")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else {
                    VStack(spacing: 4) {
                        ForEach(Array(logger.events.suffix(8).reversed().enumerated()), id: \.element.id) { index, event in
                            PerfTimelineRow(event: event, index: index, animate: showTimeline)
                        }
                    }
                }
            }
        }
        .opacity(showTimeline ? 1 : 0)
        .offset(y: showTimeline ? 0 : 28)
    }
    
    // MARK: - Clear Button
    
    private var clearButton: some View {
        Button {
            clearHaptic.toggle()
            logger.clearSession()
        } label: {
            Text("Clear Session Data")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.05))
                )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: clearHaptic)
    }
    
    // MARK: - Helpers
    
    private var sessionDurationText: String {
        let seconds = Int(logger.sessionDurationSeconds)
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, remainingSeconds)
        } else {
            return String(format: "0:%02d", remainingSeconds)
        }
    }
    
    private func showStateForCategory(_ index: Int) -> Bool {
        switch index {
        case 0: return showCategory1
        case 1: return showCategory2
        case 2: return showCategory3
        case 3: return showCategory4
        default: return false
        }
    }
    
    private func animateAppearance() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.05)) {
            showHeader = true
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.15)) {
            showScore = true
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.30)) {
            showCategory1 = true
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.38)) {
            showCategory2 = true
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.46)) {
            showCategory3 = true
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.54)) {
            showCategory4 = true
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.65)) {
            showTimeline = true
        }
    }
}

// MARK: - Array Safe Index Extension

private extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

//
//  PerformanceLogger.swift
//  Created on 2026-03-05
//

import SwiftUI
import Combine

// MARK: - PerformanceCategory

enum PerformanceCategory: String, CaseIterable, Codable, Identifiable {
    case appLaunch
    case apiCall
    case screenLoad
    case viewRender
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .appLaunch:
            return "bolt.circle.fill"
        case .apiCall:
            return "network"
        case .screenLoad:
            return "rectangle.on.rectangle"
        case .viewRender:
            return "paintbrush.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .appLaunch:
            return .blue
        case .apiCall:
            return .purple
        case .screenLoad:
            return .orange
        case .viewRender:
            return .green
        }
    }
    
    var thresholds: (excellent: Double, good: Double, fair: Double) {
        switch self {
        case .appLaunch:
            return (excellent: 1000, good: 2500, fair: 5000)
        case .apiCall:
            return (excellent: 500, good: 1500, fair: 3000)
        case .screenLoad:
            return (excellent: 100, good: 300, fair: 600)
        case .viewRender:
            return (excellent: 50, good: 150, fair: 300)
        }
    }
}

// MARK: - PerformanceRating

enum PerformanceRating: String, Codable {
    case excellent
    case good
    case fair
    case slow
    
    var color: Color {
        switch self {
        case .excellent:
            return .green
        case .good:
            return .blue
        case .fair:
            return .orange
        case .slow:
            return .red
        }
    }
    
    var dot: String {
        switch self {
        case .excellent:
            return "●"
        case .good:
            return "●"
        case .fair:
            return "●"
        case .slow:
            return "●"
        }
    }
}

// MARK: - PerformanceEvent

struct PerformanceEvent: Identifiable, Codable {
    let id: UUID
    let category: PerformanceCategory
    let label: String
    let durationMs: Double
    let timestamp: Date
    let success: Bool
    let detail: String?
    
    var formattedDuration: String {
        if durationMs < 1000 {
            return String(format: "%.0f ms", durationMs)
        } else {
            let seconds = durationMs / 1000.0
            return String(format: "%.2f s", seconds)
        }
    }
    
    var rating: PerformanceRating {
        let thresholds = category.thresholds
        
        if durationMs <= thresholds.excellent {
            return .excellent
        } else if durationMs <= thresholds.good {
            return .good
        } else if durationMs <= thresholds.fair {
            return .fair
        } else {
            return .slow
        }
    }
}

// MARK: - PerfTimerToken

struct PerfTimerToken {
    let label: String
    let category: PerformanceCategory
    let startTime: Date
}

// MARK: - PerformanceLogger

@MainActor
final class PerformanceLogger: ObservableObject {
    static let shared = PerformanceLogger()
    
    @Published private(set) var events: [PerformanceEvent] = []
    @Published private(set) var sessionStartTime: Date
    
    private init() {
        self.sessionStartTime = Date()
    }
    
    // MARK: - Timing Methods
    
    func start(label: String, category: PerformanceCategory) -> PerfTimerToken {
        return PerfTimerToken(
            label: label,
            category: category,
            startTime: Date()
        )
    }
    
    @discardableResult
    func stop(token: PerfTimerToken, success: Bool = true, detail: String? = nil) -> PerformanceEvent {
        let endTime = Date()
        let durationMs = endTime.timeIntervalSince(token.startTime) * 1000.0
        
        let event = PerformanceEvent(
            id: UUID(),
            category: token.category,
            label: token.label,
            durationMs: durationMs,
            timestamp: endTime,
            success: success,
            detail: detail
        )
        
        append(event)
        return event
    }
    
    func logInstant(
        label: String,
        category: PerformanceCategory,
        durationMs: Double,
        success: Bool = true,
        detail: String? = nil
    ) {
        let event = PerformanceEvent(
            id: UUID(),
            category: category,
            label: label,
            durationMs: durationMs,
            timestamp: Date(),
            success: success,
            detail: detail
        )
        
        append(event)
    }
    
    func clearSession() {
        events.removeAll()
        sessionStartTime = Date()
    }
    
    // MARK: - Computed Properties
    
    var sessionDurationSeconds: Double {
        Date().timeIntervalSince(sessionStartTime)
    }
    
    var eventsByCategory: [PerformanceCategory: [PerformanceEvent]] {
        Dictionary(grouping: events) { $0.category }
    }
    
    func averageDuration(for category: PerformanceCategory) -> Double? {
        let categoryEvents = events.filter { $0.category == category }
        guard !categoryEvents.isEmpty else { return nil }
        
        let total = categoryEvents.reduce(0.0) { $0 + $1.durationMs }
        return total / Double(categoryEvents.count)
    }
    
    var slowestEvent: PerformanceEvent? {
        events.max { $0.durationMs < $1.durationMs }
    }
    
    var healthScore: Int {
        guard !events.isEmpty else { return 100 }
        
        let ratingScores: [PerformanceRating: Double] = [
            .excellent: 100,
            .good: 75,
            .fair: 40,
            .slow: 0
        ]
        
        let totalScore = events.reduce(0.0) { total, event in
            total + (ratingScores[event.rating] ?? 0)
        }
        
        let averageScore = totalScore / Double(events.count)
        return Int(averageScore.rounded())
    }
    
    var healthLabel: String {
        let score = healthScore
        
        if score >= 90 {
            return "Excellent"
        } else if score >= 70 {
            return "Good"
        } else if score >= 50 {
            return "Fair"
        } else {
            return "Needs Attention"
        }
    }
    
    var healthColor: Color {
        let score = healthScore
        
        if score >= 90 {
            return .green
        } else if score >= 70 {
            return .blue
        } else if score >= 50 {
            return .orange
        } else {
            return .red
        }
    }
    
    // MARK: - Private Methods
    
    private func append(_ event: PerformanceEvent) {
        events.append(event)
        
        // Cap at 200 events
        if events.count > 200 {
            events.removeFirst(events.count - 200)
        }
    }
}

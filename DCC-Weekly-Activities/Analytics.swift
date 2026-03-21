//
//  Analytics.swift
//  DCC-Weekly-Activities
//
//  Analytics tracking (privacy-friendly)
//

import Combine
import Foundation
import SwiftUI

// MARK: - Analytics Events

enum AnalyticsEvent {
    // App lifecycle
    case appLaunched
    case appForegrounded
    case appBackgrounded
    
    // Authentication
    case loginStarted
    case loginCompleted
    case loginFailed(reason: String)
    case logoutCompleted
    case biometricAuthAttempt(success: Bool)
    
    // Data fetching
    case activitiesFetchStarted
    case activitiesFetchCompleted(count: Int, duration: TimeInterval)
    case activitiesFetchFailed(error: String)
    
    // User interactions
    case viewModeChanged(mode: String)
    case metricSelected(metric: String)
    case memberListExpanded
    case refreshTriggered
    
    // Features
    case chartViewed
    case tableViewed
    case activitiesListViewed
    
    var name: String {
        switch self {
        case .appLaunched: return "app_launched"
        case .appForegrounded: return "app_foregrounded"
        case .appBackgrounded: return "app_backgrounded"
        case .loginStarted: return "login_started"
        case .loginCompleted: return "login_completed"
        case .loginFailed: return "login_failed"
        case .logoutCompleted: return "logout_completed"
        case .biometricAuthAttempt: return "biometric_auth_attempt"
        case .activitiesFetchStarted: return "activities_fetch_started"
        case .activitiesFetchCompleted: return "activities_fetch_completed"
        case .activitiesFetchFailed: return "activities_fetch_failed"
        case .viewModeChanged: return "view_mode_changed"
        case .metricSelected: return "metric_selected"
        case .memberListExpanded: return "member_list_expanded"
        case .refreshTriggered: return "refresh_triggered"
        case .chartViewed: return "chart_viewed"
        case .tableViewed: return "table_viewed"
        case .activitiesListViewed: return "activities_list_viewed"
        }
    }
    
    var parameters: [String: Any] {
        switch self {
        case .loginFailed(let reason):
            return ["reason": reason]
        case .biometricAuthAttempt(let success):
            return ["success": success]
        case .activitiesFetchCompleted(let count, let duration):
            return ["count": count, "duration": duration]
        case .activitiesFetchFailed(let error):
            return ["error": error]
        case .viewModeChanged(let mode):
            return ["mode": mode]
        case .metricSelected(let metric):
            return ["metric": metric]
        default:
            return [:]
        }
    }
}

// MARK: - Analytics Manager

@MainActor
class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private var isEnabled: Bool {
        false // Analytics disabled; enable in AppConfiguration.Features.enableAnalytics
    }
    
    private init() {}
    
    /// Tracks an analytics event
    func track(_ event: AnalyticsEvent) {
        guard isEnabled else { return }
        
        #if DEBUG
        print("📊 Analytics: \(event.name)")
        if !event.parameters.isEmpty {
            print("   Parameters: \(event.parameters)")
        }
        #endif
        
        // TODO: Integrate with your analytics provider
        // Examples: Firebase Analytics, Mixpanel, Amplitude, etc.
        
        // Firebase example:
        // Analytics.logEvent(event.name, parameters: event.parameters)
        
        // Custom analytics example:
        // sendToCustomAnalytics(event: event.name, parameters: event.parameters)
    }
    
    /// Tracks screen views
    func trackScreen(_ screenName: String) {
        guard isEnabled else { return }
        
        #if DEBUG
        print("📱 Screen View: \(screenName)")
        #endif
        
        // TODO: Track screen view
        // Firebase example:
        // Analytics.logEvent(AnalyticsEventScreenView, parameters: [
        //     AnalyticsParameterScreenName: screenName
        // ])
    }
    
    /// Tracks timing events (useful for performance monitoring)
    func trackTiming(_ category: String, duration: TimeInterval, label: String? = nil) {
        guard isEnabled else { return }
        
        #if DEBUG
        print("⏱️ Timing: \(category) - \(duration)s")
        if let label = label {
            print("   Label: \(label)")
        }
        #endif
        
        // TODO: Track timing
    }
    
    /// Sets user properties (use sparingly, respect privacy)
    func setUserProperty(_ value: String?, forName: String) {
        guard isEnabled else { return }
        
        #if DEBUG
        print("👤 User Property: \(forName) = \(value ?? "nil")")
        #endif
        
        // TODO: Set user property
        // Firebase example:
        // Analytics.setUserProperty(value, forName: forName)
    }
}

// MARK: - View Extension for Analytics

extension View {
    /// Tracks when a view appears
    func trackScreenView(_ screenName: String) -> some View {
        self.onAppear {
            AnalyticsManager.shared.trackScreen(screenName)
        }
    }
    
    /// Tracks user interactions
    func trackAction(_ event: AnalyticsEvent) -> some View {
        self.onTapGesture {
            AnalyticsManager.shared.track(event)
        }
    }
}

// MARK: - Privacy-First Analytics

/// Privacy-friendly usage statistics (no personal data)
struct UsageStatistics: Codable {
    var appLaunchCount: Int = 0
    var lastLaunchDate: Date?
    var totalActivitiesFetched: Int = 0
    var totalRefreshes: Int = 0
    var preferredViewMode: String?
    var preferredMetric: String?
    
    private static let key = "usage_statistics"
    
    static func load() -> UsageStatistics {
        guard let data = UserDefaults.standard.data(forKey: key),
              let stats = try? JSONDecoder().decode(UsageStatistics.self, from: data) else {
            return UsageStatistics()
        }
        return stats
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: UsageStatistics.key)
        }
    }
    
    mutating func recordAppLaunch() {
        appLaunchCount += 1
        lastLaunchDate = Date()
        save()
    }
    
    mutating func recordActivitiesFetched(count: Int) {
        totalActivitiesFetched += count
        save()
    }
    
    mutating func recordRefresh() {
        totalRefreshes += 1
        save()
    }
    
    mutating func setPreferredViewMode(_ mode: String) {
        preferredViewMode = mode
        save()
    }
    
    mutating func setPreferredMetric(_ metric: String) {
        preferredMetric = metric
        save()
    }
}

// MARK: - Performance Monitoring

class PerformanceMonitor {
    private var startTime: Date?
    private let operation: String
    
    init(operation: String) {
        self.operation = operation
        self.startTime = Date()
        
        #if DEBUG
        print("⏱️ Starting: \(operation)")
        #endif
    }
    
    func finish() {
        guard let start = startTime else { return }
        let duration = Date().timeIntervalSince(start)
        
        #if DEBUG
        print("✅ Finished: \(operation) in \(String(format: "%.2f", duration))s")
        #endif
        
        // Track performance metric
        if false { // Analytics disabled; enable in AppConfiguration.Features.enableAnalytics
            AnalyticsManager.shared.trackTiming(
                "operation_duration",
                duration: duration,
                label: operation
            )
        }
        
        startTime = nil
    }
}

// MARK: - Usage Example

/*
 // In your view:
 
 Button("Fetch Activities") {
     Task {
         let monitor = PerformanceMonitor(operation: "fetch_activities")
         AnalyticsManager.shared.track(.activitiesFetchStarted)
         
         do {
             let activities = try await fetchActivities()
             AnalyticsManager.shared.track(
                 .activitiesFetchCompleted(count: activities.count, duration: monitor.duration)
             )
             monitor.finish()
         } catch {
             AnalyticsManager.shared.track(.activitiesFetchFailed(error: error.localizedDescription))
         }
     }
 }
 .trackScreenView("main_screen")
 
 // Update usage statistics
 var stats = UsageStatistics.load()
 stats.recordAppLaunch()
 
 */

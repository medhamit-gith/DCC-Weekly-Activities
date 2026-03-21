//
//  AppConfiguration.swift
//  DCC-Weekly-Activities
//
//  Production-ready app configuration and constants
//

import Foundation

/// Central configuration for the app
enum AppConfiguration {
    
    // MARK: - App Information
    
    static let appName = "DCC Weekly Activities"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // MARK: - Strava Configuration
    
    enum Strava {
        static let clientID = "YOUR_STRAVA_CLIENT_ID" // TODO: Replace with actual client ID
        static let clientSecret = "YOUR_STRAVA_CLIENT_SECRET" // TODO: Move to secure location
        static let redirectURI = "dcc-activities://oauth/strava" // Must match Strava dashboard AND StravaConfig exactly
        static let clubID = "YOUR_CLUB_ID" // TODO: Replace with actual club ID
        
        // API Endpoints
        static let authorizeURL = "https://www.strava.com/oauth/mobile/authorize"
        static let tokenURL = "https://www.strava.com/api/v3/oauth/token"
        static let clubActivitiesURL = "https://www.strava.com/api/v3/clubs"
        
        // Rate Limiting
        static let maxRequestsPer15Minutes = 100
        static let maxRequestsPerDay = 1000
        
        // Scopes
        static let requiredScopes = "read,activity:read"
    }
    
    // MARK: - Feature Flags
    
    enum Features {
        #if DEBUG
        static let enableMockData = true
        static let enableDebugLogging = true
        static let enableDetailedErrorMessages = true
        #else
        static let enableMockData = false
        static let enableDebugLogging = false
        static let enableDetailedErrorMessages = false
        #endif
        
        static let enableBiometricAuth = true
        static let enableAnalytics = false // Set to true when implementing analytics
        static let enableCrashReporting = false // Set to true when implementing crash reporting
    }
    
    // MARK: - UI Configuration
    
    enum UI {
        static let animationDuration: Double = 0.3
        static let defaultTopMembersCount = 10
        static let minChartHeight: CGFloat = 350
        static let cardCornerRadius: CGFloat = 12
        static let defaultPadding: CGFloat = 16
    }
    
    // MARK: - Data Configuration
    
    enum Data {
        static let cacheExpirationDays = 7
        static let maxCachedActivities = 1000
        static let refreshThresholdMinutes = 15 // Don't refresh if last refresh was less than this
    }
    
    // MARK: - Keychain Configuration
    
    enum Keychain {
        static let serviceName = "com.desicyclingclub.weeklyactivities"
        static let accessTokenKey = "strava_access_token"
        static let refreshTokenKey = "strava_refresh_token"
        static let tokenExpirationKey = "token_expiration_date"
    }
    
    // MARK: - Support Information
    
    enum Support {
        static let email = "support@desicyclingclub.com" // TODO: Replace with actual email
        static let websiteURL = URL(string: "https://www.desicyclingclub.com")! // TODO: Replace
        static let privacyPolicyURL = URL(string: "https://www.desicyclingclub.com/privacy")! // TODO: Replace
        static let termsOfServiceURL = URL(string: "https://www.desicyclingclub.com/terms")! // TODO: Replace
        static let stravaProfileURL = URL(string: "https://www.strava.com/clubs/YOUR_CLUB_ID")! // TODO: Replace
    }
    
    // MARK: - Theme Colors (Indian Flag)
    
    enum Theme {
        static let saffron = (red: 1.0, green: 0.6, blue: 0.2)
        static let white = (red: 1.0, green: 1.0, blue: 1.0)
        static let green = (red: 0.0, green: 0.5, blue: 0.0)
        static let blue = (red: 0.0, green: 0.2, blue: 0.5)
    }
    
    // MARK: - Validation
    
    /// Validates that all required configuration is present
    static func validateConfiguration() -> [String] {
        var issues: [String] = []
        
        if Strava.clientID == "YOUR_STRAVA_CLIENT_ID" {
            issues.append("Strava Client ID not configured")
        }
        
        if Strava.clubID == "YOUR_CLUB_ID" {
            issues.append("Strava Club ID not configured")
        }
        
        #if !DEBUG
        if Strava.clientSecret == "YOUR_STRAVA_CLIENT_SECRET" {
            issues.append("Strava Client Secret not configured")
        }
        #endif
        
        return issues
    }
    
    // MARK: - Debug Helpers
    
    #if DEBUG
    static func printConfiguration() {
        print("📱 App Configuration")
        print("   Version: \(appVersion) (\(buildNumber))")
        print("   Strava Client ID: \(Strava.clientID)")
        print("   Club ID: \(Strava.clubID)")
        print("   Mock Data: \(Features.enableMockData)")
        print("   Debug Logging: \(Features.enableDebugLogging)")
        
        let issues = validateConfiguration()
        if !issues.isEmpty {
            print("⚠️ Configuration Issues:")
            issues.forEach { print("   - \($0)") }
        }
    }
    #endif
}

// MARK: - Environment Detection

extension AppConfiguration {
    enum Environment {
        case debug
        case testFlight
        case appStore
        
        static var current: Environment {
            #if DEBUG
            return .debug
            #else
            if Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" {
                return .testFlight
            }
            return .appStore
            #endif
        }
        
        var displayName: String {
            switch self {
            case .debug: return "Debug"
            case .testFlight: return "TestFlight"
            case .appStore: return "App Store"
            }
        }
    }
}

// MARK: - Logging Helper

enum AppLogger {
    static func log(_ message: String, category: String = "General") {
        #if DEBUG
        print("[\(category)] \(message)")
        #else
        // In production, this could go to a crash reporting service
        if AppConfiguration.Features.enableCrashReporting {
            // TODO: Send to crash reporting service
        }
        #endif
    }
    
    static func error(_ message: String, error: Error? = nil) {
        #if DEBUG
        print("❌ [\(message)]")
        if let error = error {
            print("   Error: \(error.localizedDescription)")
        }
        #else
        // In production, report to crash reporting service
        if AppConfiguration.Features.enableCrashReporting {
            // TODO: Send to crash reporting service
        }
        #endif
    }
    
    static func warning(_ message: String) {
        #if DEBUG
        print("⚠️ [\(message)]")
        #endif
    }
    
    static func success(_ message: String) {
        #if DEBUG
        print("✅ [\(message)]")
        #endif
    }
}

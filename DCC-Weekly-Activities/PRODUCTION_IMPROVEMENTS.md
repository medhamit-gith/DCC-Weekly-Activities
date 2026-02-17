# Production Code Improvements Guide

This document outlines recommended code improvements to make your app production-ready.

---

## 🔧 Critical Improvements

### 1. Remove Debug Code

**Current State:** Debug print statements throughout the code  
**Action Required:** Wrap all debug statements with `#if DEBUG`

```swift
// Before
print("📊 Activities loaded: \(count)")

// After
#if DEBUG
print("📊 Activities loaded: \(count)")
#endif

// Or use the new AppLogger
AppLogger.log("Activities loaded: \(count)", category: "Data")
```

**Files to Review:**
- ContentView.swift
- MemberStatsChartView.swift
- StravaAPI.swift
- BiometricAuth.swift
- All view files

---

### 2. Secure API Credentials

**Current State:** API keys likely in source code  
**Action Required:** Move to secure configuration

**Option A: Use Xcode Configuration Files**

1. Create a `Secrets.xcconfig` file:
```
STRAVA_CLIENT_ID = your_client_id_here
STRAVA_CLIENT_SECRET = your_secret_here
STRAVA_CLUB_ID = your_club_id_here
```

2. Add to .gitignore:
```
Secrets.xcconfig
```

3. Access in code:
```swift
let clientID = Bundle.main.object(forInfoDictionaryKey: "STRAVA_CLIENT_ID") as? String
```

**Option B: Use Environment Variables**

```swift
extension AppConfiguration.Strava {
    static var clientID: String {
        #if DEBUG
        return "debug_client_id"
        #else
        return ProcessInfo.processInfo.environment["STRAVA_CLIENT_ID"] ?? ""
        #endif
    }
}
```

---

### 3. Implement Token Refresh

**Current State:** Access tokens expire but aren't refreshed  
**Action Required:** Add token refresh logic

```swift
// Add to StravaAPI.swift

func refreshAccessToken() async throws {
    guard let refreshToken = loadRefreshToken() else {
        throw AppError.tokenExpired
    }
    
    let url = URL(string: AppConfiguration.Strava.tokenURL)!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    let parameters = [
        "client_id": AppConfiguration.Strava.clientID,
        "client_secret": AppConfiguration.Strava.clientSecret,
        "refresh_token": refreshToken,
        "grant_type": "refresh_token"
    ]
    
    request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw AppError.authenticationFailed
    }
    
    let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
    
    await MainActor.run {
        self.accessToken = tokenResponse.access_token
        saveTokens(
            accessToken: tokenResponse.access_token,
            refreshToken: tokenResponse.refresh_token,
            expiresAt: Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in))
        )
    }
}

struct TokenResponse: Codable {
    let access_token: String
    let refresh_token: String
    let expires_in: Int
}
```

---

### 4. Add Rate Limiting Protection

**Current State:** No rate limit handling  
**Action Required:** Implement request throttling

```swift
// Add to StravaAPI.swift

@MainActor
class RateLimiter {
    private var requestTimes: [Date] = []
    private let maxRequests = AppConfiguration.Strava.maxRequestsPer15Minutes
    private let timeWindow: TimeInterval = 15 * 60 // 15 minutes
    
    func canMakeRequest() -> Bool {
        let now = Date()
        let cutoff = now.addingTimeInterval(-timeWindow)
        
        // Remove old requests
        requestTimes = requestTimes.filter { $0 > cutoff }
        
        return requestTimes.count < maxRequests
    }
    
    func recordRequest() {
        requestTimes.append(Date())
    }
    
    func waitTimeUntilNextRequest() -> TimeInterval? {
        guard !canMakeRequest() else { return nil }
        
        if let oldest = requestTimes.first {
            let waitTime = timeWindow - Date().timeIntervalSince(oldest)
            return max(0, waitTime)
        }
        
        return nil
    }
}

// Usage in StravaAPI
private let rateLimiter = RateLimiter()

func fetchActivities() async throws -> [ClubActivity] {
    guard rateLimiter.canMakeRequest() else {
        if let waitTime = rateLimiter.waitTimeUntilNextRequest() {
            throw AppError.rateLimitExceeded
        }
        throw AppError.unknown(NSError(domain: "RateLimit", code: 429))
    }
    
    rateLimiter.recordRequest()
    // ... rest of implementation
}
```

---

### 5. Add Offline Support

**Current State:** App crashes or shows errors when offline  
**Action Required:** Cache data and show appropriate messages

```swift
// Add to a new file: DataCache.swift

import Foundation

actor DataCache {
    static let shared = DataCache()
    
    private let cacheKey = "cached_activities"
    private let cacheTimestampKey = "cache_timestamp"
    private let cacheExpirationSeconds: TimeInterval = 3600 // 1 hour
    
    func cacheActivities(_ activities: [ClubActivity]) async {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(activities) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: cacheTimestampKey)
        }
    }
    
    func loadCachedActivities() async -> [ClubActivity]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let timestamp = UserDefaults.standard.object(forKey: cacheTimestampKey) as? Date else {
            return nil
        }
        
        // Check if cache is still valid
        let age = Date().timeIntervalSince(timestamp)
        guard age < cacheExpirationSeconds else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try? decoder.decode([ClubActivity].self, from: data)
    }
    
    func clearCache() async {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheTimestampKey)
    }
}

// Usage in ContentView
private func fetchClubActivities() async {
    isLoading = true
    errorMessage = nil
    
    do {
        let fetched = try await stravaAPI.fetchLastWeeksClubActivities()
        
        // Cache the results
        await DataCache.shared.cacheActivities(fetched)
        
        await MainActor.run {
            activities = fetched
            memberStats = aggregateMemberStats(from: fetched)
            isLoading = false
        }
    } catch {
        // Try to load from cache
        if let cached = await DataCache.shared.loadCachedActivities() {
            await MainActor.run {
                activities = cached
                memberStats = aggregateMemberStats(from: cached)
                isLoading = false
                errorMessage = "Showing cached data (offline)"
            }
        } else {
            await MainActor.run {
                activities = []
                memberStats = []
                isLoading = false
                errorMessage = "Failed to load activities: \(error.localizedDescription)"
            }
        }
    }
}
```

---

### 6. Add Pull-to-Refresh

**Current State:** Only manual refresh button  
**Action Required:** Add pull-to-refresh gesture

```swift
// In ContentView.swift

var body: some View {
    NavigationView {
        mainContent
            .refreshable {
                await fetchClubActivities()
            }
    }
}
```

---

### 7. Improve Accessibility

**Current State:** Limited VoiceOver support  
**Action Required:** Add accessibility labels and hints

```swift
// In MemberStatsChartView.swift

StatCard(
    title: "Total Distance",
    value: String(format: "%.1f km", totalKM),
    icon: "road.lanes",
    color: .blue
)
.accessibilityElement(children: .combine)
.accessibilityLabel("Total distance: \(String(format: "%.1f", totalKM)) kilometers")
.accessibilityHint("Shows the total distance cycled by all members this week")

// For charts
Chart(displayedStats) { stat in
    // ... chart marks
}
.accessibilityLabel("Member statistics bar chart")
.accessibilityValue("\(displayedStats.count) members displayed")
.accessibilityHint("Shows \(selectedMetric.accessibilityLabel) for each member")
```

---

### 8. Add Unit Tests

**Create:** MemberStatsTests.swift

```swift
import Testing
@testable import DCC_Weekly_Activities

@Suite("Member Statistics Tests")
struct MemberStatsTests {
    
    @Test("Calculate total kilometers correctly")
    func testTotalKilometers() async throws {
        let activities = [
            ClubActivity(memberName: "Test", activityName: "Ride 1", distance: 10.0, date: Date()),
            ClubActivity(memberName: "Test", activityName: "Ride 2", distance: 15.0, date: Date())
        ]
        
        let stats = MemberStats(memberName: "Test", activities: activities)
        
        #expect(stats.totalKM == 25.0)
        #expect(stats.totalRides == 2)
    }
    
    @Test("Calculate average speed correctly")
    func testAverageSpeed() async throws {
        let activities = [
            ClubActivity(memberName: "Test", activityName: "Ride 1", distance: 10.0, date: Date(), averageSpeed: 20.0),
            ClubActivity(memberName: "Test", activityName: "Ride 2", distance: 10.0, date: Date(), averageSpeed: 30.0)
        ]
        
        let stats = MemberStats(memberName: "Test", activities: activities)
        
        #expect(stats.avgSpeed == 25.0)
    }
    
    @Test("Handle empty activities")
    func testEmptyActivities() async throws {
        let stats = MemberStats(memberName: "Test", activities: [])
        
        #expect(stats.totalKM == 0.0)
        #expect(stats.totalRides == 0)
        #expect(stats.avgSpeed == 0.0)
    }
    
    @Test("Trend calculation for new member")
    func testTrendForNewMember() async throws {
        let currentActivities = [
            ClubActivity(memberName: "Test", activityName: "Ride 1", distance: 10.0, date: Date())
        ]
        
        let stats = MemberStats(memberName: "Test", activities: currentActivities, previousWeekActivities: [])
        
        #expect(stats.currentWeekTrend == .new)
    }
}
```

---

### 9. Add Haptic Feedback

**Current State:** No tactile feedback  
**Action Required:** Add haptics for important actions

```swift
// Create HapticManager.swift

import UIKit

struct HapticManager {
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// Usage
Button("Fetch Activities") {
    HapticManager.impact()
    Task {
        do {
            try await fetchActivities()
            HapticManager.success()
        } catch {
            HapticManager.error()
        }
    }
}
```

---

### 10. Add Localization Support

**Create:** Localizable.strings files

```swift
// Localizable.strings (English)
"app.title" = "DCC Weekly Activities";
"login.title" = "Connect with Strava";
"stats.total_distance" = "Total Distance";
"stats.total_rides" = "Total Rides";
"error.network_unavailable" = "No internet connection";

// Localizable.strings (Hindi)
"app.title" = "DCC साप्ताहिक गतिविधियाँ";
"login.title" = "Strava से जुड़ें";
"stats.total_distance" = "कुल दूरी";
"stats.total_rides" = "कुल सवारी";
"error.network_unavailable" = "इंटरनेट कनेक्शन नहीं है";

// Usage in code
Text(NSLocalizedString("app.title", comment: "App title"))

// Or with String extension
extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}

Text("app.title".localized)
```

---

## 📋 Quick Implementation Checklist

- [ ] Wrap all debug statements in `#if DEBUG`
- [ ] Move API credentials to secure configuration
- [ ] Implement token refresh mechanism
- [ ] Add rate limiting protection
- [ ] Implement data caching for offline support
- [ ] Add pull-to-refresh gesture
- [ ] Improve accessibility labels
- [ ] Add unit tests for core logic
- [ ] Implement haptic feedback
- [ ] Add localization for key languages
- [ ] Remove mock data from release builds
- [ ] Add error tracking (Crashlytics/Sentry)
- [ ] Implement analytics (optional)
- [ ] Add loading skeletons for better UX
- [ ] Optimize image assets
- [ ] Test on multiple device sizes
- [ ] Test with VoiceOver enabled
- [ ] Test with Dynamic Type (text scaling)
- [ ] Profile memory usage
- [ ] Check for retain cycles

---

## 🔍 Code Review Checklist

### Security
- [ ] No hardcoded secrets
- [ ] Keychain used for sensitive data
- [ ] HTTPS for all network calls
- [ ] Input validation on all user input
- [ ] No logging of sensitive information

### Performance
- [ ] No blocking operations on main thread
- [ ] Proper use of async/await
- [ ] Image assets optimized
- [ ] Efficient data structures
- [ ] Memory leaks checked

### User Experience
- [ ] Loading states for all async operations
- [ ] Error messages are user-friendly
- [ ] Empty states have helpful text
- [ ] Animations are smooth (60fps)
- [ ] App responds quickly to user input

### Accessibility
- [ ] All buttons have labels
- [ ] Images have descriptions
- [ ] Colors have sufficient contrast
- [ ] Text is scalable
- [ ] VoiceOver navigation works

### Code Quality
- [ ] No force unwraps (!)
- [ ] Proper error handling
- [ ] Code is well-documented
- [ ] No compiler warnings
- [ ] SwiftLint passes (if using)

---

## 📱 Testing Matrix

### Devices to Test
- [ ] iPhone SE (smallest screen)
- [ ] iPhone 15 Pro
- [ ] iPhone 15 Pro Max (largest screen)
- [ ] iPad Pro 11"
- [ ] iPad Pro 12.9"
- [ ] Apple TV 4K (if supporting)

### iOS Versions
- [ ] iOS 17.0 (minimum supported)
- [ ] iOS 17.latest
- [ ] iOS 18.0 (current)

### Scenarios to Test
- [ ] Fresh install and login
- [ ] App launch with existing session
- [ ] Network timeout
- [ ] No network connection
- [ ] Slow network (3G simulation)
- [ ] Biometric auth failure
- [ ] Strava OAuth cancellation
- [ ] Very large dataset (100+ activities)
- [ ] Empty dataset (no activities)
- [ ] App backgrounding/foregrounding
- [ ] Memory warning scenarios
- [ ] Device rotation
- [ ] Dark mode
- [ ] Large text size
- [ ] VoiceOver enabled

---

## 🚀 Pre-Submission Final Check

1. **Build Settings**
   - [ ] Deployment target set correctly
   - [ ] Release configuration optimized
   - [ ] Bitcode enabled (if required)
   - [ ] Strip debug symbols in Release

2. **Info.plist**
   - [ ] All privacy descriptions present
   - [ ] URL schemes configured
   - [ ] App Transport Security configured
   - [ ] Supported orientations set

3. **Code Quality**
   - [ ] All TODOs addressed or documented
   - [ ] No force unwraps in production code
   - [ ] No fatalError() in production code
   - [ ] All warnings resolved

4. **Testing**
   - [ ] App doesn't crash
   - [ ] All features work as expected
   - [ ] Tested on multiple devices
   - [ ] TestFlight beta completed

5. **Legal**
   - [ ] Privacy policy finalized and hosted
   - [ ] Terms of service created
   - [ ] Strava API compliance verified
   - [ ] All attributions included

---

**Next Steps:**
1. Implement critical improvements (1-5)
2. Add recommended improvements (6-10)
3. Complete testing matrix
4. Run final checklist
5. Submit to App Store! 🎉

# DCC Weekly Activities — App Architecture

**Version:** 1.0  
**Last Updated:** March 2, 2026  
**Platform:** iOS 17.0+  
**Language:** Swift 6 with Swift Concurrency

---

## 📋 Executive Summary

DCC Weekly Activities is a native iOS app that connects to the Strava API to fetch and analyze cycling club activities. The app provides rich performance insights, comparative analytics, and personalized coaching tips for club members. It follows a modern SwiftUI architecture with clean separation of concerns, Swift Concurrency for async operations, and privacy-first design principles.

---

## 🏗 Architecture Overview

### High-Level Architecture Pattern

The app follows a **unidirectional data flow** pattern with clear separation between:
- **Data Layer** (Models + API Service)
- **Business Logic Layer** (ViewModels)
- **Presentation Layer** (SwiftUI Views)

```
┌──────────────────────────────────────────────────────────────┐
│                      Presentation Layer                       │
│  ┌────────────┬────────────┬──────────────┬────────────────┐ │
│  │ RootView   │ Leaderboard│ RiderAnalysis│ InsightsView   │ │
│  │ (Main Hub) │ View       │ View         │                │ │
│  └────────────┴────────────┴──────────────┴────────────────┘ │
└────────────────────────┬──────────────────────────────────────┘
                         │ @Observable ViewModels
┌────────────────────────┴──────────────────────────────────────┐
│                    Business Logic Layer                        │
│  ┌────────────────┬──────────────┬──────────────────────────┐ │
│  │ InsightsVM     │ RootViewModel│ WhatIfEngine (NEW)       │ │
│  │ (Gap Analysis) │ (Main State) │ (Scenario Projections)   │ │
│  └────────────────┴──────────────┴──────────────────────────┘ │
└────────────────────────┬──────────────────────────────────────┘
                         │ async/await calls
┌────────────────────────┴──────────────────────────────────────┐
│                        Data Layer                              │
│  ┌────────────────┬────────────────┬──────────────────────┐   │
│  │ StravaAPI      │ MemberStats    │ RiderStats (NEW)     │   │
│  │ (OAuth + Fetch)│ (Aggregates)   │ (Rich Analytics)     │   │
│  └────────────────┴────────────────┴──────────────────────┘   │
│  ┌────────────────┬────────────────┬──────────────────────┐   │
│  │ BiometricAuth  │ ErrorHandler   │ DataCache            │   │
│  │ (Face/Touch ID)│ (Centralized)  │ (Offline Support)    │   │
│  └────────────────┴────────────────┴──────────────────────┘   │
└────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow Diagram

### 1. Authentication Flow

```
┌─────────┐        ┌──────────────┐        ┌──────────────┐
│  User   │        │  StravaAPI   │        │   Strava     │
│         │        │   Service    │        │   Servers    │
└────┬────┘        └──────┬───────┘        └──────┬───────┘
     │                    │                       │
     │ 1. Tap "Connect"   │                       │
     ├───────────────────>│                       │
     │                    │                       │
     │                    │ 2. ASWebAuthSession   │
     │                    ├──────────────────────>│
     │                    │                       │
     │                    │ 3. User approves      │
     │                    │<──────────────────────┤
     │                    │ (auth code)           │
     │                    │                       │
     │                    │ 4. Exchange via       │
     │                    │    Cloudflare Worker  │
     │                    ├──────────────────────>│
     │                    │                       │
     │                    │ 5. Access + Refresh   │
     │                    │<──────────────────────┤
     │                    │    Tokens             │
     │                    │                       │
     │ 6. Logged In       │                       │
     │<───────────────────┤                       │
     │                    │                       │
     │                    │ 7. Store tokens       │
     │                    │    (Memory only)      │
     │                    │                       │
```

**Security Notes:**
- Client secret lives ONLY in Cloudflare Worker (never in app binary)
- Access token stored in memory only (not persisted to disk)
- Refresh token not currently saved (user re-authenticates each session)
- ASWebAuthenticationSession provides secure OAuth flow

### 2. Data Fetch & Analysis Flow

```
┌─────────┐     ┌────────────┐     ┌──────────┐     ┌─────────────┐
│   User  │     │  RootView  │     │ StravaAPI│     │ InsightsVM  │
└────┬────┘     └─────┬──────┘     └────┬─────┘     └──────┬──────┘
     │                │                  │                  │
     │ 1. Pull        │                  │                  │
     │    to refresh  │                  │                  │
     ├───────────────>│                  │                  │
     │                │                  │                  │
     │                │ 2. fetchLastWeeks│                  │
     │                │    ClubActivities│                  │
     │                ├─────────────────>│                  │
     │                │                  │                  │
     │                │                  │ 3. GET /clubs/   │
     │                │                  │    {id}/activities│
     │                │                  │    ?per_page=200  │
     │                │                  │    &after=<unix>  │
     │                │                  ├────────────────> │
     │                │                  │    (Strava API)  │
     │                │                  │                  │
     │                │                  │ 4. [Activity]    │
     │                │                  │<─────────────────│
     │                │                  │                  │
     │                │ 5. [Activity]    │                  │
     │                │<─────────────────┤                  │
     │                │                  │                  │
     │                │ 6. aggregate     │                  │
     │                │    MemberStats   │                  │
     │                │    (group by     │                  │
     │                │     athlete)     │                  │
     │                │                  │                  │
     │                │ 7. build         │                  │
     │                │    RiderStats    │                  │
     │                │──────────────────┼─────────────────>│
     │                │                  │                  │
     │                │                  │ 8. normalize     │
     │                │                  │    metrics       │
     │                │                  │    (0-1 scale)   │
     │                │                  │                  │
     │                │                  │ 9. generate      │
     │                │                  │    coaching tips │
     │                │                  │                  │
     │ 10. Display    │                  │                  │
     │     Charts     │                  │                  │
     │<───────────────┤                  │                  │
     │                │                  │                  │
```

---

## 📊 Data Models

### Core Models

#### 1. Activity (Base Unit)
```swift
struct Activity: Identifiable, Hashable {
    let id: UUID
    let memberName: String
    let activityName: String
    let distance: Double        // km
    let date: Date
    let averageSpeed: Double    // km/h
    let elevationGain: Double   // meters
    let movingTime: Int         // seconds
    let type: String            // "Ride", "GravelRide", etc.
}
```

**Source:** Transformed from Strava's `StravaActivityResponse`

#### 2. MemberStats (Aggregated View)
```swift
struct MemberStats: Identifiable {
    let memberName: String
    let totalRides: Int
    let totalKM: Double
    let avgSpeed: Double
    let totalElevation: Double
    let currentWeekTrend: TrendDirection
    let rides: [Activity]
    let previousWeekKM: Double
    let previousWeekRides: Int
}
```

**Purpose:** Week-over-week comparison and basic leaderboard display

#### 3. RiderStats (NEW — Rich Analytics Model)
```swift
struct RiderStats: Identifiable {
    let id: String
    let displayName: String
    let activities: [ClubActivity]
    
    // Distance Metrics
    var totalDistanceKm: Double
    var averageDistanceKm: Double
    var longestRideKm: Double
    var distanceVariance: Double
    
    // Speed Metrics
    var averageSpeedKmh: Double
    var maxSpeedKmh: Double
    var speedConsistency: Double
    
    // Elevation Metrics
    var totalElevationM: Double
    var averageElevationPerKm: Double
    var climbingFocus: Double
    
    // Performance Scores (0-1 normalized)
    var normalizedDistance: Double
    var normalizedSpeed: Double
    var normalizedElevation: Double
    var normalizedConsistency: Double
    var normalizedEfficiency: Double
    
    // What-If Projections
    func projectedDistanceWith(extraRides: Int) -> Double
    func ridesNeededToMatch(leader: RiderStats) -> Int
}
```

**Purpose:** Deep performance analysis, radar charts, what-if scenarios

---

## 🎯 Key Services

### 1. StravaAPI

**Responsibilities:**
- OAuth 2.0 authentication via ASWebAuthenticationSession
- Token management (access + refresh via Cloudflare Worker)
- Fetching club activities with pagination
- Rate limit awareness

**Key Methods:**
```swift
func beginOAuth()
func fetchLastWeeksClubActivities(isExtendedFetch: Bool) async throws -> [Activity]
func fetchAuthenticatedAthlete() async throws -> AthleteProfile
func refreshAccessToken() async -> Bool
```

**Data Source:**
- `GET /api/v3/clubs/{id}/activities`
- Returns: ClubActivity objects (limited fields — no activity ID, no dates)

**Pagination Strategy:**
- `per_page=200` (maximum allowed by Strava)
- Loop until empty page received
- 0.5s delay between pages after page 3 (rate limit protection)

### 2. InsightsViewModel

**Responsibilities:**
- Gap analysis (distance, speed, elevation, consistency)
- Coaching tip generation
- Normalization of metrics across club members
- Ranking calculation

**Key Methods:**
```swift
func generateCoachingTips(for rider: MemberStats) -> [CoachingTip]
func normalizedDistance(for rider: MemberStats) -> Double
func rank(for rider: MemberStats) -> Int
```

### 3. WhatIfEngine (NEW)

**Responsibilities:**
- Scenario projection ("what if I ride 2 more times?")
- Gap closing calculations
- Weakest/strongest metric identification

**Key Methods:**
```swift
static func whatIfExtraRides(_ count: Int, rider: RiderStats) -> WhatIfResult
static func whatIfFasterPace(extraKmh: Double, rider: RiderStats) -> WhatIfResult
static func generateTips(gap: GapAnalysis, rider: RiderStats, leader: RiderStats) -> [CoachingTip]
```

---

## 🖼 View Architecture

### Screen Hierarchy

```
RootView (Main Container)
├─ LoginView (Strava OAuth)
├─ LeaderboardView
│  ├─ ClubHeaderCard
│  ├─ DistanceBarChart
│  └─ MemberListItem (foreach)
│
├─ InsightsView
│  ├─ RiderPicker
│  ├─ CelebrationCardView
│  ├─ RadarChartView
│  ├─ SpeedElevationScatter
│  └─ CoachingTipsSection
│
└─ RiderAnalysisView (Full-Screen Detail)
   ├─ CelebrationCardView
   ├─ DistanceBarChart (with ChartHelpButton) ← NEW
   ├─ SpeedElevationScatter (with ChartHelpButton) ← NEW
   ├─ RadarChartView (with ChartHelpButton) ← NEW
   └─ CoachingTipsSection (with ChartHelpButton) ← NEW
```

### Navigation Pattern

```
RootView uses .sheet for full-screen transitions:
- LoginView: .sheet(isPresented: $showLogin)
- RiderAnalysisView: .sheet(item: $selectedRider)

NavigationStack used within each main section
Animated transitions via RiderAnalysisTransition.swift
```

---

## 🎨 Design System

### Color Tokens

```swift
// Brand Colors
.dccBlue    = #1E40AF
.dccSaffron = #F59E0B
.dccGreen   = #10B981

// Accent (Primary Action)
.accent = #FC4C02

// Surfaces
.appBackground      = #0D0D0D  // Base layer
.surface            = #1A1A1A  // Cards/panels
.surfaceElevated    = #242424  // Elevated cards

// Text
.textPrimary    = #FFFFFF
.textSecondary  = #8E8E93
.textTertiary   = #9CA3AF
```

### Typography Scale

```swift
.displayLarge   = 34pt bold
.h1             = 24pt bold
.h2             = 20pt semibold
.bodyDefault    = 15pt regular
.cardTitle      = 18pt semibold
.heroStat       = 56pt black rounded
```

### Spacing Scale

```swift
.xs  = 8pt
.sm  = 12pt
.md  = 16pt
.lg  = 24pt
.xl  = 32pt
```

---

## 🔐 Security & Privacy

### Authentication

1. **OAuth 2.0 Flow**
   - Redirect URI: `dcc-activities://localhost/oauth/strava`
   - Scopes: `read`, `activity:read`
   - Authorization via ASWebAuthenticationSession (system-managed)

2. **Token Storage**
   - Access token: Stored in memory only (@Observable property)
   - Refresh token: Currently NOT persisted (user re-authenticates)
   - Future: Store refresh token in Keychain for persistent sessions

3. **Cloudflare Worker Proxy**
   - Client secret never shipped in app binary
   - Worker handles token exchange: `POST /exchange { code, client_id }`
   - Worker handles token refresh: `POST /refresh { refresh_token, client_id }`

### Data Privacy

- **No user data sent to third parties** (except Strava for API calls)
- **No analytics by default** (optional via AppConfiguration.Features.enableAnalytics)
- **No crash reporting by default**
- **Local data only** — all processing happens on-device
- **No persistent cache of sensitive data**

### Strava API Compliance

- Rate limit: 100 requests/15 minutes, 1000 requests/day
- Rate limit protection: Implemented in fetching logic (0.5s delays)
- Club data: Public club activities only (no private user data)
- Attribution: "Powered by Strava" required (displayed in UI)

---

## ⚡️ Performance Optimizations

### 1. Async/Await Throughout

All network calls use Swift Concurrency:
```swift
Task {
    let activities = try await stravaAPI.fetchLastWeeksClubActivities()
    await MainActor.run {
        self.activities = activities
    }
}
```

### 2. Chart Animation Staggering

Charts animate with delays to avoid janky simultaneous rendering:
```swift
withAnimation(.spring(response: 0.5).delay(0.1)) { showHeader = true }
withAnimation(.spring(response: 0.5).delay(0.35)) { showCharts = true }
withAnimation(.spring(response: 0.5).delay(0.55)) { showTips = true }
```

### 3. NaN Guards

All computed metrics use `.safeValue` extension:
```swift
extension Double {
    var safeValue: Double {
        isFinite ? self : 0.0
    }
}
```

### 4. Data Aggregation Strategy

```
1. Fetch raw [Activity] from Strava (200 per page)
2. Group by athlete name: Dictionary<String, [Activity]>
3. Map to [MemberStats] with totals/averages
4. Build [RiderStats] with rich analytics
5. Normalize across club (0-1 scale for radar chart)
6. Cache for quick re-render on view changes
```

---

## 📱 User Experience Flow

### First Launch

```
1. App opens → LoginView shown
2. User taps "Connect with Strava"
3. ASWebAuthenticationSession opens (Strava app or Safari)
4. User approves access
5. App exchanges code for tokens via Cloudflare Worker
6. Biometric auth prompt (if device supports)
7. Fetch club activities (with loading animation)
8. Display LeaderboardView with club totals
```

### Typical Session

```
1. App opens → Biometric auth (if enabled)
2. Auto-fetch latest week's activities
3. User browses leaderboard
4. User taps member → RiderAnalysisView slides up
5. Animated entrance: Celebration card → Charts → Tips
6. User explores charts (tap ⓘ for help tooltips) ← NEW
7. User views "what-if" projections ← NEW
8. User swipes back or taps back button
9. Returns to leaderboard
```

### Offline Behavior

```
1. App detects no network
2. Attempts to load from cache (DataCache.shared)
3. Shows banner: "Showing cached data (offline)"
4. User can still browse previously fetched data
5. Pull-to-refresh shows error with retry option
```

---

## 🧪 Testing Strategy

### Unit Tests (Swift Testing Framework)

Target: Core business logic

```swift
@Suite("RiderStats Calculations")
struct RiderStatsTests {
    @Test("Calculate distance metrics correctly")
    func testDistanceMetrics() async throws {
        // Test totalDistanceKm, averageDistanceKm, variance
    }
    
    @Test("Calculate normalized values")
    func testNormalization() async throws {
        // Test 0-1 scaling logic
    }
    
    @Test("What-if scenario projections")
    func testWhatIfEngine() async throws {
        // Test projectedDistanceWith(extraRides:)
    }
}
```

### UI Tests

Target: Critical user flows

```
1. OAuth login flow
2. Biometric authentication
3. Activity fetching and display
4. Chart rendering and animation
5. Navigation to RiderAnalysisView
6. Chart help tooltip display
7. Offline error handling
```

### Manual Testing Scenarios

```
✓ Fresh install and login
✓ Token expiration and refresh
✓ No network connection
✓ Slow network (3G simulation)
✓ Large dataset (100+ activities)
✓ Empty dataset (no activities this week)
✓ 2-week fallback when current week empty
✓ App backgrounding/foregrounding
✓ Dark mode
✓ Large text size (Dynamic Type)
✓ VoiceOver navigation
✓ Device rotation
```

---

## 🚀 Deployment Architecture

### Build Configuration

**Debug:**
- Debug symbols enabled
- Logging verbose
- Analytics disabled
- Test Strava Club ID

**Release:**
- Debug symbols stripped
- Logging minimal (errors only)
- Analytics optional
- Production Strava Club ID

### Environment Variables

```swift
struct AppConfiguration {
    struct Features {
        static let enableAnalytics = false
        static let enableBiometrics = true
        static let enableDebugMenu = false
    }
    
    struct Strava {
        static let clientID = "161984"
        static let clubID = "212760"
        static let workerURL = "https://dcc-strava.amit-r-kamat.workers.dev"
        static let redirectURI = "dcc-activities://localhost/oauth/strava"
    }
}
```

### Cloudflare Worker (Token Proxy)

**Endpoint 1:** `POST /exchange`
```json
{
  "code": "auth_code_from_strava",
  "client_id": "161984"
}
```

**Response:**
```json
{
  "access_token": "...",
  "refresh_token": "...",
  "expires_at": 1234567890
}
```

**Endpoint 2:** `POST /refresh`
```json
{
  "refresh_token": "...",
  "client_id": "161984"
}
```

**Response:** Same as /exchange

**Security:**
- Client secret stored in Worker environment variables
- CORS restricted to app's user-agent
- Rate limiting on Worker level

---

## 📈 Analytics & Monitoring (Optional)

### Events Tracked

```
app_launched
login_completed
login_failed
activities_fetch_completed
activities_fetch_failed
view_mode_changed
chart_viewed
refresh_triggered
```

### Performance Metrics

```
fetch_duration (activities API call)
render_time (chart animation)
cache_hit_rate
error_rate
```

### Privacy-First Approach

- No personally identifiable information (PII) logged
- Usage statistics stored locally only (UsageStatistics.swift)
- Analytics opt-in (not opt-out)
- No third-party trackers in Release builds

---

## 🔄 Future Enhancements

### Planned Features

1. **Persistent Sessions**
   - Store refresh token in Keychain
   - Auto-refresh on app launch
   - Reduce re-authentication friction

2. **Historical Trends**
   - Multi-week comparison charts
   - Personal best tracking
   - Achievement badges

3. **Social Features**
   - Kudos/comments on activities
   - Challenge creation
   - Club-wide goals

4. **Advanced Analytics**
   - Training load calculation
   - Fatigue/fitness modeling
   - Route recommendations based on weaknesses

5. **Export & Sharing**
   - PDF report generation
   - Share charts to social media
   - Export data to CSV

### Technical Debt

- [ ] Add Keychain storage for refresh tokens
- [ ] Implement DataCache for offline-first experience
- [ ] Add AppLogger for production-ready logging
- [ ] Complete test coverage (target: 80%)
- [ ] Add localization (Hindi, Punjabi)
- [ ] Optimize chart rendering for large datasets
- [ ] Add SwiftLint for code style consistency

---

## 📦 Dependencies

### First-Party (Apple Frameworks)

```
SwiftUI                   — UI framework
Swift Charts              — Native chart rendering
Foundation                — Date, JSON, networking
Combine                   — Reactive data flow (minimal usage)
AuthenticationServices    — OAuth via ASWebAuthenticationSession
LocalAuthentication       — Biometric authentication
```

### Third-Party

**None.** The app is 100% native Swift/SwiftUI.

---

## 📄 File Structure

```
DCC-Weekly-Activities/
├── Models/
│   ├── Activity.swift
│   ├── MemberStats.swift
│   ├── RiderStats.swift (NEW)
│   └── ClubTotals.swift
│
├── Services/
│   ├── StravaAPI.swift
│   ├── BiometricAuth.swift
│   ├── ErrorHandler.swift
│   ├── DataCache.swift
│   ├── WhatIfEngine.swift (NEW)
│   └── DateRangeProvider.swift
│
├── ViewModels/
│   ├── InsightsViewModel.swift
│   └── RootViewModel.swift (implicit in RootView)
│
├── Views/
│   ├── RootView.swift (main container)
│   ├── LoginView.swift
│   ├── LeaderboardView.swift
│   ├── InsightsView.swift
│   ├── RiderAnalysisView.swift
│   │
│   ├── Components/
│   │   ├── Charts/
│   │   │   ├── DistanceBarChart.swift
│   │   │   ├── SpeedElevationScatter.swift
│   │   │   ├── RadarChartView.swift
│   │   │   └── ChartHelpTooltip.swift (NEW)
│   │   │
│   │   ├── Cards/
│   │   │   ├── CelebrationCardView.swift
│   │   │   ├── CoachingTipCard.swift
│   │   │   └── ClubHeaderCard.swift
│   │   │
│   │   └── Common/
│   │       ├── LoadingView.swift
│   │       └── ErrorView.swift
│   │
│   └── Transitions/
│       └── RiderAnalysisTransition.swift
│
├── Design/
│   ├── DesignSystem.swift (colors, spacing, typography)
│   └── AppConfiguration.swift
│
├── Utilities/
│   ├── Analytics.swift
│   └── Extensions/
│       ├── Double+Safe.swift (NEW — safeValue)
│       └── View+Extensions.swift
│
└── Resources/
    ├── Assets.xcassets
    └── Info.plist
```

---

## 🎓 Key Design Decisions

### 1. Why SwiftUI over UIKit?

- **Declarative UI**: Easier to reason about state changes
- **Native Charts**: Swift Charts integration seamless
- **Animation**: Built-in animation modifiers for smooth UX
- **Future-proof**: SwiftUI is Apple's strategic UI framework

### 2. Why @Observable over @StateObject/@ObservableObject?

- **Modern Swift**: Observation framework introduced in iOS 17
- **Less boilerplate**: No need for @Published on every property
- **Better performance**: Fine-grained observation reduces re-renders

### 3. Why Cloudflare Worker for Token Exchange?

- **Security**: Client secret never exposed in app binary
- **Decompilation protection**: Reverse engineering won't reveal secrets
- **Flexibility**: Can add rate limiting, logging, monitoring on Worker
- **Strava compliance**: Recommended pattern for mobile OAuth

### 4. Why No Third-Party Libraries?

- **Simplicity**: Fewer dependencies = fewer breaking changes
- **App Store Review**: Native code reduces rejection risk
- **Privacy**: No hidden data collection from SDKs
- **Binary size**: Keeps app download size minimal

### 5. Why In-Memory Token Storage?

- **Quick Start**: Reduces complexity for v1.0
- **Security**: No token leakage via file system or Keychain exploits
- **Trade-off**: User re-authenticates each app launch (acceptable for club use case)
- **Future**: Will migrate to Keychain for persistent sessions

---

## 📞 Support & Contact

**Developer:** Amit Kamat  
**Club:** Desi Cycling Club (DCC)  
**Strava Club:** https://www.strava.com/clubs/212760  
**Support Email:** support@dcc-activities.com (TODO: set up)  

---

## 📜 License & Legal

### Strava API Compliance

This app complies with Strava's API Agreement:
- Displays "Powered by Strava" attribution
- Does not scrape or store data beyond permitted scope
- Respects rate limits (100/15min, 1000/day)
- Only accesses public club activity data

### Open Source Licenses

None — all code is proprietary to DCC Weekly Activities.

### Privacy Policy

A full privacy policy is hosted at: https://dcc-activities.com/privacy (TODO)

Key points:
- No personal data collected beyond what Strava API provides
- No data shared with third parties
- No tracking pixels or analytics by default
- All data processing happens on-device

---

**End of Architecture Documentation**  
**Last Updated:** March 2, 2026  
**Document Version:** 1.0

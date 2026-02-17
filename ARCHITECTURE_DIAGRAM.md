# DCC Weekly Activities - Architecture Diagram

## 🏗️ High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER DEVICES                             │
├──────────────────────────────┬──────────────────────────────────┤
│         iPhone/iPad          │         Apple TV                 │
│            📱                │            📺                    │
│                              │                                  │
│  • Full authentication       │  • Auto-load demo data           │
│  • Biometric security        │  • Display dashboard             │
│  • Real-time sync            │  • No user interaction           │
│  • All features              │  • Read-only view                │
└──────────────┬───────────────┴────────────┬─────────────────────┘
               │                            │
               │                            │
               ▼                            ▼
┌──────────────────────────────────────────────────────────────────┐
│                        APP LAYER                                 │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    DCC_Weekly_ActivitiesApp                │ │
│  │                    (SwiftUI App Protocol)                  │ │
│  │                                                            │ │
│  │  var body: some Scene {                                   │ │
│  │      WindowGroup {                                        │ │
│  │          ContentView()                                    │ │
│  │      }                                                     │ │
│  │  }                                                         │ │
│  └────────────────────────────┬───────────────────────────────┘ │
│                               │                                 │
└───────────────────────────────┼─────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│                     VIEW LAYER (ContentView)                     │
│                                                                  │
│  Platform Detection:                                             │
│  #if os(tvOS) → tvOSContent                                     │
│  #else → iOSContent                                              │
│                                                                  │
│  ┌──────────────────────┐         ┌──────────────────────┐     │
│  │   iOS/iPadOS Flow    │         │    tvOS Flow         │     │
│  ├──────────────────────┤         ├──────────────────────┤     │
│  │ 1. Check auth        │         │ 1. ZStack base       │     │
│  │ 2. Show login OR     │         │ 2. Auto-load data    │     │
│  │    biometric lock OR │         │ 3. Show dashboard    │     │
│  │    main content      │         │                      │     │
│  │ 3. Handle OAuth      │         │ No login required    │     │
│  │ 4. Fetch real data   │         │ Uses mock data       │     │
│  └──────────┬───────────┘         └──────────┬───────────┘     │
│             │                                │                  │
└─────────────┼────────────────────────────────┼──────────────────┘
              │                                │
              ▼                                ▼
┌──────────────────────────────────────────────────────────────────┐
│                    BUSINESS LOGIC LAYER                          │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  StravaAPI   │  │BiometricAuth │  │  TestData    │          │
│  ├──────────────┤  ├──────────────┤  ├──────────────┤          │
│  │ • OAuth      │  │ • Face ID    │  │ • Mock data  │          │
│  │ • Token mgmt │  │ • Touch ID   │  │ • 15 rides   │          │
│  │ • API calls  │  │ • Keychain   │  │ • 8 members  │          │
│  │ • Rate limit │  │ • Auth state │  │              │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                 │                   │
└─────────┼─────────────────┼─────────────────┼───────────────────┘
          │                 │                 │
          ▼                 ▼                 ▼
┌──────────────────────────────────────────────────────────────────┐
│                      DATA LAYER                                  │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Keychain   │  │  App Memory  │  │ Strava Resp  │          │
│  ├──────────────┤  ├──────────────┤  ├──────────────┤          │
│  │ • Token      │  │ • Activities │  │ • JSON data  │          │
│  │   (secure)   │  │ • Stats      │  │ • Network    │          │
│  │              │  │ • State      │  │              │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
          │                                       │
          │                                       │
          ▼                                       ▼
┌──────────────────┐                    ┌──────────────────┐
│  iOS Keychain    │                    │  Strava API      │
│  (System)        │                    │  (External)      │
│                  │                    │                  │
│  Encrypted       │                    │  https://        │
│  Secure          │                    │  strava.com/api  │
└──────────────────┘                    └──────────────────┘
```

---

## 🔄 Data Flow Diagram

### iOS/iPadOS User Flow

```
        START
          │
          ▼
    ┌──────────┐
    │ App      │
    │ Launch   │
    └────┬─────┘
         │
         ▼
    ┌──────────────────┐
    │ Token exists in  │
    │ Keychain?        │
    └─────┬──────┬─────┘
          │      │
       YES│      │NO
          │      │
          ▼      ▼
    ┌─────────┐  ┌──────────┐
    │Show     │  │Show      │
    │Face ID  │  │Login     │
    │Prompt   │  │Screen    │
    └────┬────┘  └────┬─────┘
         │            │
         │            ▼
         │       ┌──────────┐
         │       │User taps │
         │       │"Connect  │
         │       │ Strava"  │
         │       └────┬─────┘
         │            │
         │            ▼
         │       ┌──────────┐
         │       │Open      │
         │       │Safari    │
         │       │OAuth     │
         │       └────┬─────┘
         │            │
         │            ▼
         │       ┌──────────┐
         │       │User      │
         │       │authorizes│
         │       └────┬─────┘
         │            │
         │            ▼
         │       ┌──────────┐
         │       │Redirect  │
         │       │with code │
         │       └────┬─────┘
         │            │
         │            ▼
         │       ┌──────────┐
         │       │Exchange  │
         │       │for token │
         │       └────┬─────┘
         │            │
         │            ▼
         │       ┌──────────┐
         │       │Save to   │
         │       │Keychain  │
         │       └────┬─────┘
         │            │
         └────────────┘
                  │
                  ▼
            ┌──────────┐
            │Fetch club│
            │activities│
            │from      │
            │Strava API│
            └────┬─────┘
                 │
                 ▼
            ┌──────────┐
            │Process   │
            │& Aggregate│
            │data      │
            └────┬─────┘
                 │
                 ▼
            ┌──────────┐
            │Display   │
            │Dashboard │
            └──────────┘
                 │
                 ▼
              END
```

### tvOS User Flow

```
        START
          │
          ▼
    ┌──────────┐
    │ App      │
    │ Launch   │
    └────┬─────┘
         │
         ▼
    ┌──────────────────┐
    │ ZStack renders:  │
    │ • tvMainContent  │
    │ • Loading overlay│
    └────┬─────────────┘
         │
         ▼
    ┌──────────────────┐
    │ .task fires:     │
    │ Auto-load data   │
    └────┬─────────────┘
         │
         ▼
    ┌──────────────────┐
    │ #if DEBUG        │
    │ Load mock data   │
    │ #else            │
    │ Show error msg   │
    └────┬─────────────┘
         │
         ▼
    ┌──────────────────┐
    │ Set isLoading =  │
    │ true             │
    │ (shows overlay)  │
    └────┬─────────────┘
         │
         ▼
    ┌──────────────────┐
    │ Sleep 1 second   │
    │ (simulate        │
    │  network)        │
    └────┬─────────────┘
         │
         ▼
    ┌──────────────────┐
    │ TestData         │
    │ .mockActivities  │
    │ (15 activities)  │
    └────┬─────────────┘
         │
         ▼
    ┌──────────────────┐
    │ Aggregate stats  │
    │ (8 members)      │
    └────┬─────────────┘
         │
         ▼
    ┌──────────────────┐
    │ Set isLoading =  │
    │ false            │
    │ (hides overlay)  │
    └────┬─────────────┘
         │
         ▼
    ┌──────────────────┐
    │ TabView appears  │
    │ • Stats tab      │
    │ • Activities tab │
    └────┬─────────────┘
         │
         ▼
    ┌──────────────────┐
    │ User can         │
    │ navigate         │
    └──────────────────┘
         │
         ▼
       END
```

---

## 📦 Component Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────────┐
│                    ContentView (@MainActor)                 │
│                    Main orchestrator                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  State Variables:                                           │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ @State var activities: [ClubActivity] = []           │  │
│  │ @State var memberStats: [MemberStats] = []           │  │
│  │ @State var isLoading = false                         │  │
│  │ @State var errorMessage: String?                     │  │
│  │ @State var viewMode: ViewMode = .chart              │  │
│  │ @State var dateRange: (start: Date, end: Date)?     │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  Platform-Specific:                                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ #if !os(tvOS)                                        │  │
│  │   @StateObject var stravaAPI = StravaAPI.shared      │  │
│  │   @StateObject var biometricAuth =                   │  │
│  │                    BiometricAuth.shared              │  │
│  │ #endif                                               │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  Methods:                                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ func fetchClubActivities() async                     │  │
│  │ func aggregateMemberStats() -> [MemberStats]         │  │
│  │ func loadMockData() async  // DEBUG only            │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘

          ┌──────────────┬────────────────┬──────────────┐
          │              │                │              │
          ▼              ▼                ▼              ▼
┌──────────────┐  ┌──────────────┐  ┌──────────┐  ┌──────────┐
│ StravaAPI    │  │BiometricAuth │  │ TestData │  │ TVViews  │
│ (Observable) │  │ (Observable) │  │  struct  │  │          │
├──────────────┤  ├──────────────┤  ├──────────┤  ├──────────┤
│              │  │              │  │          │  │          │
│ Properties:  │  │ Properties:  │  │ Static:  │  │ Views:   │
│ • token      │  │ • isAuth     │  │ • mock   │  │ • Stats  │
│ • clubId     │  │ • bioType    │  │   data   │  │ • List   │
│              │  │              │  │          │  │ • Cards  │
│ Methods:     │  │ Methods:     │  │          │  │ • Rows   │
│ • beginOAuth │  │ • auth()     │  │          │  │          │
│ • exchange   │  │ • load()     │  │          │  │          │
│ • fetch      │  │ • save()     │  │          │  │          │
└──────────────┘  └──────────────┘  └──────────┘  └──────────┘
```

---

## 🎯 State Management

### State Flow

```
┌────────────────────────────────────────────────────────────┐
│                    APPLICATION STATE                       │
└────────────────────────────────────────────────────────────┘

AUTHENTICATION STATE (iOS only):
┌──────────────────┐
│ Not Authenticated│
└────────┬─────────┘
         │ User taps login
         ▼
┌──────────────────┐
│ OAuth in Progress│
└────────┬─────────┘
         │ User authorizes
         ▼
┌──────────────────┐
│ Token Saved      │
└────────┬─────────┘
         │ Biometric enabled?
         ▼
┌──────────────────┐
│ Biometric Lock   │
└────────┬─────────┘
         │ User unlocks
         ▼
┌──────────────────┐
│ Authenticated    │
└──────────────────┘

DATA LOADING STATE:
┌──────────────────┐
│ Initial (empty)  │
│ activities = []  │
│ isLoading = false│
└────────┬─────────┘
         │ Start fetch
         ▼
┌──────────────────┐
│ Loading          │
│ isLoading = true │
│ show spinner     │
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
SUCCESS│    ERROR│
    │         │
    ▼         ▼
┌──────────┐ ┌───────────────┐
│ Loaded   │ │ Error         │
│ data     │ │ errorMessage  │
│ ready    │ │ set           │
└──────────┘ └───────────────┘

VIEW MODE STATE:
┌──────────────────┐
│ ViewMode.chart   │ ← Default
└────────┬─────────┘
         │ User switches tab
         ├──► ViewMode.table
         ├──► ViewMode.activities
         └──► Back to chart
```

---

## 🔐 Security Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SECURITY LAYERS                          │
└─────────────────────────────────────────────────────────────┘

Layer 1: Network Security
┌──────────────────────────────────────────────────────────┐
│  HTTPS Only (App Transport Security)                     │
│  ✓ TLS 1.2+                                              │
│  ✓ Certificate pinning (Strava's certs)                 │
│  ✓ No cleartext HTTP allowed                            │
└──────────────────────────────────────────────────────────┘

Layer 2: OAuth 2.0
┌──────────────────────────────────────────────────────────┐
│  Authorization Code Flow                                 │
│  ✓ Client ID / Client Secret                            │
│  ✓ Temporary auth code (single use)                     │
│  ✓ Access token (time-limited)                          │
│  ✓ Refresh token (for renewal)                          │
└──────────────────────────────────────────────────────────┘

Layer 3: iOS Keychain
┌──────────────────────────────────────────────────────────┐
│  Secure Token Storage                                    │
│  ✓ Hardware-encrypted                                    │
│  ✓ App-specific (can't be read by others)               │
│  ✓ Survives app reinstall (if backup enabled)           │
│  ✓ Protected by device passcode                         │
└──────────────────────────────────────────────────────────┘

Layer 4: Biometric Authentication
┌──────────────────────────────────────────────────────────┐
│  Face ID / Touch ID                                      │
│  ✓ User verification before data access                 │
│  ✓ Biometric data never leaves device                   │
│  ✓ Fallback to device passcode                          │
│  ✓ Optional (user preference)                           │
└──────────────────────────────────────────────────────────┘

Layer 5: Data Privacy
┌──────────────────────────────────────────────────────────┐
│  Local-Only Storage                                      │
│  ✓ No backend servers                                    │
│  ✓ No analytics / tracking                              │
│  ✓ No data sharing                                       │
│  ✓ Data deleted on app removal                          │
└──────────────────────────────────────────────────────────┘
```

---

## 🌐 API Architecture

### Strava API Integration

```
┌─────────────────────────────────────────────────────────────┐
│                    StravaAPI Class                          │
└─────────────────────────────────────────────────────────────┘

OAuth Endpoints:
┌──────────────────────────────────────────────────────────┐
│ 1. Authorization                                         │
│    GET https://www.strava.com/oauth/authorize           │
│    Params: client_id, redirect_uri, response_type,      │
│            scope                                         │
│    Returns: Authorization code (via redirect)           │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│ 2. Token Exchange                                        │
│    POST https://www.strava.com/oauth/token              │
│    Body: client_id, client_secret, code, grant_type     │
│    Returns: { access_token, refresh_token, ... }        │
└──────────────────────────────────────────────────────────┘

Data Endpoints:
┌──────────────────────────────────────────────────────────┐
│ 3. Club Activities                                       │
│    GET https://www.strava.com/api/v3/clubs/{id}/        │
│        activities                                        │
│    Headers: Authorization: Bearer {access_token}        │
│    Params: page, per_page (pagination)                  │
│    Returns: [{ athlete, name, distance, ... }]          │
└──────────────────────────────────────────────────────────┘

Rate Limiting:
┌──────────────────────────────────────────────────────────┐
│ Strava Limits:                                           │
│ • 100 requests per 15 minutes                            │
│ • 1000 requests per day                                  │
│                                                          │
│ App Handling:                                            │
│ • Check response headers                                 │
│ • Track request count                                    │
│ • Show user-friendly error if exceeded                   │
└──────────────────────────────────────────────────────────┘
```

---

## 📊 Data Models

```swift
// Core data structures used throughout the app

┌─────────────────────────────────────────────────────────┐
│ ClubActivity                                            │
├─────────────────────────────────────────────────────────┤
│ struct ClubActivity: Identifiable, Codable {            │
│     let id: UUID                                        │
│     let memberName: String                              │
│     let activityName: String                            │
│     let distance: Double        // kilometers           │
│     let date: Date                                      │
│     let averageSpeed: Double    // km/h                 │
│     let elevationGain: Double   // meters               │
│     let movingTime: Int         // seconds              │
│ }                                                       │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ MemberStats                                             │
├─────────────────────────────────────────────────────────┤
│ struct MemberStats: Identifiable {                      │
│     let id: UUID                                        │
│     let memberName: String                              │
│     let totalKM: Double                                 │
│     let totalRides: Int                                 │
│     let avgSpeed: Double                                │
│     let totalElevation: Double                          │
│     let activities: [ClubActivity]                      │
│     var trendEmoji: String {                            │
│         // Calculates based on previous week            │
│     }                                                   │
│ }                                                       │
└─────────────────────────────────────────────────────────┘

Data Transformation:
┌──────────────────┐
│ Strava API JSON  │
└────────┬─────────┘
         │ Decode
         ▼
┌──────────────────┐
│ ClubActivity     │
└────────┬─────────┘
         │ Group by member
         ▼
┌──────────────────┐
│ [Member: [Act]]  │
└────────┬─────────┘
         │ Aggregate
         ▼
┌──────────────────┐
│ MemberStats      │
└────────┬─────────┘
         │ Sort by distance
         ▼
┌──────────────────┐
│ Ranked list      │
└──────────────────┘
```

---

## 🎨 UI Component Tree

```
App
├── WindowGroup
    └── ContentView
        ├── #if os(tvOS)
        │   └── tvOSContent (ZStack)
        │       ├── tvMainContent (Base Layer)
        │       │   ├── Tricolor Header
        │       │   └── Content Area
        │       │       ├── Error State
        │       │       ├── Empty State
        │       │       └── TabView
        │       │           ├── TVMemberStatsView
        │       │           │   ├── Summary Cards Grid
        │       │           │   │   ├── TVStatCard (Distance)
        │       │           │   │   ├── TVStatCard (Rides)
        │       │           │   │   ├── TVStatCard (Elevation)
        │       │           │   │   └── TVStatCard (Members)
        │       │           │   └── Top Performers List
        │       │           │       └── TVMemberRow (x8)
        │       │           └── TVActivitiesListView
        │       │               └── LazyVStack
        │       │                   └── TVActivityRow (x15)
        │       └── tvLoadingScreen (Overlay)
        │           └── Branded loading UI
        │
        └── #else (iOS/iPadOS)
            └── iOSContent (NavigationView)
                ├── Biometric Lock Screen
                │   └── Face ID/Touch ID prompt
                ├── Login Screen
                │   ├── Photo carousel
                │   ├── App branding
                │   └── "Connect with Strava" button
                └── Main Content
                    ├── Tricolor Header
                    ├── Picker (Chart/Table/Activities)
                    ├── Chart View
                    │   ├── Summary Cards
                    │   └── MemberStatsChartView
                    ├── Table View
                    │   └── MemberStatsTableView
                    └── Activities List
                        └── ActivityRow
```

---

## 🔄 Async/Await Concurrency Model

```
┌─────────────────────────────────────────────────────────┐
│                   Main Actor                            │
│                   (UI Thread)                           │
└───────────────────┬─────────────────────────────────────┘
                    │
      ┌─────────────┼─────────────┐
      │             │             │
      ▼             ▼             ▼
┌──────────┐  ┌──────────┐  ┌──────────┐
│ View     │  │ State    │  │ UI       │
│ Updates  │  │ Changes  │  │ Events   │
└──────────┘  └──────────┘  └────┬─────┘
                                  │
                                  │ User interaction
                                  ▼
                         ┌────────────────┐
                         │ Task { }       │
                         │ (Background)   │
                         └────────┬───────┘
                                  │
                ┌─────────────────┼─────────────────┐
                │                 │                 │
                ▼                 ▼                 ▼
        ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
        │ Network call │  │ Data process │  │ Mock load    │
        │ (async)      │  │ (async)      │  │ (async)      │
        └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
               │                 │                 │
               └─────────────────┼─────────────────┘
                                 │
                                 ▼
                        ┌────────────────┐
                        │ await result   │
                        └────────┬───────┘
                                 │
                                 ▼
                        ┌────────────────┐
                        │ MainActor.run  │
                        │ Update @State  │
                        └────────┬───────┘
                                 │
                                 ▼
                        ┌────────────────┐
                        │ SwiftUI reacts │
                        │ View refreshes │
                        └────────────────┘

Example Flow:
1. User taps refresh button (Main Actor)
2. Task { await fetchClubActivities() } (spawns)
3. Network call on background thread
4. Data received
5. MainActor.run { self.activities = data }
6. SwiftUI detects @State change
7. View automatically re-renders
```

---

## 📋 Summary

This architecture provides:

✅ **Clear separation of concerns**
- Views handle UI
- Services handle logic
- Models handle data

✅ **Platform-specific optimization**
- iOS: Full authentication flow
- tvOS: Auto-loading dashboard

✅ **Secure data handling**
- Keychain for tokens
- Biometric protection
- No data leakage

✅ **Modern Swift patterns**
- SwiftUI declarative UI
- Async/await concurrency
- Observable objects
- State management

✅ **Scalable & maintainable**
- Easy to add features
- Well-documented
- Testable components

---

*For detailed implementation, see source files in `/repo`*

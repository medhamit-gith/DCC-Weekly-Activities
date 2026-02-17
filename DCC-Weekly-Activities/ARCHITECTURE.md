# 🏗️ App Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        DCC Weekly Activities                 │
│                          iOS/iPadOS/tvOS                     │
└─────────────────────────────────────────────────────────────┘
                                │
                                │
                    ┌───────────┴───────────┐
                    │                       │
            ┌───────▼────────┐     ┌───────▼────────┐
            │   User Views   │     │  Authentication │
            │                │     │                 │
            │  • ContentView │     │ • StravaAPI    │
            │  • ChartsView  │     │ • BiometricAuth│
            │  • TableView   │     │ • Keychain     │
            │  • TVViews     │     │                │
            └───────┬────────┘     └───────┬────────┘
                    │                      │
                    │       ┌──────────────┘
                    │       │
            ┌───────▼───────▼────┐
            │   Business Logic    │
            │                     │
            │ • Data Aggregation  │
            │ • MemberStats       │
            │ • Calculations      │
            │ • Sorting/Filtering │
            └───────┬─────────────┘
                    │
        ┌───────────┼───────────┐
        │           │           │
  ┌─────▼────┐ ┌───▼───┐ ┌────▼─────┐
  │ Strava   │ │ Local │ │  Error   │
  │   API    │ │ Cache │ │ Handling │
  │          │ │       │ │          │
  │ • OAuth  │ │ • JSON│ │ • AppErr │
  │ • Fetch  │ │ • User│ │ • Retry  │
  │ • Parse  │ │ Defs  │ │ • Msgs   │
  └──────────┘ └───────┘ └──────────┘
```

---

## Data Flow

### 1. App Launch Flow

```
App Launch
    │
    ├──> Check for Saved Token (Keychain)
    │       │
    │       ├──> Token Exists?
    │       │       │
    │       │       ├─YES─> Biometric Auth
    │       │       │           │
    │       │       │           ├─Success─> Auto Fetch Data
    │       │       │           │
    │       │       │           └─Fail───> Login Screen
    │       │       │
    │       │       └─NO──> Login Screen
    │       │
    │       └──> Show Login Screen
    │
    └──> Load UI
```

### 2. Authentication Flow

```
User Taps "Connect with Strava"
    │
    ├──> Open Strava OAuth (Safari/Web)
    │
    ├──> User Authorizes App
    │
    ├──> Redirect to App (dcc-activities://)
    │
    ├──> Exchange Code for Token
    │       │
    │       ├─Success─> Save Token to Keychain
    │       │               │
    │       │               ├──> Enable Biometric Auth
    │       │               │
    │       │               └──> Fetch Activities
    │       │
    │       └─Fail───> Show Error, Retry
    │
    └──> Display Main View
```

### 3. Data Fetch Flow

```
Fetch Activities Request
    │
    ├──> Check Rate Limit
    │       │
    │       ├─OK─────> Continue
    │       │
    │       └─Limit──> Wait / Show Error
    │
    ├──> Check Network
    │       │
    │       ├─Online─> Continue
    │       │
    │       └─Offline─> Load Cache
    │
    ├──> Make API Request
    │       │
    │       ├─Success─> Parse Response
    │       │               │
    │       │               ├──> Validate Data
    │       │               │
    │       │               ├──> Cache Locally
    │       │               │
    │       │               └──> Aggregate Stats
    │       │
    │       └─Error──> Handle Error
    │                       │
    │                       ├──> Try Cache
    │                       │
    │                       └──> Show Error
    │
    └──> Update UI
```

### 4. Statistics Aggregation Flow

```
Activities Array
    │
    ├──> Group by Member Name
    │       │
    │       └──> Dictionary<String, [Activity]>
    │
    ├──> For Each Member:
    │       │
    │       ├──> Calculate Total Distance
    │       ├──> Count Total Rides
    │       ├──> Calculate Average Speed
    │       ├──> Sum Elevation Gain
    │       └──> Determine Trend (vs previous week)
    │
    ├──> Create MemberStats Objects
    │
    ├──> Sort by Selected Metric
    │
    └──> Display in Views
```

---

## Component Relationships

```
┌────────────────────────────────────────────────────────┐
│                    ContentView                          │
│  (Main coordinator, manages app state)                  │
└─────────┬──────────────────────────────────────────────┘
          │
          ├──────────────┬──────────────┬─────────────┐
          │              │              │             │
    ┌─────▼─────┐  ┌─────▼─────┐  ┌────▼────┐  ┌─────▼─────┐
    │  Login    │  │  Charts   │  │  Table  │  │Activities │
    │  Screen   │  │  View     │  │  View   │  │   List    │
    └───────────┘  └───────────┘  └─────────┘  └───────────┘
                          │
                          ├────────────┬────────────┐
                          │            │            │
                    ┌─────▼─────┐ ┌───▼───┐  ┌─────▼─────┐
                    │ Bar Chart │ │ Pie   │  │ Stat Card │
                    │           │ │ Chart │  │           │
                    └───────────┘ └───────┘  └───────────┘
```

---

## State Management

```
┌──────────────────────────────────────────────────┐
│              App State (ContentView)              │
├──────────────────────────────────────────────────┤
│  @StateObject var stravaAPI: StravaAPI           │
│  @StateObject var biometricAuth: BiometricAuth   │
│  @State var activities: [ClubActivity]           │
│  @State var memberStats: [MemberStats]           │
│  @State var isLoading: Bool                      │
│  @State var errorMessage: String?                │
│  @State var viewMode: ViewMode                   │
│  @State var dateRange: (Date, Date)?             │
└──────────────────────────────────────────────────┘
           │
           ├──> Passed to Child Views via Properties
           │
           └──> Updated by Async Operations
```

---

## Security Layers

```
┌─────────────────────────────────────────────────┐
│           User Interface (SwiftUI)               │
└─────────────────┬───────────────────────────────┘
                  │
          ┌───────▼────────┐
          │  Biometric     │  Face ID / Touch ID
          │  Authentication│  (LocalAuthentication)
          └───────┬────────┘
                  │
          ┌───────▼────────┐
          │    Keychain    │  Encrypted Token Storage
          │    Storage     │  (Security Framework)
          └───────┬────────┘
                  │
          ┌───────▼────────┐
          │  HTTPS/OAuth   │  Secure Communication
          │  (URLSession)  │  with Strava API
          └────────────────┘
```

---

## File Organization

```
DCC-Weekly-Activities/
│
├── 📱 App Entry Points
│   ├── DCCClubActivitiesApp.swift      (iOS/iPadOS @main)
│   └── DCC_Weekly_ActivitiesApp.swift  (Container)
│
├── 🎨 Views
│   ├── ContentView.swift               (Main view, state management)
│   ├── MemberStatsChartView.swift      (Charts visualization)
│   ├── MemberStatsTableView.swift      (Table view)
│   ├── TVViews.swift                   (Apple TV specific)
│   └── ActivityRow.swift               (Individual activity cell)
│
├── 📊 Models
│   ├── ClubActivity.swift              (Activity data model)
│   └── MemberStats.swift               (Aggregated statistics)
│
├── 🔐 Services
│   ├── StravaAPI.swift                 (API integration)
│   ├── BiometricAuth.swift             (Authentication)
│   └── DataCache.swift                 (Local caching)
│
├── ⚙️ Configuration
│   ├── AppConfiguration.swift          (App settings, constants)
│   ├── ErrorHandling.swift             (Error types, handling)
│   └── Analytics.swift                 (Usage tracking)
│
├── 🧪 Testing
│   ├── TestData.swift                  (Mock data)
│   └── MemberStatsTests.swift          (Unit tests)
│
└── 📚 Documentation
    ├── README.md                       (Project overview)
    ├── APP_STORE_CHECKLIST.md         (Submission guide)
    ├── PRODUCTION_IMPROVEMENTS.md      (Code improvements)
    ├── APP_STORE_LISTING.md           (Marketing content)
    └── PrivacyPolicy.md               (Privacy policy)
```

---

## API Integration Points

```
┌────────────────────────────────────────────────────┐
│                  Strava API                         │
├────────────────────────────────────────────────────┤
│                                                     │
│  1. OAuth Authorization                             │
│     GET /oauth/mobile/authorize                     │
│     ↓                                               │
│     Returns: Authorization Code                     │
│                                                     │
│  2. Token Exchange                                  │
│     POST /api/v3/oauth/token                       │
│     ↓                                               │
│     Returns: Access Token, Refresh Token            │
│                                                     │
│  3. Fetch Club Activities                           │
│     GET /api/v3/clubs/{id}/activities               │
│     ↓                                               │
│     Returns: Array of Activities (JSON)             │
│                                                     │
│  4. Token Refresh (when expired)                    │
│     POST /api/v3/oauth/token                       │
│     ↓                                               │
│     Returns: New Access Token                       │
│                                                     │
└────────────────────────────────────────────────────┘

Rate Limits:
├── 100 requests per 15 minutes (per application)
├── 1,000 requests per day (per application)
└── 429 Too Many Requests (if exceeded)
```

---

## View Hierarchy

```
NavigationView
└── ContentView
    │
    ├── iOS/iPadOS
    │   ├── Biometric Lock Screen
    │   │   └── Unlock Button
    │   │
    │   ├── Login Screen
    │   │   ├── Club Photos Carousel
    │   │   ├── App Branding
    │   │   └── Connect Button
    │   │
    │   └── Main Content
    │       ├── Tricolor Header
    │       ├── Date Range Display
    │       ├── View Mode Picker
    │       │   ├── Charts
    │       │   ├── Table
    │       │   └── Activities
    │       │
    │       └── Selected View
    │           ├── MemberStatsChartView
    │           │   ├── Metric Picker
    │           │   ├── Summary Cards
    │           │   ├── Bar Chart
    │           │   ├── Pie Chart
    │           │   └── Rankings List
    │           │
    │           ├── MemberStatsTableView
    │           │   └── Sortable Table
    │           │
    │           └── Activities List
    │               └── ActivityRow (foreach)
    │
    └── tvOS
        ├── Login Screen
        │   ├── App Branding
        │   └── Login Button
        │
        └── Main Content
            ├── Tricolor Header
            └── TabView
                ├── Stats Tab
                └── Activities Tab
```

---

## Performance Considerations

```
┌─────────────────────────────────────────────────────┐
│              Performance Optimizations               │
├─────────────────────────────────────────────────────┤
│                                                      │
│  1. Async/Await for Network Calls                   │
│     • Non-blocking UI                               │
│     • Proper error propagation                      │
│                                                      │
│  2. Local Data Caching                              │
│     • Reduce API calls                              │
│     • Faster app launch                             │
│     • Offline support                               │
│                                                      │
│  3. Lazy Loading                                    │
│     • LazyVGrid for summary cards                   │
│     • List for activities                           │
│     • Only render visible items                     │
│                                                      │
│  4. Efficient Sorting                               │
│     • Computed properties                           │
│     • Only sort when needed                         │
│     • Cache sorted results                          │
│                                                      │
│  5. Image Optimization                              │
│     • SF Symbols (vector icons)                     │
│     • Compressed assets                             │
│     • Appropriate resolutions                       │
│                                                      │
│  6. Memory Management                               │
│     • Weak references where needed                  │
│     • Proper deallocation                           │
│     • No retain cycles                              │
│                                                      │
└─────────────────────────────────────────────────────┘
```

---

## Error Handling Strategy

```
┌────────────────────────────────────────┐
│         Error Handling Layers          │
├────────────────────────────────────────┤
│                                        │
│  1. Network Layer                      │
│     • URLError handling                │
│     • HTTP status codes                │
│     • Timeout handling                 │
│     • Rate limiting detection          │
│     ↓                                  │
│                                        │
│  2. API Response Layer                 │
│     • JSON parsing errors              │
│     • Missing data handling            │
│     • Invalid response format          │
│     ↓                                  │
│                                        │
│  3. Business Logic Layer               │
│     • Validation errors                │
│     • Calculation errors               │
│     • State inconsistencies            │
│     ↓                                  │
│                                        │
│  4. Presentation Layer                 │
│     • User-friendly messages           │
│     • Recovery suggestions             │
│     • Retry mechanisms                 │
│     • Graceful degradation             │
│                                        │
└────────────────────────────────────────┘
```

---

## Deployment Pipeline

```
Development
    ↓
  Testing
    ↓
Code Review
    ↓
Local Build
    ↓
TestFlight Beta
    ↓
Beta Feedback
    ↓
Bug Fixes
    ↓
Release Build
    ↓
App Store Submission
    ↓
App Review
    ↓
┌─Release─┐    ┌─Rejection─┐
│ Approve │    │   Fix      │
│    ↓    │    │    ↓       │
│  Live!  │    │  Resubmit  │
└─────────┘    └────┬───────┘
                    ↓
              (Back to Review)
```

---

## Future Architecture Considerations

### Phase 1 (Current - v1.0)
- ✅ Basic statistics display
- ✅ Strava integration
- ✅ Multiple view modes
- ✅ Biometric auth

### Phase 2 (v1.1-1.2)
- [ ] Historical data (Core Data or SwiftData)
- [ ] Push notifications (APNs)
- [ ] Widget support (WidgetKit)
- [ ] watchOS companion app

### Phase 3 (v2.0+)
- [ ] Multi-club support
- [ ] Social features (CloudKit)
- [ ] Advanced analytics
- [ ] AI insights (Core ML)

---

This architecture is designed to be:
- ✅ **Scalable**: Easy to add features
- ✅ **Maintainable**: Clear separation of concerns
- ✅ **Testable**: Isolated components
- ✅ **Performant**: Efficient data flow
- ✅ **Secure**: Multiple security layers

# DCC Weekly Activities - Data Flow Diagram

## 📱 iOS/iPadOS Data Flow

### First Time Launch (No Authentication)

```
┌────────────────────────────────────────────────────────────────┐
│                      🚀 App Launches                           │
└────────────────────────────┬───────────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │  Check Keychain│
                    │  for saved     │
                    │  Strava token  │
                    └────────┬───────┘
                             │
                  ┌──────────┴──────────┐
                  │                     │
             No Token               Has Token
                  │                     │
                  ▼                     ▼
        ┌─────────────────┐   ┌─────────────────┐
        │  Login Screen   │   │ Biometric Auth  │
        │  with DCC       │   │ Screen (Face ID │
        │  branding       │   │  / Touch ID)    │
        └────────┬────────┘   └────────┬────────┘
                 │                     │
          [User taps                [User unlocks
           "Connect with             with biometric]
            Strava"]                     │
                 │                     │
                 ▼                     ▼
        ┌─────────────────┐   ┌─────────────────┐
        │  OAuth Web      │   │ Load Token from │
        │  Browser Opens  │   │ Keychain        │
        │  (Strava Login) │   │                 │
        └────────┬────────┘   └────────┬────────┘
                 │                     │
          [User enters              [Token loaded]
           Strava                       │
           credentials]                 │
                 │                     │
                 ▼                     │
        ┌─────────────────┐           │
        │ User Authorizes │           │
        │ App Access      │           │
        └────────┬────────┘           │
                 │                     │
          [Strava redirects            │
           back to app with            │
           authorization code]         │
                 │                     │
                 ▼                     │
        ┌─────────────────┐           │
        │ App Exchanges   │           │
        │ Code for Access │           │
        │ Token           │           │
        └────────┬────────┘           │
                 │                     │
          [Store in Keychain           │
           with biometric              │
           protection]                 │
                 │                     │
                 └──────────┬──────────┘
                            │
                            ▼
                   ┌────────────────┐
                   │  Main Dashboard│
                   └────────┬───────┘
                            │
                            ▼
```

### Main Dashboard - Data Loading

```
                   ┌────────────────┐
                   │  Main Content  │
                   │  View Appears  │
                   └────────┬───────┘
                            │
                            ▼
                   ┌────────────────┐
                   │ Show Loading   │
                   │ Spinner        │
                   └────────┬───────┘
                            │
                     [Calculate date
                      range: Last Monday
                      to Last Sunday]
                            │
                            ▼
        ┌──────────────────────────────────────────┐
        │  Make API Request to Strava             │
        │                                          │
        │  GET /clubs/{CLUB_ID}/activities        │
        │  Authorization: Bearer {access_token}   │
        │  Query params:                          │
        │    - per_page: 200                      │
        │    - after: {monday_timestamp}          │
        │    - before: {sunday_timestamp}         │
        └──────────────────┬───────────────────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │  Strava API Response   │
              │  (JSON Array)          │
              └────────────┬───────────┘
                           │
                 ┌─────────┴─────────┐
                 │                   │
            Success               Error
                 │                   │
                 ▼                   ▼
    ┌────────────────────┐  ┌──────────────┐
    │ Parse JSON into    │  │ Show Error   │
    │ ClubActivity       │  │ Message      │
    │ objects            │  │ with Retry   │
    └────────┬───────────┘  │ Button       │
             │              └──────────────┘
             ▼
    ┌────────────────────┐
    │ Group Activities   │
    │ by Member Name     │
    └────────┬───────────┘
             │
             ▼
    ┌────────────────────┐
    │ Calculate Stats    │
    │ for Each Member:   │
    │  - Total Distance  │
    │  - Total Rides     │
    │  - Avg Speed       │
    │  - Total Elevation │
    │  - Longest Ride    │
    └────────┬───────────┘
             │
             ▼
    ┌────────────────────┐
    │ Sort Members by    │
    │ Total Distance     │
    │ (Descending)       │
    └────────┬───────────┘
             │
             ▼
    ┌────────────────────┐
    │ Update UI:         │
    │  - Hide Loading    │
    │  - Show Stats      │
    │  - Show Activities │
    └────────┬───────────┘
             │
             ▼
    ┌────────────────────┐
    │ User Can Now View: │
    │                    │
    │  📊 Charts Tab     │
    │  📋 Table Tab      │
    │  📝 Activities Tab │
    └────────────────────┘
```

---

## 📺 tvOS Data Flow (Debug Mode)

### Simplified Flow - No Authentication

```
┌────────────────────────────────────────────────────────────────┐
│                   📺 tvOS App Launches                         │
└────────────────────────────┬───────────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │ ContentView    │
                    │ Appears        │
                    └────────┬───────┘
                             │
                   [Check if activities
                    array is empty]
                             │
                             ▼
                    ┌────────────────┐
                    │ Activities     │
                    │ Empty? → YES   │
                    └────────┬───────┘
                             │
                   [Automatically
                    trigger .task
                    modifier]
                             │
                             ▼
        ┌──────────────────────────────────────────┐
        │  loadMockData() Function Called         │
        └──────────────────┬───────────────────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │ Set isLoading = true   │
              │ Show Loading Spinner   │
              └────────────┬───────────┘
                           │
                 [Simulate network
                  delay: 1 second]
                           │
                           ▼
              ┌────────────────────────┐
              │ Load 15 Mock           │
              │ Activities from        │
              │ TestData.swift         │
              └────────────┬───────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │ Calculate Member Stats │
              │ (Same as iOS logic)    │
              └────────────┬───────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │ Set isLoading = false  │
              │ Update UI with Data    │
              └────────────┬───────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │ Show Main Dashboard    │
              │ with Tabs:             │
              │  📊 Stats              │
              │  📝 Activities         │
              └────────────────────────┘
```

**⏱️ Total Time:** ~2 seconds from launch to data display

---

## 🔄 User Interactions

### iOS - View Mode Switching

```
        User is on Dashboard
                │
                ▼
       ┌────────────────┐
       │ Picker at Top  │
       │ [Chart|Table|  │
       │  Activities]   │
       └────────┬───────┘
                │
        [User taps option]
                │
       ┌────────┴──────────┬──────────────┐
       │                   │              │
   Chart Selected      Table Selected  Activities
       │                   │           Selected
       ▼                   ▼              │
┌──────────────┐   ┌──────────────┐      ▼
│ Show Bar     │   │ Show Sorted  │  ┌──────────────┐
│ Chart with   │   │ Table with   │  │ Show List of │
│ Top Members  │   │ All Members  │  │ Individual   │
│              │   │ and Stats    │  │ Activities   │
└──────────────┘   └──────────────┘  └──────────────┘
```

### iOS - Refresh Data

```
        User on Dashboard
                │
                ▼
       ┌────────────────┐
       │ Taps Refresh   │
       │ Button (↻)     │
       └────────┬───────┘
                │
                ▼
       [Trigger fetchClubActivities()]
                │
                └──> [Same flow as initial load]
```

### iOS - Logout

```
        User on Dashboard
                │
                ▼
       ┌────────────────┐
       │ Taps "Log Out" │
       └────────┬───────┘
                │
                ▼
       ┌────────────────┐
       │ Delete Token   │
       │ from Keychain  │
       └────────┬───────┘
                │
                ▼
       ┌────────────────┐
       │ Clear All Data:│
       │  - activities  │
       │  - memberStats │
       │  - dateRange   │
       └────────┬───────┘
                │
                ▼
       ┌────────────────┐
       │ Return to      │
       │ Login Screen   │
       └────────────────┘
```

### tvOS - Tab Navigation

```
        User on Stats Tab
                │
       [Presses Down Arrow
        to reach Tab Bar]
                │
                ▼
       ┌────────────────┐
       │ Focus on       │
       │ Tab Bar        │
       └────────┬───────┘
                │
       [Right Arrow to
        Activities Tab]
                │
                ▼
       ┌────────────────┐
       │ Press Select   │
       │ (Return Key)   │
       └────────┬───────┘
                │
                ▼
       ┌────────────────┐
       │ Switch to      │
       │ Activities Tab │
       │                │
       │ Shows List of  │
       │ All 15 Rides   │
       └────────────────┘
```

---

## 🗄️ Data Structures

### How Data Flows Through the App

```
┌─────────────────────────────────────────────────────────────┐
│                     Strava API                              │
│  (Raw JSON data from club activities endpoint)              │
└────────────────────────────┬────────────────────────────────┘
                             │
                  [Decode into Swift objects]
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│              Array of ClubActivity Objects                  │
│                                                             │
│  struct ClubActivity {                                      │
│      let memberName: String       // "Amit K"              │
│      let activityName: String     // "Morning Ride"        │
│      let distance: Double         // 45.2 km               │
│      let date: Date              // 2026-02-12            │
│      let averageSpeed: Double    // 28.5 km/h             │
│      let elevationGain: Double   // 320 m                 │
│      let movingTime: Int         // 5700 seconds           │
│  }                                                          │
└────────────────────────────┬────────────────────────────────┘
                             │
              [Group by memberName and aggregate]
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│              Array of MemberStats Objects                   │
│                                                             │
│  struct MemberStats {                                       │
│      let memberName: String      // "Amit K"               │
│      let totalKM: Double         // 146.4 km               │
│      let totalRides: Int         // 3 rides                │
│      let avgSpeed: Double        // 27.5 km/h              │
│      let totalElevation: Double  // 950 m                  │
│      let longestRide: Double     // 62.5 km                │
│      let trendEmoji: String      // "🔥" or "📈" etc       │
│  }                                                          │
│                                                             │
│  [Sorted by totalKM in descending order]                    │
└────────────────────────────┬────────────────────────────────┘
                             │
                [Used to render UI components]
                             │
               ┌─────────────┴─────────────┐
               │                           │
               ▼                           ▼
┌──────────────────────────┐   ┌──────────────────────────┐
│   Chart Views            │   │   List/Table Views       │
│                          │   │                          │
│  - Bar Chart             │   │  - Sorted Table          │
│  - Summary Cards         │   │  - Activity Rows         │
│  - Leaderboard           │   │  - Detail Views          │
└──────────────────────────┘   └──────────────────────────┘
```

---

## 🔐 Security & Storage

### How Authentication is Secured

```
┌─────────────────────────────────────────────────────────────┐
│                    User Authenticates                       │
│              (via Strava OAuth web login)                   │
└────────────────────────────┬────────────────────────────────┘
                             │
                [Receive Access Token
                 from Strava API]
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│               iOS Keychain Storage                          │
│  🔒 Hardware-encrypted secure storage                       │
│                                                             │
│  Key: "stravaAccessToken"                                   │
│  Value: "abc123xyz..." (encrypted)                          │
│  Protected by: Device biometrics (Face ID / Touch ID)       │
│                                                             │
│  ✅ Survives app deletion? NO                               │
│  ✅ Survives app updates? YES                               │
│  ✅ Shared between devices? NO                              │
│  ✅ Accessible without biometric? NO                        │
└────────────────────────────┬────────────────────────────────┘
                             │
              [On subsequent app launches]
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│              Biometric Authentication Check                 │
│                                                             │
│  1. App checks if token exists in Keychain                  │
│  2. If found, prompt for Face ID / Touch ID                 │
│  3. On success, load token from Keychain                    │
│  4. On failure, show lock screen                            │
│                                                             │
│  🔒 Token never stored in plain text                        │
│  🔒 Token never logged to console                           │
│  🔒 Token only in memory during app session                 │
└─────────────────────────────────────────────────────────────┘
```

### Data Privacy

```
┌─────────────────────────────────────────────────────────────┐
│              What Data is Stored Where                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  📱 iOS Keychain (Encrypted)                                │
│     └─ Strava access token only                            │
│                                                             │
│  💾 App Memory (Temporary)                                  │
│     └─ Activity data                                        │
│     └─ Member statistics                                    │
│     └─ Chart data                                           │
│                                                             │
│  ☁️ Cloud / Servers (NONE!)                                 │
│     └─ No data sent to any backend                         │
│     └─ No analytics collected                               │
│     └─ No tracking                                          │
│                                                             │
│  🗑️ On App Deletion                                         │
│     └─ Everything is deleted                                │
│     └─ No trace left on device                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Data Aggregation Logic

### How Member Stats are Calculated

```
Input: Array of ClubActivity objects
       (All activities from last week)
             │
             ▼
┌────────────────────────────────────────────────────────────┐
│  Step 1: Group by Member Name                              │
│                                                            │
│  [                                                         │
│    "Amit K" -> [activity1, activity2, activity3],         │
│    "Priya S" -> [activity1, activity2],                   │
│    "Raj M" -> [activity1, activity2, activity3],          │
│    ...                                                     │
│  ]                                                         │
└────────────────────────────┬───────────────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────┐
│  Step 2: For Each Member, Calculate:                       │
│                                                            │
│  • Total Distance    = sum of all activity.distance       │
│  • Total Rides       = count of activities                │
│  • Avg Speed         = average of activity.averageSpeed   │
│  • Total Elevation   = sum of activity.elevationGain      │
│  • Longest Ride      = max of activity.distance           │
│  • Total Time        = sum of activity.movingTime         │
│                                                            │
│  Example for "Amit K":                                     │
│    activities = [45.2km, 38.7km, 62.5km]                  │
│    totalKM = 45.2 + 38.7 + 62.5 = 146.4 km               │
│    totalRides = 3                                          │
│    avgSpeed = (28.5 + 26.3 + 27.8) / 3 = 27.5 km/h       │
└────────────────────────────┬───────────────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────┐
│  Step 3: Sort by Total Distance (Descending)               │
│                                                            │
│  1. Amit K     - 146.4 km  🥇                             │
│  2. Anita P    - 103.9 km  🥈                             │
│  3. Neha D     - 77.0 km   🥉                             │
│  4. Raj M      - 69.3 km                                  │
│  5. Priya S    - 58.0 km                                  │
│  ...                                                       │
└────────────────────────────┬───────────────────────────────┘
                             │
                             ▼
                    Output: Sorted Array of
                    MemberStats Objects
                    (Ready for UI display)
```

---

## 🎨 UI Rendering Flow

### From Data to Screen

```
    MemberStats Array
           │
           ▼
┌──────────────────────┐
│ ContentView          │
│ (Main Container)     │
└──────────┬───────────┘
           │
    [User selects view mode]
           │
    ┌──────┴──────────┬──────────────┐
    │                 │              │
    ▼                 ▼              ▼
Chart View       Table View    Activities View
    │                 │              │
    ▼                 ▼              ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ ForEach     │  │ List        │  │ List        │
│ memberStats │  │ ForEach     │  │ ForEach     │
└──────┬──────┘  │ memberStats │  │ activities  │
       │         └──────┬──────┘  └──────┬──────┘
       │                │                │
       ▼                ▼                ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ Bar Shape   │  │ Table Row   │  │ Activity    │
│ with        │  │ with stats  │  │ Row with    │
│ height =    │  │ displayed   │  │ details     │
│ totalKM     │  │             │  │             │
└─────────────┘  └─────────────┘  └─────────────┘
```

---

## ⚡ Performance Optimizations

### How the App Stays Fast

```
┌────────────────────────────────────────────────────────────┐
│  API Call Optimization                                     │
├────────────────────────────────────────────────────────────┤
│  ✅ Only fetches last week's data (not all history)        │
│  ✅ Uses pagination (per_page: 200, but filtered by dates) │
│  ✅ Caches data in memory until manual refresh             │
│  ✅ Uses Swift async/await for non-blocking requests       │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│  Data Processing Optimization                              │
├────────────────────────────────────────────────────────────┤
│  ✅ Single pass through activities for grouping            │
│  ✅ Swift's Dictionary(grouping:) for efficient grouping   │
│  ✅ Calculations done once, stored in MemberStats          │
│  ✅ Sorted once after aggregation                          │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│  UI Rendering Optimization                                 │
├────────────────────────────────────────────────────────────┤
│  ✅ LazyVStack/LazyVGrid for large lists                   │
│  ✅ SwiftUI automatic view diffing and updates             │
│  ✅ Minimal redraws with @State and @Published             │
│  ✅ Identifiable objects for efficient list updates        │
└────────────────────────────────────────────────────────────┘
```

---

## 🔄 Complete End-to-End Flow Summary

### iOS App - Complete Journey

```
1. Launch App
     ↓
2. Check for saved token in Keychain
     ↓
3a. No Token                      3b. Has Token
     ↓                                 ↓
4a. Show Login Screen            4b. Show Biometric Lock
     ↓                                 ↓
5a. User taps Connect            5b. User authenticates
     ↓                                 ↓
6a. OAuth flow                   6b. Load token from Keychain
     ↓                                 ↓
7a. Receive & save token             │
     └───────────────┬────────────────┘
                     ↓
8. Fetch last week's activities from Strava API
     ↓
9. Parse JSON into ClubActivity objects
     ↓
10. Group activities by member
     ↓
11. Calculate statistics for each member
     ↓
12. Sort by total distance
     ↓
13. Display dashboard with data
     ↓
14. User can:
    • Switch view modes (Chart/Table/Activities)
    • Refresh data
    • Log out
```

### tvOS App - Complete Journey

```
1. Launch App
     ↓
2. Check if activities array is empty
     ↓
3. Empty → Automatically trigger data load
     ↓
4. Load mock data from TestData.swift
     ↓
5. Calculate statistics (same as iOS)
     ↓
6. Display dashboard immediately
     ↓
7. User can:
    • Navigate between Stats and Activities tabs
    • Scroll through lists
```

---

This diagram explains the complete data flow for both novice and technical users! 🚴‍♂️📊

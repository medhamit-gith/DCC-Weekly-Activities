# Screen Reference Guide
## DCC Weekly Activities App

**Last Updated**: February 22, 2026

Use these standardized screen names throughout development, documentation, and issue tracking.

---

## 📱 Screen Naming Convention

All screens follow the pattern: `[Function][Type]`
- **Function**: What the screen does (Login, Dashboard, Activity, etc.)
- **Type**: Screen, Tab, View, Card, Prompt, etc.

---

## 🔐 Authentication Flow

| Screen Name | Purpose | File | Platform |
|-------------|---------|------|----------|
| `LoginScreen` | Initial Strava OAuth connection | `LoginView.swift` | iOS, iPadOS |
| `BiometricGateScreen` | Face ID/Touch ID authentication | `BiometricGateView.swift` | iOS, iPadOS |
| `WebAuthScreen` | Strava authorization web view | `SafariView` (system) | iOS, iPadOS |

### Screen Flow
```
App Launch → LoginScreen → WebAuthScreen → BiometricGateScreen → DashboardScreen
```

---

## 📊 Main Dashboard (iOS/iPadOS)

| Screen Name | Purpose | File | Navigation |
|-------------|---------|------|-----------|
| `DashboardScreen` | Main container with tab navigation | `WeeklyDashboardView.swift` | Root |
| `ChartsTab` | Visual statistics (bar/pie charts) | `MemberStatsChartView.swift` | Tab 1 |
| `TableTab` | Sortable data table | `MemberStatsTableView.swift` | Tab 2 |
| `ActivitiesTab` | Chronological activity list | `ActivitiesListView.swift` | Tab 3 |

### Tab Structure
```
DashboardScreen
├── ChartsTab (default)
├── TableTab
└── ActivitiesTab
```

---

## 🔍 Detail Views

| Screen Name | Purpose | File | Presented From |
|-------------|---------|------|----------------|
| `ActivityDetailScreen` | Individual activity details | `ActivityDetailView.swift` | `ChartsTab`, `ActivitiesTab` |
| `MemberDetailScreen` | Single member's complete stats | `MemberDetailView.swift` | `ChartsTab`, `TableTab` |
| `ExpandedLeaderboardScreen` | Full member list (beyond top 10) | `ExpandedLeaderboardView.swift` | `ChartsTab` |

### Navigation Flow
```
ChartsTab → Tap Member → MemberDetailScreen
ChartsTab → Tap Activity → ActivityDetailScreen
ChartsTab → "View All" → ExpandedLeaderboardScreen
ActivitiesTab → Tap Activity → ActivityDetailScreen
TableTab → Tap Row → MemberDetailScreen
```

---

## ⚙️ State & Utility Screens

| Screen Name | Purpose | File | When Shown |
|-------------|---------|------|------------|
| `LoadingScreen` | Data fetch loading state | `GlassLoadingView.swift` | Initial load, refresh |
| `ErrorScreen` | Error display with retry | `GlassErrorView.swift` | Network/auth errors |
| `EmptyStateScreen` | No activities message | `EmptyStateView.swift` | No data available |

### State Flow
```
LoadingScreen → [Success] → DashboardScreen
LoadingScreen → [Error] → ErrorScreen → [Retry] → LoadingScreen
DashboardScreen → [No Data] → EmptyStateScreen
```

---

## 📺 tvOS Screens

| Screen Name | Purpose | File | Platform |
|-------------|---------|------|----------|
| `TVDashboardScreen` | Apple TV main display | `TVDashboardView.swift` | tvOS |
| `TVChartsScreen` | TV-optimized charts view | `TVChartsView.swift` | tvOS |
| `TVTableScreen` | TV-optimized table view | `TVTableView.swift` | tvOS |

### tvOS Navigation
```
TVDashboardScreen
├── TVChartsScreen (focus-based navigation)
└── TVTableScreen
```

**Note**: tvOS is read-only - no authentication or editing capabilities.

---

## 🪟 Modal & Overlay Views

| Screen Name | Purpose | File | Modal Type |
|-------------|---------|------|------------|
| `WelcomeCard` | First-time user welcome | `GlassWelcomeCard.swift` | Card overlay |
| `RefreshIndicator` | Pull-to-refresh loading | Native SwiftUI | System standard |
| `BiometricPrompt` | System biometric auth | Native `LocalAuthentication` | System alert |
| `LogoutConfirmation` | Confirm logout action | Native `.confirmationDialog` | Action sheet |

---

## 🎨 Reusable Components (Not Full Screens)

These are components, not screens, but referenced for clarity:

| Component Name | Purpose | File |
|----------------|---------|------|
| `ActivityRow` | Single activity list item | `ActivityRow.swift` |
| `MemberStatCard` | Member stats card | `MemberStatCard.swift` |
| `ChartView` | Reusable chart component | `ChartView.swift` |
| `StatsSummaryCard` | Week summary card | `StatsSummaryCard.swift` |
| `TrendIndicator` | Arrow/emoji trend icon | `TrendIndicator.swift` |

---

## 📋 Usage Examples

### Issue Reporting
```markdown
**Title**: Chart not updating after logout/login

**Screen**: `ChartsTab` on `DashboardScreen`

**Steps to Reproduce**:
1. Open app to `DashboardScreen`
2. Navigate to `ChartsTab`
3. Tap logout → returns to `LoginScreen`
4. Login again → returns to `DashboardScreen`
5. Navigate to `ChartsTab`
6. Charts show stale data from previous session

**Expected**: `ChartsTab` should refresh data after re-authentication
**Actual**: Old cached data displayed
```

### Feature Request
```markdown
**Title**: Add activity type filter

**Screen**: `ActivitiesTab`

**Description**: 
Add a filter button at the top of `ActivitiesTab` that allows users to 
filter activities by type (Run, Ride, Walk, Other). Filtered results 
should update the activity list in real-time.

**UI Placement**: 
- Navigation bar trailing button on `ActivitiesTab`
- Opens a filter menu (could reuse `LogoutConfirmation` style)
```

### Development Task
```markdown
**Task**: Implement dark mode for charts

**Files to Modify**:
- `MemberStatsChartView.swift` (`ChartsTab`)
- `ChartView.swift` (reusable component)

**Screens Affected**:
- `ChartsTab` on iOS/iPadOS
- `TVChartsScreen` on tvOS

**Testing Required**:
- [ ] `ChartsTab` in light mode
- [ ] `ChartsTab` in dark mode
- [ ] `TVChartsScreen` in light mode
- [ ] `TVChartsScreen` in dark mode
- [ ] Switch between modes while viewing charts
```

---

## 🗺️ Complete User Flow Map

```
App Launch
    │
    ├─ [First Time User]
    │   └─ LoginScreen
    │       └─ WebAuthScreen (Strava OAuth)
    │           └─ [Auth Success]
    │               └─ BiometricGateScreen (setup prompt)
    │                   └─ DashboardScreen + WelcomeCard
    │
    └─ [Returning User]
        └─ BiometricGateScreen (if enabled)
            └─ [Auth Success]
                └─ LoadingScreen
                    ├─ [Success] → DashboardScreen
                    └─ [Error] → ErrorScreen
                        └─ [Retry] → LoadingScreen
                        └─ [Logout] → LoginScreen

DashboardScreen
    ├─ ChartsTab
    │   ├─ Tap Chart Bar → MemberDetailScreen
    │   ├─ Tap Activity → ActivityDetailScreen
    │   └─ "View All Members" → ExpandedLeaderboardScreen
    │
    ├─ TableTab
    │   └─ Tap Row → MemberDetailScreen
    │       └─ Tap Activity → ActivityDetailScreen
    │
    └─ ActivitiesTab
        └─ Tap Activity → ActivityDetailScreen
            └─ See Member Activities (filtered view)
```

---

## 🎯 Quick Reference Table

| Screen Type | Count | Example |
|-------------|-------|---------|
| **Auth Screens** | 3 | `LoginScreen`, `BiometricGateScreen`, `WebAuthScreen` |
| **Main Tabs** | 3 | `ChartsTab`, `TableTab`, `ActivitiesTab` |
| **Detail Screens** | 3 | `ActivityDetailScreen`, `MemberDetailScreen`, `ExpandedLeaderboardScreen` |
| **State Screens** | 3 | `LoadingScreen`, `ErrorScreen`, `EmptyStateScreen` |
| **tvOS Screens** | 3 | `TVDashboardScreen`, `TVChartsScreen`, `TVTableScreen` |
| **Modals/Overlays** | 4 | `WelcomeCard`, `RefreshIndicator`, `BiometricPrompt`, `LogoutConfirmation` |

**Total Named Screens**: 19

---

## 📝 Naming Guidelines

### DO ✅
- Use descriptive, functional names: `ActivityDetailScreen`
- Include screen type: `Screen`, `Tab`, `View`, `Card`, `Prompt`
- Use PascalCase: `MemberDetailScreen`
- Be consistent across all documentation

### DON'T ❌
- Use generic names: `Screen1`, `View2`
- Mix naming patterns: `activity-detail`, `ActivityDetail`
- Use abbreviations: `ActDtlScr`
- Change names mid-development

---

## 🔄 Updating This Document

When adding new screens:

1. **Add to appropriate category** (Auth, Main, Detail, State, etc.)
2. **Update the count** in Quick Reference Table
3. **Add to User Flow Map** if it changes navigation
4. **Update README.md** screen reference section
5. **Notify team** of new screen names

---

## 📞 Questions?

If you're unsure which screen name to use:
1. Check the file name (usually matches)
2. Look at the User Flow Map
3. Ask in the development channel
4. When in doubt, be descriptive: `[What]Screen`

---

<p align="center">
<em>Keep screen names consistent. Your future self will thank you! 🙏</em>
</p>

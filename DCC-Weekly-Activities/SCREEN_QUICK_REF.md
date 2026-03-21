# Quick Screen Reference Card
**DCC Weekly Activities** - Keep this handy during development! 📱

---

## 🎯 Most Common Screens

| Screen | File | What It Does |
|--------|------|--------------|
| `LoginScreen` | `LoginView.swift` | First screen - Strava login |
| `DashboardScreen` | `WeeklyDashboardView.swift` | Main app with 3 tabs |
| `ChartsTab` | `MemberStatsChartView.swift` | Visual charts (default tab) |
| `TableTab` | `MemberStatsTableView.swift` | Data table view |
| `ActivitiesTab` | `ActivitiesListView.swift` | Activity list |
| `ActivityDetailScreen` | `ActivityDetailView.swift` | Single activity details |
| `LoadingScreen` | `GlassLoadingView.swift` | Loading indicator |
| `ErrorScreen` | `GlassErrorView.swift` | Error with retry |

---

## 🏃 Quick Navigation Flow

```
LoginScreen 
    ↓
BiometricGateScreen 
    ↓
DashboardScreen (with 3 tabs)
    ├── ChartsTab → ActivityDetailScreen
    ├── TableTab → MemberDetailScreen
    └── ActivitiesTab → ActivityDetailScreen
```

---

## 💬 Example Issue Format

```markdown
**Screen**: `ChartsTab`
**Bug**: Charts not updating after pull-to-refresh
**Steps**: 
1. Open `DashboardScreen`
2. Go to `ChartsTab`
3. Pull down to refresh
4. Data doesn't update
```

---

## 📋 All Screen Names (Alphabetical)

- `ActivitiesTab`
- `ActivityDetailScreen`
- `BiometricGateScreen`
- `BiometricPrompt`
- `ChartsTab`
- `DashboardScreen`
- `EmptyStateScreen`
- `ErrorScreen`
- `ExpandedLeaderboardScreen`
- `LoadingScreen`
- `LoginScreen`
- `LogoutConfirmation`
- `MemberDetailScreen`
- `RefreshIndicator`
- `TableTab`
- `TVChartsScreen`
- `TVDashboardScreen`
- `TVTableScreen`
- `WebAuthScreen`
- `WelcomeCard`

**Total**: 20 named screens

---

## 🎨 Platform-Specific

### iOS/iPadOS Only
- `LoginScreen`
- `BiometricGateScreen`
- `DashboardScreen` (+ all tabs)
- All detail screens

### tvOS Only
- `TVDashboardScreen`
- `TVChartsScreen`
- `TVTableScreen`

### System Provided
- `WebAuthScreen` (Safari)
- `BiometricPrompt` (system)
- `RefreshIndicator` (SwiftUI)

---

## 🔗 Full Documentation

See **[SCREEN_REFERENCE.md](SCREEN_REFERENCE.md)** for:
- Complete screen descriptions
- File locations
- User flow diagrams
- Usage examples
- Development guidelines

---

<p align="center">
<strong>Print this card and keep it at your desk! 🖨️</strong>
</p>

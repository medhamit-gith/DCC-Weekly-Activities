# Quick Start Guide - Dashboard Mode Selection

## What Changed?

After logging in, users now see a **mode selection screen** before the dashboard. They can choose from 3 different views of their cycling data.

## The 3 Dashboard Modes

### 🏃 Just My Stats
**What it shows**: Only YOUR activities  
**Best for**: Personal tracking and progress  
**Features**:
- Your total distance, rides, speed, elevation
- Daily breakdown chart
- List of your recent activities

### 📊 Me vs Top 3  
**What it shows**: You compared to top 3 riders  
**Best for**: Friendly competition  
**Features**:
- Your ranking (with medals if top 3!)
- Bar chart comparison (you're highlighted in orange)
- Shows how far behind the leader you are
- Detailed stats table

### ⚠️ Worst Performer & Why
**What it shows**: Who needs motivation  
**Best for**: Club encouragement  
**Features**:
- Identifies rider with lowest distance
- Explains WHY they're behind (below average, fewer rides, etc.)
- Comparison chart vs club average
- Motivational suggestions

## User Flow

```
1. Login with Strava ✓
2. Biometric authentication ✓
3. See "Welcome, [YourName]!" screen ← NEW!
4. Tap one of 3 mode cards ← NEW!
5. View your selected dashboard ← NEW!
6. Tap back button to change modes ← NEW!
```

## For Developers

### New Files
- `DashboardModeSelectionView.swift` - Mode selection screen
- `JustMyStatsView.swift` - Personal stats view
- `MeVsTop3View.swift` - Comparison view
- `WorstPerformerView.swift` - Motivation view
- `DASHBOARD_MODE_SELECTION_README.md` - Full documentation

### Modified Files
- `StravaAPI.swift` - Added `fetchAuthenticatedAthlete()`
- `RootView.swift` - Added mode selection flow

### No Changes To
- Authentication (OAuth, biometric)
- API configuration
- Data models (Activity, MemberStats)
- Existing networking layer
- Original dashboard (preserved as `OriginalWeeklyDashboardView`)

## Testing Checklist

Quick things to verify:

- [ ] Mode selection appears after login
- [ ] Your first name displays correctly
- [ ] All 3 cards are tappable
- [ ] Each mode shows correct data
- [ ] Back button works
- [ ] Refresh button works
- [ ] Logout still works

## Customization Points

Easy to change:

**Number of top riders**: Line 17 in `MeVsTop3View.swift`
```swift
private var top3: [MemberStats] {
    stats.sorted { $0.totalKM > $1.totalKM }.prefix(3) // Change 3 to any number
}
```

**Card colors**: Lines 27-33 in `DashboardModeSelectionView.swift`
```swift
var color: Color {
    switch self {
    case .justMyStats: return .dccSaffron    // Change these
    case .meVsTop3: return .dccGreen         // to any color
    case .worstPerformer: return .dccBlue
    }
}
```

**Date range**: Currently fixed to last 7 days, but can be made dynamic

## Troubleshooting

**Problem**: "No activities found" in Just My Stats  
**Solution**: Make sure you have activities in the club this week

**Problem**: Colors not found (.dccSaffron, etc.)  
**Solution**: These should exist in your Color extensions - check `Color+DCC.swift`

**Problem**: Name doesn't match  
**Solution**: The app matches by `firstname + lastname` from Strava

## API Usage

Only 1 new API call added:
```
GET /api/v3/athlete
```

This fetches your profile (name, ID) once per session.

All other data comes from existing club activities endpoint (unchanged).

## Performance

- ✅ Profile fetched once per session
- ✅ Activities fetched on-demand
- ✅ No extra API calls
- ✅ Efficient filtering and sorting
- ✅ Smooth animations

## Need Help?

1. Check `DASHBOARD_MODE_SELECTION_README.md` for details
2. Look at `IMPLEMENTATION_SUMMARY.md` for overview
3. Each view file has preview code with examples
4. Original dashboard still available if needed

---

**TL;DR**: Login → Choose mode → See dashboard → Switch modes anytime  
**Impact**: Zero breaking changes, all new code in separate files  
**Status**: Ready to use! 🚀

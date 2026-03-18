# Quick Reference: Current Week vs Last Week

## 🗓️ Today: Saturday, February 28, 2026

---

## What Changed?

### ❌ BEFORE (Old Behavior)
- **Showed**: Last **completed** week (Feb 16-22)
- **Display**: "Mon 16 Feb – Sun 22 Feb"
- **Data**: Activities from 7 days ago
- **Function**: `getLastCompletedWeek()`

### ✅ AFTER (New Behavior)
- **Shows**: **Current** week (Feb 24-28)
- **Display**: "Mon 24 Feb – today"
- **Data**: Activities from this Monday onwards
- **Function**: `getCurrentWeek()`

---

## Date Ranges Explained

### Current Week (NEW - Primary)
```
Monday Feb 24 ────────────────────── Saturday Feb 28 (today)
        ↑                                    ↑
    00:00:00 UTC                         23:59:59 UTC
    
UI: "Mon 24 Feb – today"
```

### Last Completed Week (OLD - Deprecated)
```
Monday Feb 16 ────────────────────── Sunday Feb 22
        ↑                                    ↑
    00:00:00 UTC                         23:59:59 UTC
    
UI: "Mon 16 Feb – Sun 22 Feb"
```

---

## Function Reference

### DateRangeProvider Functions

| Function | Purpose | Returns | Use For |
|----------|---------|---------|---------|
| `getCurrentWeek()` | ✅ **PRIMARY** | Mon to today | Main charts, dashboards |
| `getCurrentWeekTimestamps()` | Get Unix timestamps | `(after, before)` | API calls (current week) |
| `getLastCompletedWeek()` | ⚠️ Deprecated | Last Mon-Sun | Historical comparisons |
| `getLastCompletedWeekTimestamps()` | ⚠️ Deprecated | `(after, before)` | Performance trends only |
| `getExtendedWeekRange()` | Fallback mode | Last 14 days | When no current week data |
| `formatDateRange()` | Display formatting | `"Mon 24 Feb – today"` | UI text |

---

## Code Examples

### ✅ CORRECT - Use Current Week
```swift
// Main dashboard data
let interval = DateRangeProvider.getCurrentWeek()
let timestamps = DateRangeProvider.getCurrentWeekTimestamps()

// Fetch current week activities
let activities = try await stravaAPI.fetchLastWeeksClubActivities()
// Returns activities from Feb 24-28
```

### ⚠️ DEPRECATED - Only for Comparisons
```swift
// Performance trend comparison ONLY
let lastWeek = DateRangeProvider.getLastCompletedWeek()
// Returns Feb 16-22 for historical comparison
```

---

## UI Display Examples

### Main Dashboard
```swift
DateRangeHeaderView(dateRange: DateRangeProvider.getCurrentWeek())
// Displays: "Mon 24 Feb – today"
```

### Charts Tab
```
┌─────────────────────────────────────┐
│          Weekly Activities          │
├─────────────────────────────────────┤
│                                     │
│           Week Summary               │
│        Mon 24 Feb – today            │  ← Current week
│                                     │
│     [Bar Chart with 6 days data]    │
└─────────────────────────────────────┘
```

### Performance Trend (ActivityDetailView)
```
Performance Trend
─────────────────
     150
  ┌──────┐
  │      │  120        100
  │ This │┌────┐    ┌────┐
  │ Week ││ 1w │    │ 2w │
  └──────┘│ago │    │ago │
          └────┘    └────┘

↑ 20.0% increase vs previous weeks

Current Week: 150.0 km  (Feb 24-28)
Avg Previous: 125.0 km  (Feb 17-23, Feb 10-16)
```

---

## Calendar View

### February 2026
```
Su Mo Tu We Th Fr Sa
                   1
 2  3  4  5  6  7  8
 9 10 11 12 13 14 15
16 17 18 19 20 21 22  ← Last completed week (OLD)
23 24 25 26 27 28     ← Current week (NEW)
   ↑              ↑
   Mon          Today
```

---

## API Behavior

### Strava API Call
```swift
// OLD: Fetched Feb 16-22
after=1739673600   (Mon Feb 16 00:00:00)
before=1740278399  (Sun Feb 22 23:59:59)

// NEW: Fetches Feb 24-28
after=1740364800   (Mon Feb 24 00:00:00)
before=1740796799  (Sat Feb 28 23:59:59)
```

### What Gets Returned
- **Monday Feb 24**: All activities ✅
- **Tuesday Feb 25**: All activities ✅
- **Wednesday Feb 26**: All activities ✅
- **Thursday Feb 27**: All activities ✅
- **Friday Feb 28**: All activities ✅
- **Saturday Feb 28** (today): All activities up to now ✅
- **Sunday Feb 22**: ❌ NOT included (old week)

---

## Timeline: How It Updates

### Saturday Feb 28 (Today)
- **Shows**: Mon 24 Feb – today
- **Days**: 6 days of data
- **Status**: Week in progress

### Sunday Mar 1 (Tomorrow)
- **Shows**: Mon 24 Feb – Sun 1 Mar
- **Days**: Complete 7-day week
- **Status**: Week completed today

### Monday Mar 3 (Next Week)
- **Shows**: Mon 3 Mar – today
- **Days**: 1 day of data (just Monday)
- **Status**: New week started

---

## Migration Checklist

### Files Updated ✅
- [x] DateRangeProvider.swift - Added `getCurrentWeek()`
- [x] StravaAPI.swift - Uses `getCurrentWeek()` for fetches
- [x] RootView.swift - Both dashboards use `getCurrentWeek()`
- [x] DateRangeHeaderView.swift - Preview uses `getCurrentWeek()`

### Functions Changed ✅
- [x] `fetchLastWeeksClubActivities()` → uses `getCurrentWeek()`
- [x] `WeeklyDashboardView.loadData()` → uses `getCurrentWeek()`
- [x] `OriginalWeeklyDashboardView.loadData()` → uses `getCurrentWeek()`

### UI Impact ✅
- [x] Date header shows "Mon 24 Feb – today"
- [x] Charts display current week activities only
- [x] Week summary shows this week's totals
- [x] Performance trends still work correctly

---

## Troubleshooting

### Issue: Still showing old week (Feb 16-22)
**Solution**: 
1. Clean build folder (Cmd+Shift+K)
2. Rebuild app (Cmd+B)
3. Force quit app and relaunch

### Issue: No activities showing
**Possible causes**:
- No activities yet this week
- Extended range fallback should trigger
- Check Strava API connectivity

### Issue: Date shows future Sunday
**Expected behavior**:
- Shows "today" instead of Sat Feb 28
- This is correct - week is in progress

### Issue: Performance trend wrong
**Check**:
- Trend uses separate `fetchClubActivities(weeksBack: 3)`
- Should show "This Week", "1w ago", "2w ago"
- Not affected by getCurrentWeek() change

---

## Testing Guide

### Test 1: Verify Current Week Display
1. Open app
2. Check date header
3. **Expected**: "Mon 24 Feb – today"
4. **NOT**: "Mon 16 Feb – Sun 22 Feb"

### Test 2: Verify Activity List
1. View activities list
2. Check dates of all activities
3. **Expected**: All from Feb 24 onwards
4. **NOT**: Any from Feb 16-23

### Test 3: Verify Charts
1. Open Charts tab
2. Check bar chart data
3. **Expected**: Data for Mon-Sat (6 bars max)
4. Values should be for current week only

### Test 4: Verify Performance Trends
1. Tap any activity
2. Scroll to "Performance Trend"
3. **Expected**: "This Week" shows Feb 24-28 data
4. "1w ago" shows Feb 17-23 for comparison

---

## Key Takeaways

✅ **Main UI** → Shows **current week** (Feb 24-28)  
✅ **Date Display** → Shows "today" for in-progress weeks  
✅ **Performance Trends** → Uses **previous weeks** for comparison  
✅ **Old Functions** → Still available but deprecated  
✅ **Backward Compatible** → Can rollback if needed  

---

**Quick Answer**: "What week am I seeing?"

**Answer**: **This week** (Monday Feb 24 to today Saturday Feb 28)

---

Last Updated: February 28, 2026

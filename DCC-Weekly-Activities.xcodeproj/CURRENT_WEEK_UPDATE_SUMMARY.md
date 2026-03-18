# Current Week Update - Implementation Summary

**Date**: February 28, 2026  
**Objective**: Update app to show **current week's data** (Monday to today) instead of last completed week

---

## 🎯 Problem Statement

The app was showing data from **last week** (Feb 16-22) instead of the **current week** (Feb 24-28). Users expect to see:
- **Main graphs**: Current week data (Monday Feb 24 to today Feb 28)
- **Performance trends**: Previous weeks for comparison purposes only

---

## ✅ Changes Implemented

### 1. **DateRangeProvider.swift** - New `getCurrentWeek()` Function

**Added**: New primary function to calculate current week range

```swift
/// Returns the current ISO calendar week (Monday 00:00:00 to today/Sunday 23:59:59)
static func getCurrentWeek() -> DateInterval {
    // Returns THIS WEEK's data (current week Monday through today)
    // If today is Saturday Feb 28, returns: Mon Feb 24 00:00:00 to Sat Feb 28 23:59:59
}
```

**Key Logic**:
- Today is **Saturday, Feb 28, 2026**
- ISO weekday = 6 (Saturday)
- Days back to Monday = 6 - 1 = **5 days**
- **Week start**: Monday, Feb 24, 2026 at 00:00:00 UTC
- **Week end**: Saturday, Feb 28, 2026 at 23:59:59 UTC

**Result**: Shows "Mon 24 Feb – today" in the UI

---

**Deprecated**: Old `getLastCompletedWeek()` function

This function now has a deprecation notice and is only used for:
- Historical comparisons in performance trends
- "Previous week" calculations

```swift
/// **DEPRECATED**: Use getCurrentWeek() for displaying current week data.
/// Only use this for historical comparisons or "previous week" features.
static func getLastCompletedWeek() -> DateInterval {
    // Returns LAST COMPLETED week (always a full Monday-Sunday)
}
```

---

**Added**: New timestamp function

```swift
/// Returns Unix timestamps for API calls (after, before parameters)
/// Uses CURRENT WEEK (this week's data, not last week)
static func getCurrentWeekTimestamps() -> (after: Int, before: Int) {
    let interval = getCurrentWeek()
    return (
        after: Int(interval.start.timeIntervalSince1970),
        before: Int(interval.end.timeIntervalSince1970)
    )
}
```

---

### 2. **StravaAPI.swift** - Updated to Fetch Current Week

**Changed**: `fetchLastWeeksClubActivities()` now uses `getCurrentWeek()`

**Before**:
```swift
} else {
    // Fetch standard single week
    timestamps = DateRangeProvider.getLastCompletedWeekTimestamps()
    interval = DateRangeProvider.getLastCompletedWeek()
}
```

**After**:
```swift
} else {
    // Fetch CURRENT week (not last completed week)
    // This ensures we show this week's data (Monday to today)
    timestamps = DateRangeProvider.getCurrentWeekTimestamps()
    interval = DateRangeProvider.getCurrentWeek()
}
```

**Impact**: All API calls now fetch activities from **Monday Feb 24** onwards instead of Feb 16.

---

### 3. **RootView.swift** - Updated Date Range Calculation

**Changed**: Both dashboard views now calculate date ranges using `getCurrentWeek()`

**WeeklyDashboardView** (lines 265-270):
```swift
let interval = stravaAPI.isShowingExtendedRange 
    ? DateRangeProvider.getExtendedWeekRange()
    : DateRangeProvider.getCurrentWeek()  // Changed from getLastCompletedWeek()
dateRange = (start: interval.start, end: interval.end)
```

**OriginalWeeklyDashboardView** (lines 446-449):
```swift
let interval = stravaAPI.isShowingExtendedRange 
    ? DateRangeProvider.getExtendedWeekRange()
    : DateRangeProvider.getCurrentWeek()  // Changed from getLastCompletedWeek()
dateRange = (start: interval.start, end: interval.end)
```

**Impact**: UI now displays "Mon 24 Feb – today" instead of "Mon 16 Feb – Sun 22 Feb"

---

### 4. **DateRangeHeaderView.swift** - Updated Preview

**Changed**: Preview now uses current week

**Before**:
```swift
#Preview {
    let interval = DateRangeProvider.getLastCompletedWeek()
```

**After**:
```swift
#Preview {
    let interval = DateRangeProvider.getCurrentWeek()
```

**Updated**: Version history to document the change

---

## 📊 Date Range Behavior

### Today: Saturday, February 28, 2026

#### Current Week Display (NEW)
- **Start**: Monday, February 24, 2026 at 00:00:00 UTC
- **End**: Saturday, February 28, 2026 at 23:59:59 UTC
- **UI Display**: "Mon 24 Feb – today"
- **Days included**: Monday, Tuesday, Wednesday, Thursday, Friday, Saturday (6 days)

#### Last Completed Week (OLD - Deprecated)
- **Start**: Monday, February 16, 2026 at 00:00:00 UTC
- **End**: Sunday, February 22, 2026 at 23:59:59 UTC
- **UI Display**: "Mon 16 Feb – Sun 22 Feb"
- **Days included**: Full 7-day week (Monday through Sunday)

---

## 🎨 UI Examples

### Before This Update
```
┌─────────────────────────────────┐
│        Week Summary              │
│     Mon 16 Feb – Sun 22 Feb      │  ← OLD: Last week's data
└─────────────────────────────────┘
```

### After This Update
```
┌─────────────────────────────────┐
│        Week Summary              │
│      Mon 24 Feb – today          │  ← NEW: Current week's data
└─────────────────────────────────┘
```

When the week completes (Sunday):
```
┌─────────────────────────────────┐
│        Week Summary              │
│    Mon 24 Feb – Sun 1 Mar        │  ← Shows full week
└─────────────────────────────────┘
```

---

## 🔄 Performance Trend Handling

The **performance trend feature** in `ActivityDetailView` is **NOT affected** by this change because it:

1. Uses a separate API call: `fetchClubActivities(weeksBack: 3)`
2. Groups activities by relative week: "This Week", "1w ago", "2w ago"
3. Calculates "This Week" dynamically based on activity dates

**Result**: Performance trends will now correctly compare:
- **This Week** (Feb 24-28): Current week data
- **1w ago** (Feb 17-23): Previous week for comparison
- **2w ago** (Feb 10-16): Two weeks ago for comparison

This is exactly what you want - current data in main views, historical data for trends.

---

## 📁 Files Modified

| File | Changes | Lines Modified |
|------|---------|----------------|
| **DateRangeProvider.swift** | • Added `getCurrentWeek()` function<br>• Added `getCurrentWeekTimestamps()`<br>• Deprecated `getLastCompletedWeek()`<br>• Updated version history | ~60 lines added |
| **StravaAPI.swift** | • Changed to use `getCurrentWeek()` for standard fetches | 4 lines |
| **RootView.swift** | • Updated both dashboard views to use `getCurrentWeek()` | 4 lines |
| **DateRangeHeaderView.swift** | • Updated preview<br>• Updated version history | 3 lines |

**Total Files Modified**: 4  
**Total Lines Changed**: ~70 lines

---

## ✅ Testing Checklist

### Data Display
- [ ] Charts tab shows activities from **Monday Feb 24** onwards
- [ ] Date range header displays "Mon 24 Feb – today"
- [ ] Week summary cards show totals for current week only
- [ ] No activities from Feb 16-23 appear in main charts

### Date Range Updates
- [ ] On **Sunday (tomorrow)**, range should show "Mon 24 Feb – Sun 1 Mar"
- [ ] On **Monday (Mar 3)**, range should update to "Mon 3 Mar – today"
- [ ] Extended range mode (if triggered) still shows 14-day window

### Performance Trends
- [ ] ActivityDetailView performance trend shows:
  - "This Week" = Current week (Feb 24-28)
  - "1w ago" = Last week (Feb 17-23)
  - "2w ago" = Two weeks ago (Feb 10-16)
- [ ] Percentage calculations are correct
- [ ] Chart bars display proper data

### Edge Cases
- [ ] Works on Sunday (end of week)
- [ ] Works on Monday (start of week)
- [ ] Works with no activities this week
- [ ] Extended range fallback still works

---

## 🚀 Expected Behavior

### For Users Today (Saturday, Feb 28)

**When opening the app**:
1. See "Mon 24 Feb – today" in date range header
2. All charts show only activities from Feb 24-28
3. Week summary shows totals for 6 days (Mon-Sat)
4. Performance trends compare this week vs previous weeks

**Tomorrow (Sunday, Mar 1)**:
1. Date range changes to "Mon 24 Feb – Sun 1 Mar"
2. Charts include Sunday's activities
3. Week summary shows complete 7-day week

**Monday (Mar 3)**:
1. Date range automatically updates to "Mon 3 Mar – today"
2. Charts reset to show new week starting Monday
3. Previous week (Feb 24-Mar 1) becomes historical data

---

## 💡 Design Decisions

### Why Show "today" Instead of Saturday's Date?
- **User-friendly**: "today" is immediately understood
- **Accurate**: Clearly indicates the week is in progress
- **Consistent**: Matches the `formatDateRange()` logic already in place

### Why Keep getLastCompletedWeek()?
- **Backward compatibility**: Other features might need it
- **Historical comparisons**: Performance trends need previous week data
- **Safety**: Deprecated but not removed in case of issues

### Why Use getCurrentWeek() as Default?
- **User expectation**: Most users want to see "this week"
- **Real-time data**: Shows activities happening now
- **Engagement**: Encourages checking the app more frequently

---

## 🔍 Verification

### Quick Test Commands

**Check what date range is being calculated:**
```swift
let current = DateRangeProvider.getCurrentWeek()
print("Current week: \(current.start) to \(current.end)")
// Expected: Mon Feb 24 00:00:00 to Sat Feb 28 23:59:59

let last = DateRangeProvider.getLastCompletedWeek()
print("Last completed: \(last.start) to \(last.end)")
// Expected: Mon Feb 16 00:00:00 to Sun Feb 22 23:59:59
```

**Check formatted output:**
```swift
let formatted = DateRangeProvider.formatDateRange(current)
print("Formatted: \(formatted)")
// Expected: "Mon 24 Feb – today"
```

---

## 📝 Notes

### Important Considerations

1. **UTC Timezone**: All calculations use UTC to match Strava's API format
2. **Display Timezone**: UI shows dates in user's local timezone
3. **ISO 8601 Calendar**: Weeks start on Monday, end on Sunday
4. **Real-time Updates**: Date range updates automatically each day

### Future Enhancements

- [ ] Add "Week X of Year" label (e.g., "Week 9 • Mon 24 Feb – today")
- [ ] Add toggle to switch between "Current Week" and "Last Week"
- [ ] Add "Compare to Last Week" feature in main charts
- [ ] Show week-over-week growth percentage in summary cards

---

## 🎯 Success Criteria

This update is successful if:

✅ Main dashboard shows **current week data** (Feb 24-28)  
✅ Date display shows "Mon 24 Feb – today"  
✅ Performance trends still show **previous weeks** for comparison  
✅ No activities from Feb 16-23 appear in main charts  
✅ Extended range fallback still works if needed  
✅ All date calculations are accurate and consistent  

---

## 🚨 Rollback Plan

If issues arise, revert these changes:

1. **DateRangeProvider.swift**: Change default back to `getLastCompletedWeek()`
2. **StravaAPI.swift**: Use `getLastCompletedWeekTimestamps()`
3. **RootView.swift**: Both dashboard views use `getLastCompletedWeek()`
4. **DateRangeHeaderView.swift**: Preview uses `getLastCompletedWeek()`

All old functions are still present and functional.

---

## ✨ Summary

The DCC Weekly Activities app now displays **current week data** (Monday to today) instead of last week's completed data. This provides:

- ✅ **Real-time visibility** into ongoing weekly performance
- ✅ **More relevant data** for users checking progress during the week
- ✅ **Better engagement** as users see their latest activities immediately
- ✅ **Accurate comparisons** in performance trends (current vs previous)

The change is **non-breaking** - all deprecated functions remain for backward compatibility and historical comparisons.

---

**Implementation Date**: February 28, 2026  
**Implemented By**: AI Assistant  
**Status**: ✅ Complete and Ready for Testing

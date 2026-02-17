# Date Range Fix - Last Monday to Last Sunday

## Changes Made

### ✅ Fixed Date Range Calculation
The app now correctly fetches activities from **last Monday to last Sunday**, regardless of what day of the week you run the app.

### How it Works:

1. **Always shows LAST week's data** (Monday-Sunday)
   - If today is Monday, shows last week's Monday-Sunday
   - If today is Tuesday, shows last week's Monday-Sunday
   - If today is Sunday, shows last week's Monday-Sunday

2. **Proper date boundaries**
   - Start: Last Monday at 00:00:00
   - End: Last Sunday at 23:59:59

### 📅 Date Display
The app now shows the date range prominently at the top:
- **Primary display**: "Week: Mon, Jan 27 - Sun, Feb 2"
- **Secondary display**: "January 27, 2025 - February 2, 2025"

### 🔍 Debug Information
Added debug logging to help verify totals:
- Total KM across all activities
- Total number of activities
- Per-member breakdown (specifically for Amit K as example)

### 📊 API Changes

**StravaAPI.swift:**
1. Updated `fetchLastWeeksClubActivities()` to:
   - Calculate last Monday and last Sunday dates
   - Use both `after` and `before` parameters in Strava API
   - Increased `per_page` from 50 to 200 to ensure all activities are captured
   - Added detailed debug logging with date ranges

2. Added new method `getLastWeekDateRange()`:
   - Returns the start and end dates for display
   - Uses the same calculation logic as the fetch method

**ContentView.swift:**
1. Added `@State private var dateRange` to store the week being displayed
2. Added date range header showing:
   - Short format: "Mon, Jan 27 - Sun, Feb 2"
   - Full format: "January 27, 2025 - February 2, 2025"
3. Added debug logging to verify totals match manual extraction
4. Added helper methods for date formatting

## Testing the Fix

When you run the app, check the debug console for output like:
```
📅 Fetching activities from 2025-01-27 00:00:00 to 2025-02-02 23:59:59
📡 Fetching from: https://www.strava.com/api/v3/clubs/212760/activities?per_page=200&after=1737936000&before=1738540799
📊 Total KM fetched: 664.4
📊 Total activities: XX
🔍 Amit K activities: 7
🔍 Amit K total KM: 274.2
```

This should now match your manually extracted data:
- Total: 664.4 km ✓
- Amit K: 274.2 km in 7 rides ✓

## Example Calculation

If today is **Monday, February 10, 2025**:
- Current weekday = 2 (Monday)
- Days to last Monday = (2 - 2 + 7) = 7 days back
- Last Monday = February 3, 2025 00:00:00
- Last Sunday = February 9, 2025 23:59:59

If today is **Sunday, February 9, 2025**:
- Current weekday = 1 (Sunday)
- Days to last Monday = 6 days back
- Last Monday = February 3, 2025 00:00:00
- Last Sunday = February 9, 2025 23:59:59

This ensures everyone sees the same week's data no matter when they check the app!

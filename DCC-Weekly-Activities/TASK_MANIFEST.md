# Task Manifest — DCC Weekly Activities

Track completed features, fixes, and improvements.

## v0.1-data-and-icons — 2026-02-24

✅ **[DATE-FALLBACK]** Smart 2-week fallback when current week has no data
   - Automatically extends date range to previous 2 weeks
   - Prevents empty screens during slow weeks
   - Added `StravaAPI.isShowingExtendedRange` flag
   - Added `DateRangeProvider.getExtendedWeekRange()`

✅ **[UI-DATES]** Accurate date range display on all screens
   - In-progress weeks show "Mon 16 Feb – today" not future dates
   - Extended ranges show full 2-week span accurately
   - Consistent formatting: short day names, no leading zeros, en dash
   - Reactive updates when range changes

✅ **[ICONS]** All icons replaced with cycling SF Symbols
   - Activity types (run/walk/swim) → `figure.outdoor.cycle`
   - Total rides metric → `flag.checkered`
   - Worst performer mode → `tortoise.fill`
   - Welcome screen → `figure.outdoor.cycle`

---

## v0.0-hotfix — 2026-02-24

✅ **[HOTFIX]** Removed "before" param from Strava club activities URL
   - Strava API doesn't support both after/before simultaneously
   - Activities now filtered client-side after fetch

✅ **[HOTFIX]** Fixed post-login crash/freeze
   - Task now isolated to @MainActor in .onOpenURL handler
   - Prevents race condition on Observable property updates

---

## Planned

⏳ Dashboard mode selection feature enhancements
⏳ Additional performance optimizations
⏳ Enhanced analytics and insights

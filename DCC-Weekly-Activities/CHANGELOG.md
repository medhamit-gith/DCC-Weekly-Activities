# Changelog

All notable changes to DCC Weekly Activities will be documented in this file.

## [v1.1-clean-build] — 2026-02-24

### Fixed
- **All type mismatch errors resolved**: Fixed ForEach generic inference failures in MeVsTop3View
  - Removed redundant explicit KeyPath syntax `\MemberStats.id` from ForEach statements
  - Leveraged existing Identifiable conformance for cleaner syntax
  - Resolved "Cannot convert [MemberStats] to Binding<C>" errors
  - Resolved "Generic parameter 'C' could not be inferred" errors
- **All ViewBuilder errors resolved**: ForEach statements now compile cleanly with proper type inference
- **Unused variable warning fixed**: Removed unused `movingTimeData` variable in MeVsTop3View
- **Zero deprecation warnings**: All code uses modern SwiftUI APIs (NavigationStack, .foregroundStyle, .navigationTitle)

### Changed
- **MeVsTop3View.swift**: Simplified ForEach syntax to rely on Identifiable conformance
  - `ForEach(top3, id: \MemberStats.id)` → `ForEach(top3)`
  - `ForEach(comparisonData, id: \MemberStats.id)` → `ForEach(comparisonData)`

### Verified
- ✅ Clean Build Folder completed
- ✅ Zero errors, zero warnings
- ✅ All screens compile successfully
- ✅ All type conformances verified present (Identifiable, Hashable, Codable)
- ✅ No deprecated APIs in use

### Note
- All functionality preserved during cleanup
- No breaking changes introduced
- Ready for production build

---

## [v1.0-docs] — 2026-02-24

### Added
- **Complete App Store documentation suite**:
  - `docs/appstore/APP_STORE_DESCRIPTION.md` - Full App Store listing copy (name, subtitle, description, keywords, URLs)
  - `docs/legal/PRIVACY_POLICY.md` - Complete privacy policy in plain English (must be hosted publicly)
  - `docs/appstore/APPLE_REVIEW_NOTES.md` - Detailed reviewer instructions with step-by-step testing guide
  - `docs/technical/TECHNICAL_DOCUMENTATION.md` - Developer handover documentation (architecture, API integration, deployment)
  - `docs/appstore/APP_STORE_CONNECT_CHECKLIST.md` - Pre-submission checklist (every item must be verified)

### Documentation Highlights
- All documents reflect actual code implementation (no assumptions or placeholders for features that don't exist)
- Privacy-first approach clearly documented (no server storage, no third-party SDKs, read-only Strava access)
- Known Strava API constraints documented (no date fields in club endpoint, cannot use before+after together)
- Clear placeholders flagged for developer action: test account credentials, support URL, privacy policy URL, contact emails

### Ready For
- App Store submission (pending placeholder completion)
- Developer handover
- External privacy policy hosting
- App Store Connect metadata entry

---

## [v0.1-data-loading] — 2026-02-24

### Fixed
- **All club activities being filtered to zero**: In-code date filter was rejecting every activity
  - **Root cause**: Strava `/v3/clubs/{id}/activities` endpoint returns no `start_date` or `start_date_local` fields in response payload. All activities decoded with `Date.distantPast`, failing all date boundary comparisons
  - **Impact**: Every fetched activity (28-36) was filtered to 0, triggering unnecessary 2-week fallback loop
  - **Fix**: Removed in-code date filter entirely. Trust server-side "after=" parameter for date range enforcement
  - **Files changed**: StravaAPI.swift (removed filter logic, updated 2-week fallback to check raw API count)
- **36 activities now load correctly**

### Note  
- This is confirmed Strava API behaviour for the club activities endpoint — it deliberately omits date fields from the response for privacy/performance reasons
- Date range filtering happens server-side via the "after=" Unix timestamp query parameter
- **DO NOT re-add date filtering on this endpoint response** — it will break data loading again
- The 2-week fallback now correctly triggers only when Strava genuinely returns 0 activities

---

## [v0.1-data-and-icons] — 2026-02-24

### Added
- **Smart date range fallback**: Automatically extends to 2-week range when current week has no activity data
  - Prevents empty screens during slow weeks while maintaining accurate date boundaries
  - Added `StravaAPI.isShowingExtendedRange` flag for reactive UI updates
  - Added `DateRangeProvider.getExtendedWeekRange()` for 2-week spans
  - No infinite recursion - stops at 2 weeks if still empty

### Fixed  
- **Accurate date range display**: Date range labels now precisely reflect the exact API fetch window on all screens
  - In-progress weeks display "Mon 16 Feb – today" instead of future Sunday dates
  - Extended 2-week ranges display full "Mon 9 Feb – Sun 22 Feb 2026"
  - Consistent format: short day names, no leading zeros, en dash separator (–)
  - Reactive updates when switching between standard/extended ranges

### Changed
- **Cycling-appropriate icons**: Replaced all non-cycling activity icons with cycling-specific SF Symbols
  - Activity types (run/walk/swim) → `figure.outdoor.cycle` (iOS 17+)
  - Total rides metric → `flag.checkered` (finish line)
  - Worst performer mode → `tortoise.fill`
  - Welcome screen → `figure.outdoor.cycle`
  - Preserved appropriate icons: trophies, person icons, charts, navigation elements

---

## [v0.0-hotfix] — 2026-02-24

### Fixed
- **Strava club activities returning Bad Request error**: Fixed API parameter conflict that prevented activity data from loading after successful authentication.
  - **Root cause**: The `/v3/clubs/{id}/activities` endpoint does not support both "after" and "before" query parameters in the same request. Strava API returns `{"message":"Bad Request","errors":[{"field":"before after","code":"both provided"}]}`
  - **Introduced in**: Initial implementation of ISO week date range filtering
  - **Fix applied**: Removed "before" parameter from URL query string. Activities are now filtered client-side using the week end date after decoding.
  - **Files changed**: StravaAPI.swift (fetchLastWeeksClubActivities function)
- **Post-login crash/freeze regression**: Fixed main thread violation in OAuth redirect handler that caused app to freeze or crash immediately after Strava login completed, leaving users with an empty or spinning screen.
  - **Root cause**: The `.onOpenURL` Task was not isolated to `@MainActor`, causing a race condition when updating `@Observable` properties from a background thread.
  - **Introduced in**: Recent refactoring of RootView.swift OAuth handling
  - **Fix applied**: Wrapped Task with `@MainActor` isolation to ensure thread-safe UI updates during OAuth token exchange
  - **Files changed**: RootView.swift only
  
### Added
- Comprehensive post-login diagnostic logging with `[PostLogin]` prefix for easier debugging of future authentication flow issues
- Client-side activity filtering to enforce ISO week boundaries (Monday 00:00:00 to Sunday 23:59:59)

### Note
- Feature branch `feature/dashboard-mode-selection` must be created from main after this merge
- Do not begin feature work until v0.0-hotfix tag exists on main

---

## [Unreleased]

### Planned
- Dashboard mode selection feature (to be implemented after hotfix merge)

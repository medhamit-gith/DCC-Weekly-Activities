# DCC Weekly Activities — Bug Tracker

---

## DCC-001 · Analysis tab: content not scrollable

| Field | Value |
|---|---|
| **ID** | DCC-001 |
| **Status** | Resolved |
| **Priority** | High |
| **Component** | Analysis Tab / RiderAnalysisView |
| **Reported** | 2026-03-06 |
| **Resolved** | 2026-03-06 |
| **Reporter** | User |
| **Assignee** | Engineering |

### Summary
Scrolling is completely disabled on the Analysis tab. The user cannot scroll past the first visible section to see charts or coaching tips.

### Steps to Reproduce
1. Log in with Strava
2. Navigate to the **Analysis** tab
3. Attempt to scroll down past the Celebration Card

### Expected Behaviour
The entire Analysis tab content (Celebration Card → Distance Bar Chart → Speed/Elevation Scatter → Radar Chart → Coaching Tips) should be vertically scrollable.

### Actual Behaviour
Content is frozen. No scrolling response to vertical swipe.

### Root Cause (Confirmed)
Two compounding issues were found:

**Issue A — Nested ScrollViews (initial fix, 2026-03-06 session 1)**
`RiderAnalysisView` had its own inner `ScrollView`. When placed inline inside the tab-level outer `ScrollView` in `ProfessionalDashboardView`, the two `ScrollView`s conflicted and scroll gestures were lost.
- Fixed by removing the inner `ScrollView` from `RiderAnalysisView`.

**Issue B — DragGesture intercepting all vertical touches (root cause, 2026-03-06 session 2)**
After removing the nested `ScrollView`, a `DragGesture()` (no `minimumDistance`) remained attached to the top-level `VStack` in `RiderAnalysisView`. Because `DragGesture` defaults to `minimumDistance: 10pt` with no directional constraint, it competed with — and won over — the outer `ScrollView` for all vertical pan gestures, leaving the tab unscrollable.

```swift
// REMOVED from RiderAnalysisView.swift — was intercepting all scroll gestures
.gesture(
    DragGesture()
        .onEnded { value in
            if value.startLocation.x < 30 && value.translation.width > 80 {
                dismiss()
            }
        }
)
```

The gesture was a swipe-right-to-dismiss shortcut. It is redundant because:
- The **Back button** in the toolbar already handles dismissal from push-navigation contexts.
- In the inline Analysis tab context, dismiss has no effect anyway.

### Fix Applied
**File:** `DCC-Weekly-Activities/RiderAnalysisView.swift`
Removed the `DragGesture` modifier entirely. The Back button remains for push-navigation usage (Leaderboard → rider detail, Insights → "View Full Analysis").

### Regression Risk
- Low. Back button still works for push-navigation dismiss.
- No other swipe interactions depend on this gesture.

### Verification
- Build: `✅ Success` (0 errors, 0 warnings)
- Manual: Scroll through all sections on Analysis tab

---

*Add new bugs below following the same template. Increment ID (DCC-002, DCC-003, …).*

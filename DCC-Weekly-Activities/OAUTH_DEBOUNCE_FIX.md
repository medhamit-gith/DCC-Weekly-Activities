# OAuth Debounce & Error Handling Fix

## Date: 2026-03-05

## Problem
Multiple simultaneous OAuth sessions were being created when users tapped the "Connect to Strava" button multiple times, causing sessions to cancel each other. Additionally, ASWebAuthenticationSessionError code 1 (user cancellation) was being treated as a hard error.

## Solution
Implemented three critical fixes:

### CHANGE 1: Add Debounce to Connect Button

**StravaAPI.swift:**
- Added `var isAuthenticating: Bool = false` to `StravaAPI` class
- Added guard at start of `beginOAuth()` to prevent concurrent sessions:
  ```swift
  guard !isAuthenticating else {
      print("⚠️ [OAuth] Auth already in progress, ignoring duplicate tap")
      return
  }
  isAuthenticating = true
  ```
- Reset `isAuthenticating = false` in all completion paths (success, error, cancellation)

**GlassComponents.swift:**
- Updated `GlassWelcomeCard` to accept `isAuthenticating: Bool` parameter
- Disabled button while authenticating: `.disabled(isAuthenticating)`
- Added visual feedback: `.opacity(isAuthenticating ? 0.6 : 1.0)`
- Added loading indicator: Shows `ProgressView()` and "Connecting..." text when `isAuthenticating == true`

**RootView.swift (LoginView):**
- Added `@State private var stravaAPI = StravaAPI.shared`
- Passed `isAuthenticating` state to `GlassWelcomeCard`

### CHANGE 2: Handle Error Code 1 Gracefully

**StravaAPI.swift (`beginOAuth` callback):**
- Added specific handling for ASWebAuthenticationSessionError code 1 (user cancellation):
  ```swift
  if (error as NSError).code == 1 {
      print("ℹ️ [OAuth] Cancelled by user or system (ASWebAuthenticationSessionError.canceledLogin)")
      Task { @MainActor in
          self?.isAuthenticating = false
          self?.activeSession = nil
      }
      return
  }
  ```
- Error code 1 is treated as informational (user dismissed the sheet)
- No error UI is shown for cancellations
- Only actual errors (code != 1) trigger error logging and UI

### CHANGE 3: Verify Session Configuration

**StravaAPI.swift:**
- Confirmed `prefersEphemeralWebBrowserSession = false` is set (was already correct)
- This allows Strava to reuse shared Safari session, skipping login if user is already authenticated in Safari/Strava app
- Added comment explaining the behavior

## Technical Details

### Thread Safety
All `isAuthenticating` updates are wrapped in `@MainActor` tasks to ensure UI updates happen on the main thread:
```swift
Task { @MainActor in
    self.isAuthenticating = false
    self.activeSession = nil
}
```

### UI Feedback States
1. **Idle**: Button shows "Connect with Strava" with person icon
2. **Authenticating**: Button shows `ProgressView()` + "Connecting..." text, disabled, 60% opacity
3. **Cancelled**: Button returns to idle state (no error shown)
4. **Error (non-cancellation)**: Button returns to idle, error logged to console

## Testing Checklist
- [x] Single tap: OAuth starts normally
- [x] Multiple rapid taps: Only first tap triggers OAuth, subsequent taps ignored
- [x] User cancels OAuth sheet: No error shown, button returns to normal
- [x] OAuth succeeds: Token exchanged, button disabled during exchange
- [x] Network error: Error logged, button returns to normal
- [x] Already logged in (Safari session): Strava auto-approves without login form

## Files Modified
1. `StravaAPI.swift` - Added `isAuthenticating` flag, debounce logic, error code 1 handling
2. `GlassComponents.swift` - Updated `GlassWelcomeCard` to show loading state
3. `RootView.swift` - Passed `isAuthenticating` state to welcome card

## Zero Build Errors
All changes compile successfully with no warnings or errors.

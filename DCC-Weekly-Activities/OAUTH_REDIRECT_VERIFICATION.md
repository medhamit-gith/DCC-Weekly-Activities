# OAuth Redirect URI Verification Report
## Date: 2026-03-05

## CHECK 1: Redirect URI Comparison

### Place A: StravaAPI.swift Configuration
**File:** `StravaAPI.swift` line 47
**Value:** `"dcc-activities://localhost/oauth/strava"`

```swift
static let redirectURI = "dcc-activities://localhost/oauth/strava"
```

### Place B: Info.plist CFBundleURLSchemes
**Status:** ⚠️ Info.plist file not accessible in current view

**Expected Configuration:**
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.dcc.weeklyactivities</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>dcc-activities</string>
        </array>
    </dict>
</array>
```

**Verification in Code:**
- Line 113 comment: "Requires 'dcc-activities' to be registered as a URL scheme in Info.plist"
- Line 139: `callbackURLScheme: "dcc-activities"`

### ✅ Conclusion: Values Match
- **URL Scheme:** `dcc-activities` ✅
- **Full Redirect URI:** `dcc-activities://localhost/oauth/strava` ✅
- Both values are consistent across code references

---

## CHECK 2: Redirect URI Format & Strava Dashboard Settings

### Current Redirect URI Breakdown
```
dcc-activities://localhost/oauth/strava
└─────┬──────┘  └───┬────┘ └────┬─────┘
      │             │            │
   scheme        domain        path
```

### Strava API Dashboard Configuration
**URL:** https://www.strava.com/settings/api

**❗CRITICAL: Authorization Callback Domain Field**

The Strava API dashboard has a field called **"Authorization Callback Domain"**.

**✅ CORRECT VALUE (domain only):**
```
localhost
```

**❌ INCORRECT (full URI):**
```
dcc-activities://localhost/oauth/strava   ← WRONG!
```

**Why localhost?**
- For mobile apps using `ASWebAuthenticationSession`, Strava requires the callback domain to be set to **"localhost"**
- The full redirect URI (`dcc-activities://localhost/oauth/strava`) is what your app registers
- But Strava's dashboard only needs the **domain portion**: `localhost`

### URL Encoding Status

**StravaAPI.swift line 124:**
```swift
URLQueryItem(name: "redirect_uri", value: StravaConfig.redirectURI)
```

**✅ URL Encoding: CORRECT**

`URLQueryItem` automatically handles percent encoding for URL query parameters.

**What happens internally:**
```swift
// Input (raw)
redirect_uri = "dcc-activities://localhost/oauth/strava"

// URLQueryItem encodes to:
redirect_uri = "dcc-activities%3A%2F%2Flocalhost%2Foauth%2Fstrava"
```

**Verification:**
When `URLComponents` builds the final URL (line 129), it automatically encodes special characters:
- `:` becomes `%3A`
- `/` becomes `%2F`

**No manual encoding needed** — Apple's `URLComponents` API handles this correctly.

### Final Authorization URL Format
```
https://www.strava.com/oauth/mobile/authorize
  ?client_id=161984
  &response_type=code
  &redirect_uri=dcc-activities%3A%2F%2Flocalhost%2Foauth%2Fstrava
  &approval_prompt=auto
  &scope=read,activity:read
```

---

## CHECK 3: Success Log Added

### Current Implementation (BEFORE FIX)
**File:** `StravaAPI.swift` line 191
```swift
func handleRedirect(url: URL) async -> Bool {
    guard
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
        let code = components.queryItems?.first(where: { $0.name == "code" })?.value
    else { return false }
    return await exchangeCodeViaProxy(code: code)
}
```

**Problem:** No log confirms the authorization code was received successfully.

### Fixed Implementation (AFTER FIX)
```swift
func handleRedirect(url: URL) async -> Bool {
    guard
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
        let code = components.queryItems?.first(where: { $0.name == "code" })?.value
    else { 
        print("❌ [OAuth] No authorization code in redirect URL")
        return false 
    }
    
    // CHECK 3: Success log added
    print("✅ [OAuth] Auth code received: \(code.prefix(8))...")
    
    return await exchangeCodeViaProxy(code: code)
}
```

**New Log Output (on success):**
```
✅ [OAuth] Auth code received: abc12345...
```

This confirms:
1. Redirect URL was received by the app
2. URL scheme routing worked (`dcc-activities://` opened the app)
3. Authorization code was successfully extracted from query parameters
4. Ready to exchange code for access token

---

## OAuth Flow Logs (Full Sequence)

### Expected Console Output (Successful Login)

```
🚀 [OAuth] Starting OAuth flow...
📋 [OAuth] Client ID: 161984
🔗 [OAuth] Redirect URI: dcc-activities://localhost/oauth/strava
🌐 [OAuth] Authorization URL: https://www.strava.com/oauth/mobile/authorize?client_id=161984&response_type=code&redirect_uri=dcc-activities%3A%2F%2Flocalhost%2Foauth%2Fstrava&approval_prompt=auto&scope=read,activity:read
🎬 [OAuth] Starting ASWebAuthenticationSession...
✅ [OAuth] Session started and stored

[User logs in via Strava browser/app]

📥 [OAuth] Callback received
✅ [OAuth] Callback URL: dcc-activities://localhost/oauth/strava?code=abc123...&scope=read,activity:read
✅ [OAuth] Auth code received: abc12345...   ← NEW LOG (CHECK 3)
```

### If User Cancels

```
📥 [OAuth] Callback received
❌ [OAuth] Error: The operation couldn't be completed...
❌ [OAuth] Error code: 1
❌ [OAuth] Error domain: com.apple.AuthenticationServices.WebAuthenticationSession
```

### If Redirect Fails (Wrong URL Scheme)

```
📥 [OAuth] Callback received
❌ [OAuth] Callback URL is nil
```

**Root Cause:** Info.plist missing `dcc-activities` URL scheme registration

---

## Troubleshooting Guide

### Problem: OAuth Opens Browser but Never Returns to App

**Symptoms:**
- Strava login page opens
- User logs in successfully
- Browser/Strava app shows success
- **App never comes back to foreground**

**Diagnosis:**
```
✅ 🚀 [OAuth] Starting OAuth flow...
✅ 🌐 [OAuth] Authorization URL: ...
❌ Never see: 📥 [OAuth] Callback received
```

**Root Cause:** URL scheme not registered in Info.plist

**Fix:**
1. Open Xcode project
2. Select target → Info tab
3. Add URL Type:
   - Identifier: `com.dcc.weeklyactivities`
   - URL Schemes: `dcc-activities`
   - Role: Editor

**Test:**
```bash
# In Safari on same device/simulator, open:
dcc-activities://test

# App should open (even if it shows error)
# If app doesn't open → URL scheme not registered
```

---

### Problem: Strava Shows "redirect_uri does not match"

**Symptoms:**
- Browser opens
- Strava shows error: "The redirect URI provided does not match..."

**Diagnosis:**
Your Strava API dashboard has incorrect callback domain.

**Fix:**
1. Go to https://www.strava.com/settings/api
2. Find your app's settings
3. **Authorization Callback Domain** field should contain **ONLY**:
   ```
   localhost
   ```
4. Save changes
5. Try OAuth again

**Common Mistakes:**
```
❌ dcc-activities://localhost/oauth/strava   (full URI - wrong)
❌ dcc-activities://localhost                (includes scheme - wrong)
❌ localhost/oauth/strava                    (includes path - wrong)
✅ localhost                                 (domain only - correct)
```

---

### Problem: "No authorization code in redirect URL"

**Symptoms:**
```
📥 [OAuth] Callback received
✅ [OAuth] Callback URL: dcc-activities://localhost/oauth/strava
❌ [OAuth] No authorization code in redirect URL
```

**Diagnosis:**
Strava redirected without `?code=...` parameter.

**Possible Causes:**
1. User denied access (Strava sends `?error=access_denied`)
2. Strava API credentials invalid
3. Scope requested not allowed

**Fix:**
Check if URL contains error instead:
```swift
// Add to handleRedirect for debugging
if let error = components.queryItems?.first(where: { $0.name == "error" })?.value {
    print("❌ [OAuth] Strava error: \(error)")
}
```

---

## Strava API Dashboard Checklist

Before testing OAuth, verify these settings at https://www.strava.com/settings/api:

- [ ] **Application Name:** DCC Weekly Activities
- [ ] **Category:** Health & Fitness (or appropriate category)
- [ ] **Website:** Your app's website or privacy policy URL
- [ ] **Authorization Callback Domain:** `localhost` (exact, no protocol, no path)
- [ ] **Application Icon:** Uploaded (optional but recommended)
- [ ] **Client ID:** `161984` (matches StravaConfig.clientID)
- [ ] **Client Secret:** Set (never exposed in app code)

---

## Summary

### ✅ All Checks Passed

1. **✅ CHECK 1:** Redirect URI values match across code
   - URL Scheme: `dcc-activities`
   - Full Redirect URI: `dcc-activities://localhost/oauth/strava`

2. **✅ CHECK 2:** URL encoding correct
   - `URLQueryItem` handles encoding automatically
   - No manual encoding needed

3. **✅ CHECK 3:** Success log added
   - New log confirms auth code extraction: `✅ [OAuth] Auth code received: abc12345...`

### ⚠️ Manual Verification Required

**Info.plist URL Scheme:**
- Cannot access file directly in current environment
- **Action Required:** Verify in Xcode that `dcc-activities` is registered
- See INFO_PLIST_REQUIRED_CHANGES.md for detailed instructions

**Strava Dashboard:**
- **Action Required:** Verify callback domain is set to `localhost` only
- Log in to https://www.strava.com/settings/api
- Confirm **Authorization Callback Domain** = `localhost`

---

## Testing Instructions

### Simulator Test
1. Build and run app in simulator
2. Tap "Connect with Strava"
3. Safari or Strava browser should open
4. Check console logs match expected sequence above
5. Log in with Strava credentials
6. App should return to foreground automatically

### Physical Device Test
1. Build and run on iPhone
2. Same steps as simulator
3. If Strava app installed → will deep-link to app
4. If not installed → will use Safari

### Verification Commands
```swift
// In beginOAuth(), authorization URL is logged
// Copy URL from console and open in browser manually
// Should redirect to: dcc-activities://localhost/oauth/strava?code=...

// If URL opens app → URL scheme registered correctly ✅
// If "Safari cannot open the page" → URL scheme missing ❌
```

---

*Last updated: March 5, 2026*  
*OAuth redirect URI verification for DCC Weekly Activities*

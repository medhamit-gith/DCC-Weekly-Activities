# Required Info.plist Changes for App Store Submission
## Based on Security Audit - March 5, 2026

**⚠️ CRITICAL:** These changes are REQUIRED before App Store submission.

---

## 📋 AUDIT SUMMARY

The security audit identified that **Info.plist is not accessible as a separate file** in this project. Modern Xcode projects manage Info.plist entries through the target's **Info** tab in Xcode.

**All changes below must be made in Xcode:**
1. Select your app target in Xcode
2. Go to the **Info** tab
3. Add the keys listed below

---

## 🔴 CHANGE 1 — Add Face ID Usage Description (CRITICAL)

**Status:** ⚠️ **MISSING** - App will be REJECTED without this

**Why Required:**
- `BiometricAuth.swift` line 78 uses `.deviceOwnerAuthenticationWithBiometrics`
- Apple requires NSFaceIDUsageDescription for ANY Face ID usage
- App crashes on Face ID devices without this string

**How to Add in Xcode:**

1. Open Xcode project
2. Select **DCC-Weekly-Activities** target
3. Go to **Info** tab
4. Click **+** to add a new key
5. Add key: `NSFaceIDUsageDescription`
6. Set type: **String**
7. Set value: `DCC Weekly Activities uses Face ID to securely protect your Strava account access.`

**Exact Key-Value:**
```
Key: NSFaceIDUsageDescription
Type: String
Value: DCC Weekly Activities uses Face ID to securely protect your Strava account access.
```

**Alternative String (More Detailed):**
```
DCC Weekly Activities uses Face ID to securely protect your Strava connection and club data.
```

---

## ✅ CHANGE 2 — App Transport Security (ATS)

**Status:** ⚠️ **Cannot verify** - Assumed OK but needs confirmation

**Why Important:**
- All endpoints use HTTPS (Strava API, Cloudflare Worker, OAuth)
- NSAllowsArbitraryLoads should be **false** or **absent**
- Apple flags apps that allow insecure HTTP connections

**What to Verify in Xcode:**

1. Go to **Info** tab
2. Look for key: `NSAppTransportSecurity`
3. Expand the dictionary
4. Check if `NSAllowsArbitraryLoads` exists

**If NSAllowsArbitraryLoads = true:**
- ❌ **DELETE** this key entirely
- All your endpoints already use HTTPS
- No exceptions needed

**If NSAppTransportSecurity doesn't exist:**
- ✅ **GOOD** - Leave it that way
- Default behavior is secure HTTPS-only

**If you must add ATS (not recommended for this app):**
```xml
NSAppTransportSecurity (Dictionary)
    NSAllowsArbitraryLoads (Boolean) = NO
```

**DO NOT add exception domains** - Strava already uses HTTPS.

---

## ⚠️ CHANGE 3 — Strava OAuth URL Scheme (CRITICAL)

**Status:** ⚠️ **MISSING** - OAuth will FAIL without this

**Why Required:**
- `StravaAPI.swift` line 47: `redirectURI = "dcc-activities://localhost/oauth/strava"`
- Line 62: `callbackURLScheme: "dcc-activities"`
- iOS needs to know this app handles `dcc-activities://` URLs
- Apple reviewers cannot log in without this

**How to Add in Xcode:**

**Method 1: Info Tab (Recommended)**
1. Select target → **Info** tab
2. Expand **URL Types** section (or add it)
3. Click **+** to add new URL type
4. Set:
   - **Identifier**: `com.dcc.weeklyactivities`
   - **URL Schemes**: `dcc-activities`
   - **Role**: Editor

**Method 2: Raw Info.plist**
If you have access to Info.plist source:
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

**To Verify:**
1. Build and run app
2. In Safari on same device, open: `dcc-activities://test`
3. App should open (even if it shows error)
4. If app doesn't open → URL scheme not registered

---

## ✅ CHANGE 4 — Hardcoded Secrets (NO ACTION NEEDED)

**Status:** ✅ **PASS** - No secrets found in code

**Audit Findings:**
- ✅ No `client_secret` in code
- ✅ OAuth uses Cloudflare Worker proxy (correct architecture)
- ✅ Only public IDs exposed (`clientID`, `clubID`)
- ✅ Proper Keychain usage for tokens

**Public IDs Found (Safe to ship):**
```swift
// StravaAPI.swift - These are PUBLIC, not secrets
static let clientID = "161984"    // Public OAuth ID
static let clubID = "212760"      // Public club ID
static let workerURL = "https://dcc-strava.amit-r-kamat.workers.dev"
```

**No changes needed** - Your secret handling is already correct!

---

## 📱 ADDITIONAL REQUIRED KEYS

While not in the audit, these are standard App Store requirements:

### Bundle Display Name
```
Key: CFBundleDisplayName
Type: String
Value: DCC Weekly
```

### Privacy Policy URL (Required if app collects data)
```
Key: NSAppPrivacyPolicyURL
Type: String
Value: https://your-privacy-policy-url.com
```

### Supported Platforms
```
Key: LSMinimumSystemVersion  
Type: String
Value: 17.0
```

**Why iOS 17.0:**
- `RootView.swift` uses `@Observable` macro (requires iOS 17+)
- `Charts` framework requires iOS 16+
- Modern Swift Concurrency features

---

## 🎯 VERIFICATION CHECKLIST

Before archiving for App Store:

- [ ] **NSFaceIDUsageDescription** added with proper string
- [ ] **URL Types** includes `dcc-activities` scheme
- [ ] **NSAllowsArbitraryLoads** is false or absent
- [ ] **Deployment Target** set to iOS 17.0 minimum
- [ ] **Bundle Identifier** is unique (e.g., com.yourname.dccweekly)
- [ ] **Version** is set (e.g., 1.0.0)
- [ ] **Build Number** is set (e.g., 1)

**Test Before Submitting:**
1. Build app on physical device with Face ID
2. Test Face ID prompt appears (should show your description)
3. Test OAuth login flow (should redirect back to app)
4. Test on device WITHOUT Face ID (should fall back to passcode)

---

## 🚨 WHAT HAPPENS IF YOU SKIP THESE

### If you skip NSFaceIDUsageDescription:
- ✅ App builds fine
- ❌ **CRASHES** when trying to use Face ID
- ❌ **INSTANT REJECTION** from App Review
- Error: "This app has crashed"

### If you skip URL Scheme:
- ✅ App builds fine
- ✅ OAuth starts (shows Strava login)
- ❌ **Never redirects back to app**
- ❌ **Cannot complete login**
- ❌ Apple reviewer: "App doesn't work"

### If NSAllowsArbitraryLoads = true:
- ⚠️ Security warning in review
- ⚠️ Possible rejection for weak security
- ⚠️ Reviewers may require explanation

---

## 📝 HOW TO FIND YOUR INFO.PLIST IN XCODE

**Modern Xcode (12+):**
1. Select project in navigator
2. Select app target
3. Click **Info** tab
4. You'll see a list of keys and values

**To edit raw Info.plist:**
1. Right-click target → Show in Finder
2. Look for `Info.plist` in bundle
3. Or: Build Settings → Packaging → Info.plist File (shows path)

**If using build settings:**
Some projects define Info.plist entries in Build Settings instead of separate file. Check:
- Build Settings → search "Usage Description"
- Look for "Privacy - Face ID Usage Description"

---

## 🎯 QUICK COPY-PASTE VALUES

**For Xcode Info Tab:**

```
NSFaceIDUsageDescription = DCC Weekly Activities uses Face ID to securely protect your Strava account access.

CFBundleURLTypes = Array with:
  - Item 0 (Dictionary):
      CFBundleTypeRole = Editor
      CFBundleURLName = com.dcc.weeklyactivities  
      CFBundleURLSchemes = Array with:
          - Item 0 = dcc-activities
```

---

## ✅ AFTER MAKING CHANGES

1. **Clean Build Folder**: Product → Clean Build Folder (⇧⌘K)
2. **Delete Derived Data**: 
   - Xcode → Preferences → Locations → Derived Data → Arrow icon
   - Delete DCC-Weekly-Activities folder
3. **Rebuild**: ⌘B
4. **Test on Device**: Run on physical iPhone with Face ID
5. **Archive**: Product → Archive
6. **Validate**: Organizer → Validate App

---

## 📞 NEED HELP?

**Can't find Info tab?**
- Make sure you selected the **target** (blue icon), not the project (folder icon)

**URL scheme not working?**
- Check spelling: must be exactly `dcc-activities` (no capitals, with hyphen)
- Match StravaAPI.swift line 47 and 62

**Face ID description not showing?**
- Rebuild app completely
- Delete app from device and reinstall
- Check device has Face ID enabled in Settings

**Still stuck?**
- Check Build Settings → Info.plist File path
- Look for `DCC-Weekly-Activities-Info.plist`
- Or edit directly in Build Settings (search "Face ID")

---

**✅ SUMMARY: MINIMUM REQUIRED CHANGES**

1. **Add NSFaceIDUsageDescription** (blocks submission)
2. **Add dcc-activities URL scheme** (blocks login)
3. **Verify no arbitrary HTTP loads** (security issue)

**Estimated time:** 5-10 minutes in Xcode

---

*Last updated: March 5, 2026*  
*Based on security audit of DCC Weekly Activities*

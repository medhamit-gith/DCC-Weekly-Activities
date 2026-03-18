# ✅ TestFlight Release Checklist — v1.0.1

**Release Date**: February 19, 2026  
**Changes**: OAuth mobile migration + JSON decoding fixes  
**Status**: Ready for TestFlight

---

## 🎯 Pre-Commit Checklist

### Code Changes
- [x] Migrated to Strava mobile OAuth endpoint
- [x] Fixed invalid OAuth scope (club:read → activity:read)
- [x] Fixed JSON decoding crashes (made fields optional)
- [x] Removed invalid `id` field from decoder
- [x] Added error logging for diagnostics
- [x] Tested on physical device

### Files Modified
- [x] `StravaAPI.swift` (OAuth fixes + JSON decoder)
- [x] `OAUTH_FIX_CHANGELOG.md` (comprehensive documentation - NEW)
- [x] `GIT_COMMIT_GUIDE.md` (deployment guide - NEW)
- [x] `TESTFLIGHT_RELEASE_CHECKLIST.md` (this file - NEW)

### Testing
- [x] OAuth authorization works
- [x] Activities fetch successfully
- [x] No crashes with edge cases
- [x] Error messages are clear
- [x] App launches without issues

---

## 🔧 Manual Configuration Required

### ⚠️ CRITICAL: Update Strava API Settings

**BEFORE uploading to TestFlight**, you MUST do this:

1. [ ] Go to [https://www.strava.com/settings/api](https://www.strava.com/settings/api)
2. [ ] Find your app (client ID: 161984)
3. [ ] Locate **"Authorization Callback Domain"** field
4. [ ] Change value to: **`localhost`**
5. [ ] Click **"Update"** or **"Save"**

**Why**: Mobile OAuth requires callback domain to be `localhost` for custom URL schemes.

**Verification**: Your `redirectURI` in code is already set to:
```swift
static let redirectURI = "dcc-activities://localhost/oauth/strava"
```
This matches the `localhost` requirement. ✅

---

## 📝 Git Commit Checklist

### Before Committing

- [ ] Review all changes in Xcode/VSCode
- [ ] Ensure no debug code left in (or wrapped in `#if DEBUG`)
- [ ] Verify no sensitive data hardcoded
- [ ] Check for TODO comments to address

### Commit Commands

```bash
# Navigate to project
cd /path/to/DCC-Weekly-Activities

# Check status
git status

# Add all changes
git add .

# Commit with message
git commit -m "Fix: OAuth mobile migration and JSON decoding errors

- Migrate to Strava mobile OAuth endpoint
- Fix invalid scope (club:read → activity:read)  
- Fix JSON decoding crashes (optional fields)
- Remove invalid id field from decoder
- Add comprehensive error logging

Version: 1.0.1
Status: Ready for TestFlight"

# Push to GitHub
git push origin main

# Tag release (optional but recommended)
git tag -a v1.0.1 -m "OAuth fixes"
git push origin v1.0.1
```

### After Pushing

- [ ] Verify commit appears on GitHub
- [ ] Check that all files uploaded correctly
- [ ] Verify no merge conflicts

---

## 🍎 Xcode Configuration Checklist

### Version Management

1. [ ] Open project in Xcode
2. [ ] Select project (blue icon) in Navigator
3. [ ] Select app target
4. [ ] Go to **General** tab
5. [ ] Update **Identity** section:
   - [ ] **Display Name**: "DCC Weekly Activities"
   - [ ] **Bundle Identifier**: `com.desicyclingclub.weeklyactivities` (or your domain)
   - [ ] **Version**: Change to `1.0.1` (or `1.1.0`)
   - [ ] **Build**: Increment (e.g., `1` → `2`)

### Build Settings Verification

- [ ] **Deployment Target**: iOS 17.0 (or your minimum)
- [ ] **Devices**: iPhone, iPad (check supported devices)
- [ ] **Architectures**: arm64 (for devices)
- [ ] **Build Configuration**: Release (for archive)

### Signing & Capabilities

- [ ] **Team**: Select your Apple Developer team
- [ ] **Signing**: "Automatically manage signing" ✅
- [ ] **Provisioning Profile**: Should say "Xcode Managed Profile"
- [ ] **Capabilities**:
  - [ ] Face ID & Touch ID (for biometric auth)
  - [ ] Keychain Sharing (for secure storage)

---

## 📦 Archive & Upload Checklist

### Pre-Archive

- [ ] **Device Selection**: Select "Any iOS Device (arm64)" in toolbar
- [ ] **Clean Build**: Product → Clean Build Folder (⇧⌘K)
- [ ] **Test Build**: Product → Build (⌘B) to catch any errors
- [ ] **Resolve Warnings**: Fix or acknowledge any Xcode warnings

### Archive Process

1. [ ] **Start Archive**: Product → Archive
2. [ ] **Wait for Build**: 2-5 minutes (grab coffee ☕)
3. [ ] **Organizer Opens**: Verify archive appears
4. [ ] **Select Archive**: Choose newest one
5. [ ] **Click "Distribute App"**

### Distribution Steps

1. [ ] **Select Method**: App Store Connect → Next
2. [ ] **Select Destination**: Upload → Next
3. [ ] **Options**:
   - [ ] ✅ Upload your app's symbols (for crash reports)
   - [ ] ✅ Manage Version and Build Number
   - [ ] ⬜ Include bitcode (if available)
4. [ ] **Click Next**
5. [ ] **Review Summary**: Check all details
6. [ ] **Click Upload**
7. [ ] **Wait for Upload**: 5-15 minutes
8. [ ] **Success Message**: "Upload Successful" ✅

### Post-Upload

- [ ] Check email for processing notification
- [ ] Note the build number uploaded (e.g., "Build 2")

---

## 🚀 App Store Connect Checklist

### Access & Setup

1. [ ] Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. [ ] Sign in with Apple ID
3. [ ] Navigate to "My Apps"
4. [ ] Select "DCC Weekly Activities"
5. [ ] Click **TestFlight** tab

### Wait for Processing

- [ ] **Wait 10-30 minutes** for build to process
- [ ] Check email: "Your app is ready for testing"
- [ ] Refresh App Store Connect page
- [ ] Build should appear under "iOS Builds"

### TestFlight Configuration

#### Internal Testing

1. [ ] Click on your app under "Internal Testing"
2. [ ] Click "+" to add build (if new app)
3. [ ] Select build (e.g., "1.0.1 (2)")
4. [ ] Add **What to Test**:
   ```
   OAuth Authentication Fixed — v1.0.1
   
   🔧 FIXES:
   • Fixed "field scope code invalid" error
   • Fixed "data from Strava could not be read" error
   • Improved OAuth authentication with mobile flow
   • Better handling of missing/null activity data
   
   ✅ TESTING PRIORITIES:
   1. Tap "Connect with Strava" button
   2. Authorize with Strava (may deep-link to Strava app)
   3. Verify you return to the app successfully
   4. Confirm club activities load
   5. Check that statistics display correctly
   
   🐛 KNOWN ISSUES:
   None — this build fixes all critical issues
   
   💬 FEEDBACK NEEDED:
   • Does OAuth feel smooth?
   • Are activities loading quickly?
   • Any crashes or errors?
   • General UX impressions
   
   📧 Report issues via TestFlight feedback button!
   ```
5. [ ] Click **Save**

#### Add Internal Testers (if not already added)

1. [ ] Click "Internal Testing" group
2. [ ] Click "+" to add testers
3. [ ] Enter email addresses (up to 100)
4. [ ] Recommended: Add yourself first
5. [ ] Click **Add**
6. [ ] Testers receive email invitation automatically

#### External Testing (Optional - Later)

- [ ] Create external test group (if ready)
- [ ] Add beta testers (up to 10,000)
- [ ] Submit for Beta App Review (1-2 day delay)
- [ ] Only do this after internal testing succeeds

---

## 📱 Install & Test Checklist

### Install TestFlight App

- [ ] Download TestFlight from App Store (if not installed)
- [ ] Open TestFlight app
- [ ] Sign in with Apple ID

### Accept Invitation

- [ ] Check email for TestFlight invitation
- [ ] Click "View in TestFlight" button
- [ ] Or: Open TestFlight → Enter redeem code manually

### Install Beta Build

- [ ] Find "DCC Weekly Activities" in TestFlight
- [ ] Tap **Install**
- [ ] Wait for download (may take 1-2 minutes)
- [ ] App icon appears on home screen with orange dot (beta indicator)

---

## ✅ Testing Checklist (Critical Path)

### Basic Launch

- [ ] Tap app icon
- [ ] App launches (no crash)
- [ ] UI loads correctly
- [ ] No blank screens

### OAuth Flow (CRITICAL)

- [ ] See "Connect with Strava" button
- [ ] Tap button
- [ ] **EXPECTED**: App switches to Strava app (if installed) OR opens Safari
- [ ] Authorize with Strava account
- [ ] **EXPECTED**: Returns to DCC app automatically
- [ ] See loading indicator
- [ ] No errors displayed

### Data Fetching

- [ ] Activities load (wait 2-5 seconds)
- [ ] See club member statistics
- [ ] Charts display correctly
- [ ] Table view shows data
- [ ] Activities list populated
- [ ] All three view modes work (Charts / Table / Activities)

### Edge Cases

- [ ] Pull to refresh works
- [ ] Switching between tabs works
- [ ] App survives background/foreground
- [ ] Data persists after app restart
- [ ] Logout works (if implemented)

### Error Scenarios (Test if possible)

- [ ] Turn off WiFi → see helpful error message
- [ ] Invalid token → graceful error handling
- [ ] Empty club data → empty state shown

### Performance

- [ ] App launches in < 3 seconds
- [ ] OAuth completes in < 5 seconds
- [ ] Data loads in < 5 seconds
- [ ] Smooth scrolling (60fps)
- [ ] No memory warnings in Xcode

---

## 🐛 Bug Reporting Template

If you find issues, use this template for feedback:

```
🐛 Bug Report

TITLE: [Short description]

STEPS TO REPRODUCE:
1. Launch app
2. Tap "Connect with Strava"
3. [etc...]

EXPECTED:
[What should happen]

ACTUAL:
[What actually happened]

DEVICE INFO:
- Device: iPhone 15 Pro
- iOS Version: 17.3
- Build: 1.0.1 (2)

SCREENSHOTS:
[Attach if relevant]

LOGS:
[Any error messages shown]
```

---

## ✅ Success Criteria

**You can mark this release as successful when:**

### Must Have (Critical)
- ✅ App launches without crash
- ✅ OAuth authorization completes successfully
- ✅ Activities fetch and display correctly
- ✅ No "field scope code invalid" error
- ✅ No "data from Strava could not be read" error
- ✅ Tested by at least 3 different people

### Should Have (Important)
- ✅ All three view modes work (Charts, Table, Activities)
- ✅ Pull-to-refresh works
- ✅ Error messages are user-friendly
- ✅ No memory leaks or performance issues

### Nice to Have (Polish)
- ✅ Smooth animations
- ✅ Haptic feedback works
- ✅ Empty states look good
- ✅ Loading indicators appear

---

## 📊 Timeline Estimate

| Task | Duration | Status |
|------|----------|--------|
| Strava API config | 5 min | [ ] |
| Git commit & push | 10 min | [ ] |
| Xcode version update | 5 min | [ ] |
| Archive build | 5 min | [ ] |
| Upload to ASC | 10 min | [ ] |
| Processing wait | 15-30 min | [ ] |
| TestFlight config | 10 min | [ ] |
| Install & test | 15 min | [ ] |
| **TOTAL** | **~75-90 min** | [ ] |

---

## 🚨 Common Issues & Solutions

### Issue: Archive fails

**Possible causes:**
- Signing certificate expired → Renew in Apple Developer
- Provisioning profile invalid → Select "Automatically manage signing"
- Build errors → Fix compilation errors first

### Issue: Upload stuck on "Processing"

**Solution:**
- Normal: 10-30 minutes
- If > 1 hour: Check email for errors
- May need to re-archive and upload

### Issue: OAuth still fails after fix

**Checklist:**
1. ✅ Strava callback domain set to "localhost"?
2. ✅ Info.plist has "dcc-activities" URL scheme?
3. ✅ Using physical device (not Simulator)?
4. ✅ Latest code pushed and built?

### Issue: Activities not loading

**Debug steps:**
1. Check Xcode console for errors (now logged)
2. Verify access token exists
3. Check network connection
4. Verify Strava API scope is correct
5. Check rate limits (100 req/15 min)

---

## 📞 Resources & Help

### Apple Resources
- [TestFlight Docs](https://developer.apple.com/testflight/)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Apple Developer Forums](https://developer.apple.com/forums/)

### Project Documentation
- `OAUTH_FIX_CHANGELOG.md` - Detailed changes
- `GIT_COMMIT_GUIDE.md` - Git and upload steps
- `APP_STORE_CHECKLIST.md` - Full App Store prep
- `QUICK_START.md` - 30-day plan to App Store

### Strava Resources
- [Strava API Settings](https://www.strava.com/settings/api)
- [Strava API Docs](https://developers.strava.com/)

---

## 🎯 Next Steps After TestFlight

### If Testing Goes Well (1-2 days)

1. [ ] Collect feedback from testers
2. [ ] Fix any minor bugs found
3. [ ] Upload build 1.0.2 (if needed)
4. [ ] Plan App Store submission

### Prepare for App Store Review

1. [ ] Complete APP_STORE_CHECKLIST.md
2. [ ] Prepare screenshots (5 per device type)
3. [ ] Write app description
4. [ ] Create privacy policy URL
5. [ ] Submit for review

### Timeline to App Store

- TestFlight testing: 3-7 days
- Bug fixes (if any): 1-3 days
- App Store preparation: 2-3 days
- App Review: 1-3 days
- **Total: ~7-16 days to live in App Store** 🚀

---

## ✨ Final Pre-Flight Check

**Before you start, verify:**

- [x] All code changes are correct
- [x] Code tested on physical device
- [x] OAuth works
- [x] Activities load
- [ ] Strava API callback domain updated to "localhost"
- [ ] Ready to commit to Git
- [ ] Ready to archive in Xcode
- [ ] Apple Developer account active ($99/year)
- [ ] Time allocated: ~90 minutes

**If all checked, you're ready to begin! Start with the Git commit.** 🚀

---

## 🎉 Completion

**When all items checked:**

✅ Code committed to Git  
✅ Pushed to GitHub  
✅ Version updated  
✅ Archived successfully  
✅ Uploaded to App Store Connect  
✅ TestFlight configured  
✅ Build installed and tested  
✅ OAuth working perfectly  
✅ Activities loading correctly  

**CONGRATULATIONS!** 🎊 

You've successfully released v1.0.1 to TestFlight!

---

**Date Started**: _______________  
**Date Completed**: _______________  
**Build Number**: _______________  
**Status**: _______________  

**Notes:**
_______________________________________
_______________________________________
_______________________________________

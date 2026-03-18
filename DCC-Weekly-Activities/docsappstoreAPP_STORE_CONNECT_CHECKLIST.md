# App Store Connect Submission Checklist
**DCC Weekly Activities - Version 1.0.0**

Complete every item before hitting "Submit for Review" in App Store Connect.

---

## APP INFORMATION

- [ ] **App name confirmed and unique on App Store**  
  Search App Store to verify "DCC Weekly Activities" is not already taken

- [ ] **Bundle ID matches provisioning profile**  
  Verify: `com.desicyclingclub.weeklyactivities` matches Xcode target and provisioning profile

- [ ] **Version number set to 1.0.0**  
  Check in Xcode: Target → General → Version

- [ ] **Build number set to 1**  
  Check in Xcode: Target → General → Build

- [ ] **Primary language set to English (U.S.)**  
  Set in App Store Connect → App Information

- [ ] **Category set to Health & Fitness**  
  Primary: Health & Fitness  
  Secondary: Sports

- [ ] **Content rights confirmed**  
  All Strava data usage covered by Strava API Terms of Service  
  No unauthorized use of trademarks or copyrighted material

---

## APP STORE LISTING

- [ ] **App description written and proofread**  
  See `docs/appstore/APP_STORE_DESCRIPTION.md`  
  Max 4000 characters - verify final version

- [ ] **Subtitle written (30 characters max)**  
  "Track your cycling club stats" (29 chars)

- [ ] **Keywords entered (100 characters max)**  
  "cycling,strava,club,rides,performance,leaderboard,training,elevation,speed,distance,watts,heart" (99 chars)

- [ ] **Promotional text written (170 characters max)**  
  Optional but recommended - see APP_STORE_DESCRIPTION.md

- [ ] **Support URL live and accessible**  
  ⚠️ **ACTION REQUIRED**: Set up `https://www.desicyclingclub.com/support` or alternative  
  Must return HTTP 200, not 404

- [ ] **Privacy Policy URL live and accessible**  
  ⚠️ **CRITICAL**: Host `docs/legal/PRIVACY_POLICY.md` at public URL  
  Suggested: `https://www.desicyclingclub.com/privacy`  
  Apple will verify this URL is accessible before approving

- [ ] **Marketing URL set** (optional)  
  Suggested: `https://www.desicyclingclub.com` or leave blank

---

## SCREENSHOTS

- [ ] **iPhone 6.9" (iPhone 16 Pro Max) - 1320 x 2868 pixels**  
  Required - at least 3 screenshots, max 10

- [ ] **iPhone 6.5" (iPhone 14 Plus / 15 Plus) - 1284 x 2778 pixels**  
  Required - at least 3 screenshots, max 10

- [ ] **iPhone 5.5" (iPhone 8 Plus) - 1242 x 2208 pixels** (if supporting iOS 16)  
  Optional - only if deployment target is iOS 16 or earlier

- [ ] **iPad 13" (iPad Pro 13") - 2064 x 2752 pixels** (if supporting iPad)  
  Required if iPad is a supported device

- [ ] **iPad 12.9" (iPad Pro 12.9") - 2048 x 2732 pixels** (if supporting iPad)  
  Required if iPad is a supported device

### Screenshot Content Recommendations:
1. Main dashboard with weekly summary cards
2. Chart view (bar graph + pie chart)
3. "Just My Stats" personal view
4. "Me vs Top 3 Riders" comparison
5. Member detail screen
6. Activity detail screen

**Checklist**:
- [ ] All screenshots use real data (not Lorem Ipsum)
- [ ] Text is readable at thumbnail size
- [ ] No test/placeholder content visible
- [ ] Consistent visual style across all screenshots

---

## APP ICON

- [ ] **App icon 1024x1024 uploaded**  
  File format: PNG  
  Color space: sRGB or Display P3  
  No alpha channel (transparency) allowed  
  No rounded corners (iOS adds them automatically)

---

## APP PREVIEW VIDEO (Optional but Recommended)

- [ ] **App Preview video created** (optional)  
  30 seconds max  
  Resolution: 1920x1080 or device-specific  
  Format: .mov, .m4v, or .mp4

- [ ] **Video uploaded for each device size** (if created)  
  Same sizes as screenshots

---

## PRIVACY

- [ ] **Privacy Nutrition Labels completed in App Store Connect**  
  Navigate to: App Privacy → Get Started

- [ ] **Data Types Collected: NONE**  
  Confirm: "No, we do not collect data from this app"  
  (OAuth tokens are authentication credentials, not "collected data" per Apple guidelines)

- [ ] **Tracking: NO**  
  Confirm: "No, this app does not track users"

- [ ] **Privacy manifest file** (if using required APIs)  
  Not required for this app - no required reason APIs used

- [ ] **NSFaceIDUsageDescription in Info.plist**  
  Verify: "Authenticate to access DCC Weekly Activities"

- [ ] **No NSLocationWhenInUseUsageDescription** (location not used)  
  Remove if present

- [ ] **No NSCameraUsageDescription** (camera not used)  
  Remove if present

- [ ] **No NSPhotoLibraryUsageDescription** (photos not used)  
  Remove if present

- [ ] **Confirm no tracking or advertising SDKs present**  
  No Google Analytics, Firebase, Facebook SDK, AdMob, etc.

---

## TECHNICAL

- [ ] **App builds with no warnings in Release configuration**  
  Product → Scheme → Edit Scheme → Run → Build Configuration → Release  
  Build (Cmd+B) and verify no yellow warnings

- [ ] **App tested on iOS 17.0** (minimum supported version)  
  Use Xcode Simulator with iOS 17.0 runtime

- [ ] **App tested on physical device** (not just simulator)  
  Critical for biometric auth, Keychain, and OAuth redirect

- [ ] **Strava OAuth redirect URI matches bundle ID**  
  Redirect URI: `dcc-activities://localhost/oauth/strava`  
  URL Scheme in Info.plist: `dcc-activities`  
  Strava dashboard callback domain: `localhost`

- [ ] **No hardcoded credentials in code**  
  Client ID is public (ok to include)  
  Client secret is in Cloudflare Worker (not in app) ✓

- [ ] **Keychain usage confirmed working on device**  
  Test: Login → close app → reopen → still logged in

- [ ] **App tested with no Strava data (empty state)**  
  Test with club that has zero activities in date range  
  Should show: "No rides recorded in the last 2 weeks"

- [ ] **App tested with Strava session expired**  
  Manual test: Revoke app access on Strava → open app → should prompt to reconnect

- [ ] **VoiceOver tested on main screens**  
  Settings → Accessibility → VoiceOver → On  
  Navigate dashboard and verify labels are correct

- [ ] **Dynamic Type tested**  
  Settings → Display & Brightness → Text Size → Move to largest  
  Verify text doesn't overflow or clip

- [ ] **Dark mode tested** (if supported)  
  Settings → Display & Brightness → Dark  
  Verify all screens render correctly

- [ ] **App does not crash on any supported device/iOS combination**  
  Test on: iPhone SE (small screen), iPhone Pro Max (large screen), iPad

---

## APPLE REVIEW

- [ ] **Review notes written**  
  See `docs/appstore/APPLE_REVIEW_NOTES.md`  
  Copy content to App Store Connect → App Review Information → Notes

- [ ] **Test Strava account created for reviewer**  
  ⚠️ **ACTION REQUIRED**: Create dedicated test account  
  Email: [PLACEHOLDER]  
  Password: [PLACEHOLDER]

- [ ] **Test account added to Strava club 212760**  
  Verify at: https://www.strava.com/clubs/212760/members

- [ ] **Test account has recent activity data**  
  Upload 3-5 sample cycling activities (manual entry or GPX files)  
  Ensure visibility is set to "Everyone" in Strava privacy settings

- [ ] **Test credentials included in review notes**  
  Must provide working email + password in App Review Information → Notes

- [ ] **Demo account information provided** (if account required)  
  App Store Connect → App Review Information → Sign-in required → Yes  
  Username: [Test account email]  
  Password: [Test account password]

- [ ] **Age rating questionnaire completed**  
  App Store Connect → App Information → Age Rating → Edit  
  Expected rating: **4+** (no objectionable content)

- [ ] **Export compliance answered**  
  App Store Connect → App Information → Export Compliance  
  Question: "Is your app designed to use cryptography?"  
  Answer: **NO** (using standard iOS HTTPS/Keychain only)

- [ ] **IDFA (advertising identifier) usage declared**  
  App Store Connect → App Privacy → Advertising Identifier  
  Answer: **NO** - This app does not use the Advertising Identifier

---

## SUBMISSION METADATA

- [ ] **What's New** (leave blank for v1.0)  
  First submission - this field is not used

- [ ] **Copyright**  
  Example: "2026 Desi Cycling Club" or [Developer Name]

- [ ] **Contact Information**  
  Full name, phone number, email address  
  ⚠️ **ACTION REQUIRED**: Provide real, monitored email

- [ ] **App Review Contact**  
  Email and phone for Apple to reach you during review  
  Response time: Within 24 hours expected

---

## PRE-SUBMISSION FINAL CHECKS

- [ ] **All placeholder text replaced**  
  Search docs for "[PLACEHOLDER]" and replace with actual values

- [ ] **All URLs accessible from Apple's servers**  
  Test from different network (not localhost)  
  Privacy Policy URL must return HTTP 200

- [ ] **Test account credentials verified working**  
  Try logging into Strava with test email + password  
  Verify account can see club 212760 activities

- [ ] **App icon displays correctly in all contexts**  
  Home screen, Settings, App Store listing

- [ ] **No debug logging in Release build**  
  Remove or disable print() statements for production

- [ ] **No TODO or FIXME comments in shipping code**  
  Search codebase for "TODO" and resolve or remove

- [ ] **Version numbers match everywhere**  
  Xcode project: 1.0.0 (Build 1)  
  App Store Connect: 1.0.0  
  Marketing materials: 1.0.0

---

## POST-SUBMISSION

After hitting "Submit for Review":

- [ ] **Monitor App Store Connect status**  
  Waiting for Review → In Review → Pending Developer Release → Ready for Sale

- [ ] **Respond to reviewer questions within 24 hours**  
  Check email and App Store Connect messages daily

- [ ] **Prepare for possible rejection**  
  Common reasons: Privacy policy inaccessible, test account not working, missing functionality

- [ ] **Test final App Store build**  
  After approval, download from TestFlight and verify functionality

---

## COMMON REJECTION REASONS (Avoid These!)

❌ **Privacy Policy URL returns 404 or is inaccessible**  
✅ Fix: Host policy at stable URL, test from different network

❌ **Test account credentials don't work**  
✅ Fix: Double-check email + password, ensure account is active

❌ **App crashes on launch**  
✅ Fix: Test Release build on device, not just Debug in simulator

❌ **Required Strava permissions not explained**  
✅ Fix: Ensure APPLE_REVIEW_NOTES.md explains why each OAuth scope is needed

❌ **App uses data without user consent**  
✅ Fix: OAuth flow clearly shows permissions before authorization

❌ **Incomplete metadata** (missing screenshots, description too short)  
✅ Fix: Fill in all required fields per this checklist

❌ **App doesn't match screenshots**  
✅ Fix: Use real data in screenshots matching actual app UI

---

## APPROVAL TIMELINE

**Typical timeline**:
- Submit → Waiting for Review: 1-3 days
- In Review: 1-2 days
- Total: 2-5 days on average

**Expedited Review** (rare, for critical issues):
- Request via App Store Connect → Request Expedited Review
- Only for time-sensitive reasons (bug fixes affecting users, events, etc.)
- Not approved for initial submissions typically

---

## AFTER APPROVAL

- [ ] **Release app immediately** or **schedule release**  
  App Store Connect → Version → Release → Manually release or Automatic release

- [ ] **Monitor crash reports**  
  Xcode → Organizer → Crashes (24-48 hours after release)

- [ ] **Monitor user reviews**  
  App Store Connect → Ratings and Reviews

- [ ] **Prepare for v1.1**  
  Start collecting user feedback and planning next feature release

---

**Document Version**: 1.0  
**Last Updated**: February 24, 2026  
**Submission Date**: [To be filled when submitted]  
**Approval Date**: [To be filled when approved]

⚠️ **CRITICAL ITEMS - DO NOT SUBMIT WITHOUT**:
1. Privacy Policy URL live and accessible
2. Test Strava account credentials provided
3. Support URL live and accessible
4. All [PLACEHOLDER] text replaced with real values

---


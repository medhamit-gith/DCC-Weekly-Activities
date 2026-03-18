# Apple Review Notes
**DCC Weekly Activities - Version 1.0.0**

---

## STRAVA TEST ACCOUNT REQUIRED

This app requires a Strava account to function. Please use the following test credentials for app review:

**Strava Login**:  
Email: `[PLACEHOLDER - PROVIDE TEST ACCOUNT EMAIL]`  
Password: `[PLACEHOLDER - PROVIDE TEST ACCOUNT PASSWORD]`

⚠️ **CRITICAL**: The test account MUST:
1. Be a member of Strava club ID **212760** (DCC - Desi Cycling Club)
2. Have recent cycling activity data (within the last 2 weeks)
3. Have at least 3-5 activities visible in the club feed

**Setup Instructions for Test Account**:
- Create a free Strava account at https://www.strava.com/register
- Join club 212760 via: https://www.strava.com/clubs/212760
- Upload at least 3 sample cycling activities (can use GPX files or manual entry)
- Ensure activities are set to "Everyone" visibility in Strava privacy settings

---

## STEP-BY-STEP REVIEW INSTRUCTIONS

Please follow these steps to evaluate all app features:

### 1. Initial Launch and Authentication
1. Launch **DCC Weekly Activities** on your test device
2. Observe the welcome screen with "Connect with Strava" button
3. Tap **"Connect with Strava"**
4. You will be redirected to Strava's OAuth login page (this is expected—we use Strava's official OAuth 2.0 flow)
5. Log in using the test credentials provided above
6. Tap **"Authorize"** to grant the app access to:
   - Read your basic profile (name, location)
   - Read club activity data (distances, times, speeds)
   - **Note**: These are read-only permissions; the app cannot post or modify any Strava data

### 2. Biometric Authentication Setup
1. After successful Strava login, you'll see a biometric authentication prompt (Face ID or Touch ID)
2. Tap **"Authenticate with Face ID"** (or Touch ID, depending on device)
3. Complete the biometric authentication
4. **Note**: This is optional for testing—you can tap "Log Out" and skip biometric if needed

### 3. Main Dashboard - Weekly Summary
1. You should now see the main dashboard with 4 summary cards at the top:
   - **Total Distance** (kilometers)
   - **Total Rides** (number of activities)
   - **Total Elevation** (meters climbed)
   - **Active Members** (number of unique riders)
2. Below, you'll see a date range header (e.g., "Mon 17 Feb – Sun 23 Feb 2026")
3. The main chart shows a **bar graph** of top performers by distance
4. A **pie chart** shows distance distribution among top riders
5. **Expected behavior**: Data reflects the test account's club activity from the past week

### 4. Metric Mode Selection (New Feature)
1. Tap any of the 4 summary cards at the top (Distance, Rides, Elevation, or Active Members)
2. A **mode selection sheet** slides up showing 3 options:
   - **Just My Stats**
   - **Me vs Top 3 Riders**
   - **Worst Performer & Why**
3. This is the primary navigation mechanism for detailed analysis views

### 5. Just My Stats View
1. From the mode selection sheet, tap **"Just My Stats"**
2. You should see:
   - The test account's personal statistics (distance, rides, elevation, speed)
   - Comparison to club average with visual indicators
   - Comparison to top 3 average
   - List of the test account's activities for the week
3. Tap any activity in the list to see **Activity Detail Screen** (see step 9)
4. Tap **back** to return to the dashboard

### 6. Me vs Top 3 Riders View
1. Tap any summary card again, then select **"Me vs Top 3 Riders"**
2. You should see:
   - Your ranking card (e.g., "#4 of 12")
   - Trophy/medal icon if you're in top 3
   - Grouped bar charts comparing you vs the top 3 distance leaders across:
     - Total Distance
     - Number of Rides
     - Total Elevation
     - Average Speed
     - Total Moving Time
   - Plain-English insights explaining the comparison (e.g., "You rode 12.5 km less than the top rider but 3.2 km more than the top 3 average")
3. Tap any rider name at the bottom to see their **Member Detail Screen** (see step 8)
4. Tap **back** to return to the dashboard

### 7. Worst Performer & Why View
1. Tap any summary card, then select **"Worst Performer & Why"**
2. You should see:
   - The member with the lowest performance score this week
   - A weighted scoring breakdown showing exactly why (distance, elevation, rides, etc.)
   - Respectful, data-driven explanations (e.g., "Only rode 2 times this week")
   - Suggested areas for improvement
3. **Note**: This feature uses a weighted scoring model (distance 35%, rides 20%, elevation 20%, time 10%, speed 10%, suffer score 5%)
4. Tap **back** to return to the dashboard

### 8. Member Detail Screen
1. From the main dashboard, tap any **bar in the chart**
2. You should see a detailed view of that member's performance:
   - Profile header with ranking
   - Stats grid (distance, speed, elevation, activities)
   - Recent activities list
3. Tap any activity to drill into **Activity Detail Screen**
4. Tap **back** to return to the previous screen

### 9. Activity Detail Screen
1. Tap any individual activity from any list
2. You should see:
   - Activity name and date
   - Detailed metrics: distance, elevation, speed, duration
   - If available: power (watts), heart rate, suffer score
   - **Note**: Power, heart rate, and suffer score only appear if the Strava activity includes this data
3. Performance trend chart (if the member has multiple recent activities)
4. Comparison to other activities by the same member
5. Tap **back** to return to the previous screen

### 10. Data Refresh
1. From the main dashboard, pull down to trigger **refresh**
2. The app will re-fetch the latest club activity data from Strava
3. Charts and stats should update to reflect any new activities
4. **Note**: Refresh is rate-limited to once per 15 minutes to respect Strava's API limits

### 11. Logout and Re-authentication
1. Tap the **logout** button (if visible in settings/menu)
2. You should return to the welcome screen
3. Tap **"Connect with Strava"** again
4. You should be able to re-authenticate without issues

---

## STRAVA API USAGE EXPLANATION

### Why OAuth 2.0 Login is Required
This app uses the Strava API to read publicly available club activity data. Strava requires OAuth 2.0 authentication for all API access—this is why users are redirected to Strava's login page during initial setup.

### API Endpoints Used
The app makes requests to only 2 Strava API endpoints:

1. **GET /api/v3/athlete**  
   - Purpose: Fetch the authenticated user's profile (name, location)  
   - Frequency: Once per app launch  
   - Scope required: `read`

2. **GET /api/v3/clubs/212760/activities**  
   - Purpose: Fetch publicly available activity data from the club feed  
   - Frequency: On app launch and manual refresh (max once per 15 minutes)  
   - Scope required: `activity:read`  
   - Parameters: `?per_page=200&after=[unix_timestamp]`

### Read-Only Access
The app **never** uses any Strava API endpoints that write, modify, or delete data. The OAuth scopes requested (`read` and `activity:read`) are read-only permissions only.

### Club ID Explanation
- **Club ID 212760** = "DCC - Desi Cycling Club"
- Publicly visible at: https://www.strava.com/clubs/212760
- The app is designed specifically for members of this club

---

## DATA USAGE EXPLANATION

### No Data Transmission to Our Servers
- The app does **not** operate any backend servers that store user data
- All data processing happens **on-device only**
- Activity data is stored **in-memory (RAM) only** and cleared when the app closes

### Cloudflare Worker (Token Exchange Only)
- URL: `https://dcc-strava.amit-r-kamat.workers.dev`
- Purpose: Securely exchange OAuth authorization codes for access tokens
- Why needed: Keeps Strava client secret out of the app binary (standard OAuth security practice)
- What it does:
  1. Receives authorization code from the app
  2. Exchanges code with Strava for access token (server-side)
  3. Returns token to the app
  4. **Does not log, store, or transmit any user data**
- This is a **stateless proxy** that retains no information after the exchange

### Keychain Storage
- OAuth access token and refresh token are stored in iOS Keychain
- Encrypted with AES-256, protected by device biometric or passcode
- Keychain data is **device-local only**—never synced to iCloud
- Deleted automatically when user logs out or deletes the app

### No Third-Party SDKs
The app contains:
- ✅ Native Apple frameworks only (SwiftUI, Charts, LocalAuthentication)
- ❌ No analytics SDKs (Google Analytics, Firebase, etc.)
- ❌ No crash reporting SDKs (Crashlytics, Sentry, etc.)
- ❌ No advertising SDKs (AdMob, Facebook, etc.)
- ❌ No third-party data collection of any kind

---

## KNOWN LIMITATIONS FOR REVIEW

### Empty State Handling
- If the test account's club has **no activities in the last 7 days**, the app will automatically extend the date range to **2 weeks** to avoid showing an empty screen
- This is expected behavior, not a bug
- If the extended 2-week range also returns no data, the app displays: "No rides recorded in the last 2 weeks"

### Activity Date Display
- Individual activity dates may show as `0001-01-01` (distant past) in console logs
- **This is expected**: Strava's `/clubs/{id}/activities` endpoint deliberately omits `start_date` and `start_date_local` fields for privacy/performance reasons
- Date filtering happens **server-side** via the `after=` parameter (Unix timestamp)
- The app does **not** filter dates client-side because no date fields are available
- This does **not** affect functionality—all activity data displays correctly

### Optional Activity Data
- **Power (watts)**, **heart rate**, and **suffer score** data only appear if the Strava activity includes this information
- Many cyclists do not track power or heart rate, so these fields may be absent
- The app gracefully handles missing data by showing "N/A" or omitting the field

### Strava API Rate Limits
- Strava limits: 100 requests per 15 minutes, 1,000 requests per day
- The app respects these limits by:
  - Caching data in-memory during the session
  - Throttling refresh requests (max once per 15 minutes)
  - Only fetching data on app launch and manual refresh

---

## ENTITLEMENTS EXPLANATION

This app uses the following iOS entitlements:

### 1. Keychain Access
- **Entitlement**: `keychain-access-groups`
- **Purpose**: Store OAuth access token and refresh token securely
- **Security level**: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` (most restrictive)
- **Why needed**: Persistent Strava authentication across app launches without requiring re-login every time

### 2. Network (Outbound Connections)
- **Purpose**: Make HTTPS API requests to:
  - `https://www.strava.com/api/v3/*` (Strava API)
  - `https://dcc-strava.amit-r-kamat.workers.dev/*` (OAuth token exchange)
- **Protocol**: HTTPS only (TLS 1.2+)
- **No inbound connections**: The app does not accept incoming network traffic

### 3. Associated Domains (OAuth Redirect)
- **Domain**: `dcc-activities://localhost/oauth/strava`
- **Purpose**: Handle OAuth redirect from Strava after authentication
- **Why needed**: iOS requires a custom URL scheme to receive the authorization code from Strava's OAuth flow
- **Security**: This is a **standard OAuth mobile practice**—the redirect URI is validated against Strava's developer dashboard settings

---

## ACCESSIBILITY AND COMPATIBILITY

### Device Compatibility
- **Minimum**: iOS 17.0
- **Tested on**: iPhone 14, iPhone 15, iPhone 16 Pro Max, iPad Pro
- **Orientations**: Portrait and landscape (iPad), portrait only (iPhone)

### Accessibility Features
- ✅ **VoiceOver**: All interactive elements have accessibility labels
- ✅ **Dynamic Type**: Text scales with system font size preferences
- ✅ **Color Contrast**: Passes WCAG AA standards
- ✅ **Reduce Motion**: Respects system reduce motion setting
- ✅ **Dark Mode**: Fully supported (if iOS Dark Mode is enabled)

### Biometric Authentication
- **Face ID**: Supported on iPhone X and later
- **Touch ID**: Supported on iPhone 8 and earlier, iPad Pro
- **Fallback**: Passcode authentication if biometrics unavailable
- **Optional**: Users can tap "Log Out" to skip biometric setup during initial login

---

## PRIVACY NUTRITION LABELS (App Store Connect)

When completing the Privacy Nutrition Labels in App Store Connect, select:

### Data Linked to the User
**None** — This app does not link any data to the user's identity

### Data Not Linked to the User
**None** — This app does not collect any data

### Data Used to Track You
**None** — This app does not track users

### Explanation
All data displayed in the app is:
- Fetched directly from Strava's API
- Processed in-memory only
- Never transmitted to any server we operate
- Already publicly visible on Strava's platform to club members

OAuth tokens are stored in Keychain but are not considered "collected data" under Apple's guidelines because they are authentication credentials handled by Strava's OAuth flow, not data collected by the app itself.

---

## ADDITIONAL REVIEW NOTES

### Strava Branding Compliance
This app complies with Strava's Brand Guidelines:
- "Powered by Strava" logo displayed on login screen (if required by Strava)
- Orange "Connect with Strava" button follows Strava's design specifications
- App does not misrepresent affiliation with Strava
- App clearly states it is a third-party club dashboard, not an official Strava product

### Club-Specific Design
- This app is designed for a specific club (ID 212760)
- The club ID is hardcoded because the app serves a single club's members
- Future versions may support multiple clubs, but v1.0 is single-club only

### No In-App Purchases
- The app is completely free with no in-app purchases
- No subscription model
- No ads or monetization of any kind

### Cloudflare Worker Source Code
If you require verification of the Cloudflare Worker's functionality (token exchange only, no data logging), the source code can be provided upon request.

---

## CONTACT FOR REVIEW QUESTIONS

If you have any questions during the review process, please contact:

**Developer Email**: support@desicyclingclub.com  
**Response Time**: Within 24-48 hours

⚠️ **ACTION REQUIRED**: Replace with actual developer support email before submission

---

## TESTING CHECKLIST FOR REVIEWER

Please verify the following during review:

- [ ] App launches without crashing on iOS 17.0+
- [ ] Strava OAuth login flow completes successfully
- [ ] Biometric authentication prompts correctly (Face ID/Touch ID)
- [ ] Dashboard displays club activity data (if test account has data)
- [ ] All 3 mode selection views navigate correctly (Just My Stats, Me vs Top 3, Worst Performer)
- [ ] Member detail screen shows individual rider statistics
- [ ] Activity detail screen shows individual ride metrics
- [ ] Pull-to-refresh updates data correctly
- [ ] Logout returns to welcome screen
- [ ] Re-login works without issues
- [ ] No crashes or hangs during normal usage
- [ ] No unexpected permissions requested (location, camera, etc.)
- [ ] Privacy Policy URL is accessible and complete
- [ ] Support URL is accessible (if provided)

---

**Document Version**: 1.0  
**Submission Date**: [To be filled by developer]  
**Build Number**: 1  
**Version Number**: 1.0.0  
**Status**: Ready for submission (pending test account credentials)

⚠️ **CRITICAL**: Provide actual test account email and password before submitting to App Review

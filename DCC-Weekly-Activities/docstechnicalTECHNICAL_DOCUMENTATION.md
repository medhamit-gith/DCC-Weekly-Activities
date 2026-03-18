# Technical Documentation
**DCC Weekly Activities - Developer Handover**

**Version**: 1.0.0  
**Last Updated**: February 24, 2026  
**Audience**: Developers (not for Apple review)

---

## PROJECT OVERVIEW

**App Name**: DCC Weekly Activities  
**Bundle ID**: com.desicyclingclub.weeklyactivities (inferred from Keychain service name)  
**Deployment Target**: iOS 17.0+  
**Swift Version**: Swift 6.0+  
**Xcode Version**: Xcode 15.0+ required  
**Platforms**: iOS, iPadOS (iPhone and iPad)  
**Architecture**: MVVM with Swift Concurrency (@Observable, async/await)

---

## ARCHITECTURE

### Pattern: MVVM + Swift Concurrency

**View Layer** (SwiftUI):
- `RootView` - Auth state router
- `WeeklyDashboardView` - Main container
- `MemberStatsChartView` - Charts visualization
- `JustMyStatsView` - Personal stats mode
- `MeVsTop3View` - Comparison mode
- `WorstPerformerView` - Analysis mode
- `MemberDetailView` - Individual member details
- `MetricModeSelectionView` - Mode selection sheet

**ViewModel Layer** (@Observable/@ObservableObject):
- `StravaAPI` (@MainActor @Observable) - All Strava interactions
- `BiometricAuth` (@MainActor ObservableObject) - Face ID/Touch ID

**Model Layer** (Codable structs):
- `Activity` - Core activity model
- `MemberStats` - Aggregated statistics
- `AthleteProfile` - User profile
- `StravaActivityResponse` - API response decoder

**Utilities**:
- `DateRangeProvider` - ISO week calculations (UTC timezone)
- `GlassComponents` - Reusable UI components
- `DashboardMode` - Mode enumeration

---

## THIRD-PARTY DEPENDENCIES

**NONE**

This is a pure SwiftUI app with no external dependencies beyond:
- Apple frameworks (SwiftUI, Charts, LocalAuthentication, AuthenticationServices)
- Strava API (via URLSession)
- Cloudflare Worker (OAuth token exchange proxy)

**Licenses**: All code uses Apple frameworks under Apple Developer Program Agreement.

---

## STRAVA INTEGRATION

### OAuth 2.0 Flow

1. **User taps "Connect with Strava"**
   - `StravaAPI.beginOAuth()` called
   - Constructs auth URL with client ID + redirect URI + scopes
   - Launches `ASWebAuthenticationSession`

2. **User logs into Strava** (in Safari or Strava app)
   - Strava presents consent screen
   - User grants permissions

3. **Strava redirects back to app**
   - Redirect URI: `dcc-activities://localhost/oauth/strava?code=xxx`
   - iOS routes to `.onOpenURL` handler in `RootView`
   - Calls `StravaAPI.handleRedirect(url:)`

4. **Exchange code for tokens**
   - Sends authorization code to Cloudflare Worker
   - Worker exchanges code + client secret for tokens (server-side)
   - Returns access_token + refresh_token + expires_at

5. **Store tokens securely**
   - `BiometricAuth.saveStravaToken()` stores in iOS Keychain
   - Keychain service: `com.desicyclingclub.weeklyactivities`
   - Accessibility: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`

6. **Use tokens for API calls**
   - `Authorization: Bearer {access_token}` header
   - Auto-refresh when expired via `ensureFreshToken()`

### OAuth Scopes

- `read` - View athlete profile (name, location)
- `activity:read` - View club activity data (distances, times, speeds)

**Both are read-only**. No write permissions requested.

### API Endpoints

1. **GET /api/v3/athlete**
   - Fetches authenticated user's profile
   - Used once per app launch
   - Returns: id, firstname, lastname, profile, city, state, country

2. **GET /api/v3/clubs/212760/activities**
   - Fetches club activity feed
   - Parameters: `?per_page=200&after={unix_timestamp}`
   - Returns: Array of activities (NO date fields - see Constraints below)

### Known Strava API Constraints

1. **Club activities endpoint does NOT return date fields**
   - No `start_date` or `start_date_local` in response
   - Activities decode with `Date.distantPast` as fallback
   - **Solution**: Server-side filtering via `after=` parameter only
   - **Critical**: Do NOT add client-side date filter (will reject all activities)

2. **Cannot use `before` and `after` parameters together**
   - Strava returns: `{"message":"Bad Request","errors":[{"field":"before after","code":"both provided"}]}`
   - **Solution**: Use `after=` only, rely on server-side filtering

3. **`per_page` maximum is 200**
   - Cannot fetch more than 200 activities in a single request
   - For most clubs, this is sufficient for 1-2 weeks of data

### Token Storage (Keychain)

```swift
Keychain.serviceName = "com.desicyclingclub.weeklyactivities"
Keychain.accessTokenKey = "strava_access_token"
Keychain.refreshTokenKey = "strava_refresh_token"
```

Security level: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` (no iCloud sync)

### Token Refresh

- Tokens expire after ~6 hours (Strava default)
- `ensureFreshToken()` checks `tokenExpiresAt` with 5-minute buffer
- If stale, calls `refreshAccessToken()` via Cloudflare Worker
- Automatic - user never sees re-login prompt unless refresh fails

---

## NAVIGATION STRUCTURE

```
App Launch
  │
  ├─ [No Token] → LoginView (GlassWelcomeCard)
  │                 └─ OAuth → BiometricGateView → WeeklyDashboardView
  │
  └─ [Has Token] → BiometricGateView → WeeklyDashboardView

WeeklyDashboardView (Main Container)
  │
  ├─ Summary Cards (4 tappable metric cards)
  │   └─ Tap → MetricModeSelectionView (Sheet)
  │             ├─ Just My Stats → JustMyStatsView
  │             ├─ Me vs Top 3 → MeVsTop3View
  │             └─ Worst Performer → WorstPerformerView
  │
  ├─ MemberStatsChartView (Charts + Stats)
  │   ├─ Tap Chart Bar → MemberDetailView
  │   │                    └─ Tap Activity → ActivityDetailView
  │   └─ Tap Rider Name → MemberDetailView
  │
  └─ Charts (Bar + Pie)
```

**New in v1.0**:
- `MetricModeSelectionView` - Modal sheet with 3 analysis modes
- `JustMyStatsView` - Personal stats with club comparisons
- `MeVsTop3View` - Comparison charts vs top 3 distance leaders
- `WorstPerformerView` - Weighted scoring analysis

---

## DATE RANGE LOGIC

### "Last Week" Definition

**ISO Week**: Monday 00:00:00 to Sunday 23:59:59 (**UTC timezone**)

**Logic** (`DateRangeProvider.getLastCompletedWeek()`):
- If today is Monday → return LAST week (7 days ago)
- If today is Tue-Sun → return LAST week (most recently completed)
- Always a complete Mon-Sun week, never partial

**Critical**: Uses `Calendar(identifier: .iso8601)` with `timeZone = UTC`
- **Why UTC**: Strava API dates are in UTC
- Matching timezones ensures date boundaries align with Strava's data

### 2-Week Fallback

**Trigger**: If `activities.count == 0` after API call
**Action**: Automatically fetch 2 weeks (Mon 2 weeks ago to Sun last week)
**Implementation**: `fetchLastWeeksClubActivities(isExtendedFetch: true)`
**UI Indicator**: `StravaAPI.isShowingExtendedRange = true`

**Critical**: Checks **raw API count**, NOT filtered count
- Because club endpoint returns no dates, there's no filter to apply
- `activities.count` reflects actual Strava response size

### Why No Client-Side Date Filter

Strava's `/clubs/{id}/activities` endpoint does NOT return:
- `start_date` field
- `start_date_local` field

All activities decode with `Date.distantPast` as fallback. Server-side filtering (via `after=` parameter) is the ONLY way to filter by date.

**DO NOT re-add a client-side date filter** - it will reject all activities.

---

## WORST PERFORMER SCORING MODEL

### Weighted Formula

```swift
totalScore = 
    (distance_normalized * 0.35) +
    (rides_normalized * 0.20) +
    (elevation_normalized * 0.20) +
    (moving_time_normalized * 0.10) +
    (speed_normalized * 0.10) +
    (suffer_score_normalized * 0.05)
```

### Normalization

Each parameter normalized to 0-100 scale:
```swift
normalized_value = (value - min) / (max - min) * 100
```

### Nil Handling

- If parameter is `nil` or `0`, treat as `0` (minimum value)
- Normalization prevents divide-by-zero: if `max == min`, normalized = 0

### Adjusting Weights

Edit `WorstPerformerView.swift` (search for `weights`):
```swift
let weights = (
    distance: 0.35,
    rides: 0.20,
    elevation: 0.20,
    movingTime: 0.10,
    speed: 0.10,
    sufferScore: 0.05
)
```

**Must sum to 1.0** for accurate scoring.

---

## KNOWN ISSUES & CONSTRAINTS

### Strava API Quirks

1. **No date fields in club activities response** (see Date Range Logic above)
2. **No activity IDs** in club response (for privacy)
3. **No maps/routes** in club response
4. **Power/HR/suffer score** optional (only if athlete tracks it)

### App Limitations

1. **Single club only** - Club ID 212760 hardcoded
2. **iOS 17+ only** - Uses Swift Charts, `@Observable` macro, SF Symbols 5
3. **No offline mode** - Requires network to fetch Strava data
4. **Rate limiting** - Strava: 100 req/15min, 1000 req/day
5. **No historical data** - Only shows last 1-2 weeks

### Future Enhancements

- Multi-club support (select from clubs user is a member of)
- Custom date range picker
- Export stats to CSV/PDF
- Push notifications for new club records
- Widget for Lock Screen/Home Screen

---

## VERSION HISTORY

See `CHANGELOG.md` for full details.

**v0.1-data-loading** (Feb 24, 2026):
- Fixed: Removed broken date filter (club endpoint has no dates)
- Fixed: 2-week fallback now checks raw API count

**v0.1-data-and-icons** (Feb 24, 2026):
- Added: Smart 2-week fallback
- Added: Cycling-specific SF Symbols
- Fixed: Date range display with UTC timezone

**v0.0-hotfix** (Feb 24, 2026):
- Fixed: Removed "before" param (Strava API constraint)
- Fixed: Post-login crash (@MainActor isolation)

---

## RUNNING THE PROJECT

### Prerequisites

1. **Xcode 15.0+** with iOS 17.0+ SDK
2. **Apple Developer Account** (for device testing)
3. **Strava API Credentials**:
   - Client ID: `161984`
   - Club ID: `212760`
   - Cloudflare Worker URL: `https://dcc-strava.amit-r-kamat.workers.dev`
4. **Test Strava Account** (member of club 212760 with recent activities)

### Setup Steps

1. **Clone repository**
   ```bash
   git clone [repo URL]
   cd DCC-Weekly-Activities
   ```

2. **Open in Xcode**
   ```bash
   open DCC-Weekly-Activities.xcodeproj
   ```

3. **Configure Bundle ID**
   - Select project in navigator
   - Under "Signing & Capabilities", set Team
   - Ensure Bundle ID matches: `com.desicyclingclub.weeklyactivities`

4. **Configure OAuth Redirect**
   - In Xcode, select target → Info → URL Types
   - Ensure URL Scheme: `dcc-activities`
   - Matches redirect URI: `dcc-activities://localhost/oauth/strava`

5. **Build & Run**
   - Select iOS Simulator or connected device
   - Build (Cmd+B)
   - Run (Cmd+R)

### Simulator vs Device

**Simulator**:
- ✅ Works for most features
- ✅ OAuth login functional
- ❌ Biometric auth not available (auto-skips to dashboard)
- ❌ Keychain not fully sandboxed (tokens persist across builds)

**Device**:
- ✅ Full biometric auth (Face ID/Touch ID)
- ✅ Proper Keychain isolation
- ✅ Real-world performance testing
- ⚠️ Requires Apple Developer provisioning profile

### Environment Variables / Config

**No .env files required**. All config in `StravaConfig` struct (StravaAPI.swift):

```swift
static let clientID = "161984"
static let clubID = "212760"
static let workerURL = "https://dcc-strava.amit-r-kamat.workers.dev"
static let redirectURI = "dcc-activities://localhost/oauth/strava"
```

**Cloudflare Worker** (token exchange):
- Source code: [Developer should have this separately]
- Deployment: Cloudflare Workers dashboard
- No secrets in app binary - client secret lives in Worker environment variables

---

## TESTING

### Test Account Setup

1. Create free Strava account: https://www.strava.com/register
2. Join club 212760: https://www.strava.com/clubs/212760
3. Upload 3-5 sample activities (manual entry or GPX files)
4. Ensure activities are set to "Everyone" visibility

### Testing Checklist

- [ ] OAuth login completes successfully
- [ ] Biometric prompt appears (device only)
- [ ] Dashboard loads with club data
- [ ] All 3 metric mode views navigate correctly
- [ ] Member detail screen displays
- [ ] Activity detail screen displays
- [ ] Pull-to-refresh updates data
- [ ] Logout returns to login screen
- [ ] Empty state displays if no data (test with date range that has no activities)
- [ ] 2-week fallback triggers if current week empty

---

## DEPLOYMENT

### Release Build

1. **Set scheme to Release**
   - Product → Scheme → Edit Scheme → Run → Build Configuration → Release

2. **Archive**
   - Product → Archive
   - Wait for build to complete

3. **Distribute to App Store**
   - Xcode Organizer → Archives
   - Select archive → Distribute App
   - App Store Connect → Upload

4. **App Store Connect**
   - Login to appstoreconnect.apple.com
   - Select app → Prepare for Submission
   - Fill in metadata (see APP_STORE_DESCRIPTION.md)
   - Add screenshots
   - Add reviewer notes (see APPLE_REVIEW_NOTES.md)
   - Submit for Review

### Pre-Submission Checklist

See `APP_STORE_CONNECT_CHECKLIST.md` for complete checklist.

**Critical items**:
- [ ] Privacy Policy URL live and accessible
- [ ] Support URL live and accessible
- [ ] Test account credentials in reviewer notes
- [ ] All placeholder emails replaced
- [ ] Bundle ID matches everywhere (Xcode, Strava OAuth, App Store Connect)

---

## TROUBLESHOOTING

### "No activities found" (Empty State)

**Cause**: Club 212760 has no activities in the date range  
**Solution**: Check Strava club feed, ensure test account has recent activities, verify "after=" timestamp is correct

### "OAuth redirect not working"

**Cause**: URL scheme mismatch  
**Solution**: Verify Info.plist URL Scheme = `dcc-activities`, matches StravaConfig.redirectURI

### "Token expired" error

**Cause**: Access token expired, refresh failed  
**Solution**: Check Cloudflare Worker is responding, verify refresh token is valid, log out and re-login

### "All activities filtered to 0"

**Cause**: Someone re-added a client-side date filter  
**Solution**: Remove the filter - club endpoint has no dates! See Date Range Logic section.

---

## MAINTENANCE

### Updating Strava Scopes

If you need additional permissions in the future:

1. Update scope string in `StravaAPI.beginOAuth()`:
   ```swift
   URLQueryItem(name: "scope", value: "read,activity:read,activity:write")
   ```

2. Update Privacy Policy to document new permissions

3. Force users to re-authorize (delete old tokens)

### Updating Cloudflare Worker

If token exchange logic changes:

1. Update Worker source code
2. Deploy to Cloudflare: `wrangler publish`
3. Test in staging environment first
4. No app update required (Worker URL stays the same)

---

**Document Version**: 1.0  
**Maintainer**: [Developer Name - PLACEHOLDER]  
**Last Reviewed**: February 24, 2026  
**Next Review**: Before v1.1 release

---


# Privacy Policy
**DCC Weekly Activities — Apple TV**

**Effective Date**: March 11, 2026  
**Last Updated**: March 11, 2026  
**Platform**: tvOS (Apple TV)

---

## Short Version

This app reads publicly available cycling activity data from your Strava club feed and displays it on your Apple TV. Your Strava access token is stored only on your Apple TV device using tvOS AppStorage. We collect no personal data beyond what Strava returns. We operate no servers that store user information.

---

## 1. Information We Collect

### 1.1 Strava Access Token

To fetch club activity data from Strava, you paste a Strava access token into the app (generated on your iPhone using the companion iOS app).

**What is stored**: The access token, refresh token, and expiry timestamp  
**Where it is stored**: tvOS `AppStorage` (on-device persistent storage for the Apple TV) — **not** in iCloud, **not** transmitted to any server we operate  
**How it is used**: Authenticate HTTP requests to the Strava API  
**Who can access it**: Only you, on your Apple TV  
**How long we keep it**: Until you tap "Reconnect" / clear the token, or delete the app

### 1.2 Club Activity Data (Strava API)

When authenticated, the app fetches publicly available activity data from your Strava club's activity feed:

- Athlete first name and last name
- Activity distance (kilometres)
- Moving time (seconds)
- Total elevation gain (metres)
- Average speed (km/h)

**Where it is stored**: In memory (RAM) only — never written to disk  
**How it is used**: Calculate and display performance statistics, leaderboards, and charts  
**How long we keep it**: Only while the app is running; cleared when the app closes

### 1.3 What We Do NOT Collect

We do not collect, store, or transmit:

- Your Strava password (we use OAuth access tokens only)
- Your email address, phone number, or Apple ID
- GPS coordinates or route maps
- Heart rate, power, or any health data
- Device identifiers for tracking or advertising
- Crash reports or analytics telemetry
- Any data from children under 13

---

## 2. How the Token Reaches Apple TV

The tvOS app does not support the full Strava OAuth web flow. Instead:

1. You authenticate on your iPhone using the DCC Weekly Activities iOS app
2. The iOS app provides a "Copy Token for Apple TV" button that copies a JSON token bundle to your clipboard
3. You paste this bundle into the Apple TV app's token entry screen
4. The token is stored locally in tvOS `AppStorage`

**No iCloud syncing occurs** in the current version. The token bundle never passes through any server we operate. The clipboard is used transiently on your iPhone; Apple TV receives the token directly via the on-screen keyboard or paste.

---

## 3. Third-Party Services

### 3.1 Strava API

This app uses the Strava API (`https://www.strava.com/api/v3`) to retrieve club activity data.

**Strava Privacy Policy**: https://www.strava.com/legal/privacy  
**Strava API Agreement**: https://developers.strava.com/docs/api-agreement/

All API requests are made directly from your Apple TV to Strava's servers over HTTPS. We do not proxy or store Strava API responses.

**OAuth Scopes Used**:
- `read` — Basic athlete profile (name only; used to attribute activities)
- `activity:read` — Club activity feed (distance, time, speed, elevation)

These are read-only scopes. The app cannot post activities, modify data, or access any private information.

### 3.2 Cloudflare Worker (Token Refresh Only)

When your access token expires, the app sends the refresh token to our Cloudflare Worker:

**Endpoint**: `https://dcc-strava.amit-r-kamat.workers.dev/refresh`

**What it does**:
- Receives your refresh token
- Exchanges it with Strava for a new access token (server-side, keeping the client secret out of the app binary)
- Returns the new access token and expiry to your device
- **Does not log, store, or transmit your data anywhere else**

This worker is stateless — it retains no data after completing the refresh. This is a standard OAuth 2.0 security pattern.

### 3.3 No Other Third-Party Services

We do not use:
- Google Analytics, Firebase, or any analytics platform
- Advertising networks or SDKs
- Crash reporting tools (Crashlytics, Sentry, etc.)
- A/B testing or feature flag services
- Social media SDKs

---

## 4. Data Storage on Apple TV

| Data | Storage Location | Persists After App Close? |
|------|-----------------|--------------------------|
| Access token | tvOS AppStorage | Yes — until cleared or app deleted |
| Refresh token | tvOS AppStorage | Yes — until cleared or app deleted |
| Token expiry | tvOS AppStorage | Yes — until cleared or app deleted |
| Club activity feed | In-memory (RAM) | No — cleared on app close |
| Rider stats & charts | In-memory (RAM) | No — cleared on app close |

**No iCloud**, **no Core Data**, **no SQLite**, **no network server storage**.

---

## 5. Data Sharing and Disclosure

### 5.1 We Do Not Sell Your Data
We do not sell, rent, or trade personal information to any third party for any purpose whatsoever.

### 5.2 We Do Not Share Your Data
We do not share personal information with third parties, except as required by applicable law (e.g., valid court order or government request).

### 5.3 Club Activity Data is Already Public
The activity data displayed in this app is **already publicly visible on Strava** to all members of your club. This app presents that existing public data in a focused dashboard format. To restrict the visibility of your own activities, update your privacy settings in the Strava app directly.

---

## 6. Your Rights and Choices

### 6.1 Remove the App's Strava Access
You can revoke this app's Strava access at any time:

1. Log in to **Strava.com**
2. Go to **Settings → My Apps**
3. Find "DCC Weekly Activities" and select **Revoke Access**

After revoking, the app will display the token entry screen on next launch.

### 6.2 Clear the Token on Apple TV
To remove your stored token from this Apple TV:

1. Open the app
2. Navigate to the **Leaderboard** tab
3. Select the **Reconnect** button (shown in the error or header area)
4. This clears all stored tokens from AppStorage

### 6.3 Delete All Data
Deleting the app from your Apple TV removes all AppStorage data including the access token and refresh token. To delete: **Settings → General → Manage Storage** on your Apple TV.

---

## 7. Children's Privacy

This app is **not directed at children under 13**. We do not knowingly collect personal information from children. Strava requires users to be at least 13 years old. If you believe a child under 13 is using this app, please contact us and we will take appropriate action.

---

## 8. Security

- All API calls to Strava use **HTTPS (TLS 1.2+)**
- The Strava client secret is **never included in the app binary** — token exchange is handled server-side
- Tokens are stored in tvOS AppStorage, which is sandboxed to this app and inaccessible to other apps

---

## 9. Data Retention

**Access / refresh tokens**: Retained in AppStorage until you clear them, delete the app, or reset the Apple TV  
**Activity data**: Held in memory only while the app is running — cleared on every app close

---

## 10. European Privacy (GDPR)

If you are a resident of the European Economic Area (EEA):

**Legal basis for processing**: Consent (you explicitly paste and submit your Strava token)  
**Data controller**: Desi Cycling Club  
**Your rights**: Access, rectification, erasure, restriction, portability, and objection — contact us at the address below

---

## 11. California Privacy (CCPA)

We do not sell personal information. California residents have the right to know what data we hold (see Section 1), request deletion (see Section 6.3), and will not be discriminated against for exercising these rights.

---

## 12. Changes to This Policy

We will update the "Last Updated" date above when this policy changes. Material changes will be communicated via an in-app notice on the companion iOS app.

---

## 13. Contact

**Developer**: Amit Kamat  
**Club**: Desi Cycling Club (DCC)  
**Support**: Submit an issue at the app's support URL listed on the App Store page  
**Privacy inquiries**: Use the App Store contact link for this app

---

**Document Version**: 1.0  
**Platform**: tvOS / Apple TV  
**Effective Date**: March 11, 2026

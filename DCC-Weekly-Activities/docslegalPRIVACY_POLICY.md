# Privacy Policy
**DCC Weekly Activities**

**Effective Date**: February 24, 2026  
**Last Updated**: February 24, 2026

---

## Introduction

DCC Weekly Activities ("we," "our," or "the app") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, store, and protect information when you use our iOS application.

**Short Version**: We don't collect, store, or sell your personal data. The app reads publicly available cycling activity data from your Strava club feed and displays it on your device only. All processing happens locally. We don't operate any servers that store your information.

---

## 1. Information We Collect

### 1.1 Strava Authentication Token
When you connect your Strava account, we receive an OAuth access token and refresh token from Strava. These tokens allow the app to make API requests on your behalf.

**How it's stored**: Encrypted in iOS Keychain on your device only  
**How it's used**: Authenticate API requests to Strava  
**Who has access**: Only you, on your device  
**How long we keep it**: Until you log out or delete the app

### 1.2 Strava Athlete Profile
When you connect, we retrieve your basic Strava profile information:
- First name
- Last name  
- Profile photo URL (if set)
- City, state, country (if set)

**How it's stored**: In-memory only (RAM), never written to disk  
**How it's used**: Display your name in the app greeting ("Hi, [Your Name]")  
**Who has access**: Only you, on your device  
**How long we keep it**: Until you close the app; re-fetched on next launch

### 1.3 Club Activity Data
The app fetches publicly available activity data from your Strava club's activity feed:
- Activity name
- Distance (kilometers)
- Elevation gain (meters)
- Moving time (seconds)
- Average speed (km/h)
- Average watts (if available)
- Average heart rate (if available)
- Suffer score (if available)
- Athlete first name and last name

**How it's stored**: In-memory only (RAM), never written to disk  
**How it's used**: Calculate and display performance statistics, charts, and leaderboards  
**Who has access**: Only you, on your device  
**How long we keep it**: Until you close the app; re-fetched on next launch

---

## 2. What We DO NOT Collect

We explicitly **do not** collect, store, or transmit:

❌ Your exact location or GPS coordinates  
❌ Your email address or phone number  
❌ Your Strava password (handled by Strava OAuth only)  
❌ Your browsing history or app usage patterns  
❌ Device identifiers for tracking or advertising  
❌ Crash reports or analytics data  
❌ Any data from children under 13

---

## 3. How We Use Your Information

### 3.1 Display Purposes Only
All data retrieved from Strava is used exclusively to:
- Display your weekly club activity statistics
- Generate performance charts and comparisons
- Show individual member and activity details
- Calculate club-wide aggregates (total distance, average speed, etc.)

### 3.2 Authentication
Your Strava access token is used solely to:
- Authenticate API requests to Strava's servers
- Refresh expired tokens to maintain your session
- Retrieve your athlete profile and club activity feed

### 3.3 No Secondary Use
We do not:
- Sell your data to third parties
- Share your data with advertisers
- Use your data for marketing purposes
- Analyze your data for behavioral profiling
- Transmit your data to any server we operate (we don't operate any servers)

---

## 4. How We Store Your Information

### 4.1 iOS Keychain (Encrypted Storage)
**What's stored**: Strava OAuth access token and refresh token  
**Security**: iOS Keychain uses AES-256 encryption and is protected by your device's biometric authentication (Face ID/Touch ID) or passcode  
**Accessibility**: Data is only accessible when your device is unlocked (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`)  
**Persistence**: Tokens remain in Keychain until you log out or delete the app

### 4.2 In-Memory Processing (RAM)
**What's stored**: Athlete profile and club activity data  
**Duration**: Only while the app is running  
**What happens when you close the app**: All in-memory data is immediately cleared by iOS

### 4.3 No Database, No Cloud
We do **not** use:
- SQLite or Core Data databases
- iCloud storage or sync
- Remote servers for data storage
- File system storage for personal data
- UserDefaults for sensitive information

---

## 5. Third-Party Services

### 5.1 Strava API
This app uses the Strava API to retrieve your club's publicly available activity data.

**Strava's Privacy Policy**: https://www.strava.com/legal/privacy  
**Strava's API Agreement**: https://developers.strava.com/docs/api-agreement/

When you connect your Strava account, you are subject to Strava's own privacy policy and terms of service. We receive only the data you explicitly authorize through Strava's OAuth consent screen.

**OAuth Scopes Requested**:
- `read` — View your basic Strava profile (name, location)
- `activity:read` — View your club's activity feed (distances, times, speeds)

These are **read-only** scopes. The app cannot post activities, modify existing data, or access private information beyond what your club already shares publicly.

### 5.2 Cloudflare Worker (Token Exchange Only)
To securely exchange OAuth authorization codes for access tokens without exposing our Strava client secret in the app binary, we use a Cloudflare Worker at:

**https://dcc-strava.amit-r-kamat.workers.dev**

**What it does**:
- Receives your OAuth authorization code
- Exchanges it with Strava for an access token (server-side only)
- Returns the access token to your device
- **Does not log, store, or transmit your data anywhere else**

This is a standard OAuth security practice. The worker operates as a stateless proxy and retains no information after completing the token exchange.

### 5.3 No Other Third-Party Services
We do **not** use:
- Google Analytics or similar analytics platforms
- Facebook SDK or social media trackers
- Advertising networks (AdMob, etc.)
- Crash reporting tools (Crashlytics, Sentry, etc.)
- A/B testing or feature flagging services
- Third-party authentication providers beyond Strava

---

## 6. Data Sharing and Disclosure

### 6.1 We Do Not Sell Your Data
We do not sell, rent, or trade your personal information to third parties for any purpose.

### 6.2 We Do Not Share Your Data
We do not share your personal information with third parties except as required by law (e.g., valid legal process, court order, or government request).

### 6.3 Club Activity Data Visibility
The activity data displayed in this app is **already publicly visible** on Strava's platform to all members of your club. This app simply presents that public data in a focused, club-centric dashboard format. If you want to restrict visibility of your activities, adjust your privacy settings in Strava directly.

---

## 7. Your Rights and Choices

### 7.1 Revoke Strava Access
You can revoke this app's access to your Strava account at any time:

1. Log in to Strava.com
2. Go to **Settings → My Apps**
3. Find "DCC Weekly Activities" and click **Revoke Access**

This immediately invalidates the app's access token. The next time you open the app, you'll need to reconnect.

### 7.2 Delete All Local Data
To delete all data stored by this app on your device:

1. Open the app and tap **Log Out** (if logged in)
2. Delete the app from your device
3. iOS automatically removes all Keychain data and in-memory data

Alternatively, you can log out without deleting the app—this clears the Keychain token but retains the app for future use.

### 7.3 Contact Us for Privacy Questions
If you have questions about how your data is handled, contact us at:

**Email**: privacy@desicyclingclub.com

⚠️ **ACTION REQUIRED**: Replace with actual privacy contact email before hosting

---

## 8. Children's Privacy

This app is **not directed at children under 13**. We do not knowingly collect personal information from children under 13. Strava's own Terms of Service require users to be at least 13 years old (or 16 in the EU).

If we discover that we have inadvertently collected information from a child under 13, we will delete that information immediately. If you believe a child under 13 has used this app, please contact us at the email above.

---

## 9. Data Retention

### 9.1 OAuth Tokens
**Retention period**: Until you log out or delete the app  
**Auto-expiration**: Access tokens expire after 6 hours (Strava default); refresh tokens are used to obtain new access tokens automatically

### 9.2 In-Memory Data (Activity Feed)
**Retention period**: Only while the app is actively running  
**What happens on app close**: All in-memory data is cleared by iOS immediately

### 9.3 No Long-Term Storage
We do not retain any personal data beyond the active app session. Each time you open the app, fresh data is fetched from Strava's API.

---

## 10. Security Measures

We implement industry-standard security practices:

### 10.1 Encryption
- **At Rest**: OAuth tokens stored in iOS Keychain are encrypted with AES-256
- **In Transit**: All API calls to Strava use HTTPS (TLS 1.2+)

### 10.2 Biometric Protection
If you enable Face ID or Touch ID, your Strava access token is protected by iOS biometric authentication. The app will prompt for authentication before displaying any data.

### 10.3 Token Security
- Strava client secret is **never included in the app binary**
- Token exchange happens server-side via Cloudflare Worker
- Tokens are stored with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` (most restrictive Keychain access level)

### 10.4 No Backdoors
We do not implement remote data access, remote wipe, or any mechanism to access your device's data remotely.

---

## 11. International Data Transfers

### 11.1 Strava API
Strava, Inc. is based in the United States. When you use this app, your data is transmitted to Strava's servers, which may be located outside your country. Strava is responsible for compliance with international data protection laws (including GDPR, CCPA, etc.). See Strava's privacy policy for details.

### 11.2 Cloudflare Worker
The token exchange worker operates on Cloudflare's global network. The worker does not store or log personal data—it simply forwards OAuth tokens between Strava and your device. Cloudflare's data processing practices are governed by their own privacy policy.

---

## 12. California Privacy Rights (CCPA)

If you are a California resident, you have specific rights under the California Consumer Privacy Act (CCPA):

### 12.1 Right to Know
You have the right to know what personal information we collect. See Section 1 above for a complete list.

### 12.2 Right to Delete
You have the right to request deletion of your personal information. To exercise this right, log out of the app and delete it from your device. This removes all local data. To delete data stored by Strava, contact Strava directly.

### 12.3 Right to Opt-Out of Sale
We do **not** sell personal information. No opt-out is necessary.

### 12.4 Non-Discrimination
We will not discriminate against you for exercising your CCPA rights.

---

## 13. European Privacy Rights (GDPR)

If you are a resident of the European Economic Area (EEA), you have specific rights under the General Data Protection Regulation (GDPR):

### 13.1 Legal Basis for Processing
We process your data based on:
- **Consent**: You explicitly authorize Strava access via OAuth
- **Legitimate Interest**: Displaying publicly available club activity data

### 13.2 Your GDPR Rights
- **Right to Access**: Request a copy of your data (contact us at the email above)
- **Right to Rectification**: Correct inaccurate data (update your Strava profile directly)
- **Right to Erasure**: Delete your data (log out and delete the app)
- **Right to Restrict Processing**: Revoke Strava access (see Section 7.1)
- **Right to Data Portability**: Export your data (contact us at the email above)
- **Right to Object**: Object to data processing (revoke Strava access)

### 13.3 Data Controller
For GDPR purposes:
- **Data Controller**: Desi Cycling Club (DCC Weekly Activities app)
- **Contact**: privacy@desicyclingclub.com

⚠️ **ACTION REQUIRED**: Replace with actual GDPR contact before hosting

---

## 14. Changes to This Privacy Policy

We may update this Privacy Policy from time to time to reflect changes in our practices or for legal, regulatory, or operational reasons.

### 14.1 Notification of Changes
If we make material changes, we will:
- Update the "Last Updated" date at the top of this policy
- Notify you via an in-app message on your next launch
- (For significant changes) Require you to re-consent via the OAuth flow

### 14.2 Review Regular Updates
We encourage you to review this Privacy Policy periodically. Continued use of the app after changes constitutes acceptance of the updated policy.

---

## 15. Contact Us

If you have questions, concerns, or requests regarding this Privacy Policy or our data practices, please contact us:

**Email**: privacy@desicyclingclub.com  
**Support**: https://www.desicyclingclub.com/support

⚠️ **ACTION REQUIRED**: Replace with actual contact details before hosting

We aim to respond to all privacy inquiries within 30 days.

---

## 16. Compliance and Certifications

### 16.1 Apple App Store Requirements
This Privacy Policy complies with Apple's App Store Review Guidelines, including:
- Transparency about data collection (Guideline 5.1.1)
- Privacy Nutrition Labels accuracy (Guideline 5.1.2)
- Disclosure of third-party code (Guideline 5.1.3)

### 16.2 Strava API Agreement
This app operates in full compliance with:
- Strava API Agreement: https://developers.strava.com/docs/api-agreement/
- Strava Brand Guidelines: https://developers.strava.com/guidelines/

We do not use Strava data in any manner prohibited by Strava's terms.

---

## 17. Dispute Resolution

Any disputes arising from this Privacy Policy or your use of the app shall be resolved in accordance with the laws of [Your Jurisdiction].

⚠️ **ACTION REQUIRED**: Specify jurisdiction (e.g., "State of California, United States") before hosting

---

## Summary

**In Plain English**:
- We read your club's publicly available Strava activity data and display it on your device.
- We don't store anything beyond your encrypted access token (in iOS Keychain).
- We don't sell, share, or transmit your data to any third party beyond Strava's own API.
- We don't track, analyze, or advertise to you.
- You can revoke access or delete everything at any time.

**Questions?** Contact us at privacy@desicyclingclub.com

---

**Document Version**: 1.0  
**Effective Date**: February 24, 2026  
**Status**: Ready for hosting (pending contact detail confirmation)

⚠️ **BEFORE HOSTING**: Replace all placeholder emails and URLs with actual contact information

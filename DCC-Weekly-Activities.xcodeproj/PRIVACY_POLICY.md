# Privacy Policy for DCC Weekly Activities

**Last Updated: September 29, 2026**

> **Changed in this version.** Strava withdrew its club activity feed on
> 1 September 2026. The club leaderboard is now built only from members who
> explicitly choose to share their rides, and for those members some data is
> stored on our server. Earlier versions of this policy stated that all data
> stayed on your device; that is no longer accurate for members who opt in.
> See *Information We Collect* and *Data Storage and Security*.

## Overview

DCC Weekly Activities is an iOS application designed for members of the Desi Cycling Club to track and view weekly cycling activities. This Privacy Policy explains how we collect, use, and protect your information.

## Developer Information

DCC Weekly Activities is developed independently to support the Desi Cycling Club community. This app is not affiliated with Strava, Inc., though it uses the Strava API to access club data.

**Contact Information:**
- Email: [YOUR_SUPPORT_EMAIL]
- App: DCC Weekly Activities
- Version: 1.0.0

## Information We Collect

### 1. Strava Account Information
When you authenticate with Strava, we access:
- Your Strava profile name
- Your Strava profile photo
- Your athlete ID
- Your membership in the Desi Cycling Club

### 2. Activity Data
Strava withdrew its club activity feed on 1 September 2026, so the app can no
longer read the club's rides from a single account. The leaderboard is now
built only from members who have chosen to share.

**If you choose to share your rides** (Club leaderboard → "Share my rides"),
we retrieve from Strava and store on our server:
- Your first name and last initial, and your Strava athlete ID
- Your cycling activities: distance, moving time, elevation gain, average speed
- Each activity's name, type and start time

Non-cycling activities, such as walks and runs, are ignored.

**If you do not share**, we retrieve no activity data about you, and nothing
about you is stored on our server.

Sharing is always an explicit choice. It never happens as part of signing in,
and you can stop at any time (see *Your Data Rights*).

### 3. Authentication Tokens
We store on your device:
- Strava OAuth access token
- Strava OAuth refresh token (when you have not opted in to sharing)
- Token expiration dates

**If you opt in to sharing**, your Strava refresh token is stored on our server
instead of your device. This is what allows the app to read your rides for the
leaderboard between sessions, and it grants ongoing read access to your Strava
activities until you stop sharing or revoke access at
https://www.strava.com/settings/apps. In its place your device stores a key
that identifies you to our server.

### 4. Biometric Data (Optional)
If you enable biometric authentication:
- Face ID or Touch ID is used locally on your device
- No biometric data is stored or transmitted
- Authentication is handled entirely by iOS

## How We Use Your Information

We use your information solely to:
- Authenticate you with Strava
- Display Desi Cycling Club activity data
- Show weekly leaderboards and statistics
- Provide activity summaries and insights
- Cache data for offline viewing

## Data Storage and Security

### Where Your Data Lives
We operate a small server (a Cloudflare Worker) that supports the app. It
always handles Strava sign-in, so that the app's Strava client secret is never
shipped inside the app. What else it holds depends on your choice:

- **If you have not opted in to sharing**, the server stores nothing about you.
  Your tokens and cached activity data stay on your device.
- **If you have opted in**, the server also stores your Strava refresh token,
  your name and athlete ID, and your cycling activity data as listed above.

### Who Can See Your Shared Data
If you opt in, your name and ride statistics are visible to anyone who can
reach the club leaderboard. Please treat anything you share as visible to the
whole club.

### Security Measures
- Tokens on your device are stored in the iOS Keychain (encrypted)
- All network communications use HTTPS
- Strava authentication follows OAuth 2.0 best practices
- Biometric authentication uses the iOS secure enclave
- The Strava client secret is held only on our server, never in the app

### Data Retention
- Activity data is cached locally on your device for 7 days
- On our server, shared activity data is retained for 120 days and then
  deleted automatically
- Your stored refresh token is kept until you stop sharing or delete the app's
  access in Strava
- If you stop sharing, your token and all of your stored activity data are
  deleted immediately

## Data Sharing and Third Parties

### We Do NOT:
- Sell your data to anyone
- Pass your data to third parties outside the app and its server
- Use your data for advertising
- Track your behavior outside the app
- Collect analytics or usage statistics

Note that if you choose to share your rides, they are shown to other members
on the club leaderboard. That is the purpose of sharing, and it is the one
case where your activity data is visible to other people through this app.

### Third-Party Services We Use:

#### Strava API
- We use Strava's API to retrieve club data
- Strava's Privacy Policy applies: https://www.strava.com/legal/privacy
- You can revoke app access anytime at: https://www.strava.com/settings/apps
- We only request read-only permissions for activities

### No Other Third Parties
- We do not use analytics services
- We do not use crash reporting services
- We do not use advertising networks
- We do not use tracking services

## Your Data Rights

You have the right to:

### Access Your Data
- All your data is visible within the app
- Activity data comes directly from Strava

### Delete Your Data
- Tap "Stop sharing" on the Club leaderboard screen. This immediately deletes
  your stored refresh token and every activity we hold for you on our server,
  and removes you from the leaderboard
- Log out to remove authentication tokens from your device
- Delete the app to remove all locally cached data
- Revoke the app's access at https://www.strava.com/settings/apps. This stops
  any further reading of your activities; use "Stop sharing" as well if you
  want the data already stored to be deleted

### Control Your Data
- Sharing your rides with the leaderboard is off until you turn it on, and you
  can turn it off again at any time
- Control which activities exist at all by adjusting your Strava privacy
  settings
- Disconnect the app from Strava at any time

## Children's Privacy

This app is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you believe we have inadvertently collected such information, please contact us immediately.

Strava requires users to be at least 13 years old (16 in some jurisdictions). Please refer to Strava's Terms of Service.

## Location Data

This app does NOT directly access your device location. Any location data displayed comes from activities you've already uploaded to Strava, subject to your Strava privacy settings.

## Permissions Required

### Required Permissions:
- **Internet Access**: To communicate with Strava API
- **Keychain Access**: To securely store authentication tokens

### Optional Permissions:
- **Face ID / Touch ID**: For biometric app locking (optional feature)

## International Data Transfers

Since all data is stored locally on your device, there are no international data transfers by this app. However, Strava operates globally. Please review Strava's Privacy Policy for information about their data practices.

## Changes to This Privacy Policy

We may update this Privacy Policy from time to time. Changes will be:
- Posted on this page with a new "Last Updated" date
- Highlighted in app updates when significant
- Effective immediately upon posting

We encourage you to review this policy periodically.

## Compliance

This app complies with:
- Apple App Store Guidelines
- General Data Protection Regulation (GDPR) - EU
- California Consumer Privacy Act (CCPA) - US
- UK Data Protection Act 2018
- Strava API Agreement

## Your Consent

By using DCC Weekly Activities, you consent to:
- This Privacy Policy
- Our use of Strava API to retrieve club data
- Local storage of authentication tokens and cached data

## Data Breach Notification

In the unlikely event of a data breach:
- We will notify affected users promptly
- We will describe the nature of the breach
- We will provide guidance on protective measures

Note: Since we do not operate servers or store data centrally, the risk of a data breach is minimal.

## California Privacy Rights (CCPA)

California residents have additional rights:
- Right to know what personal information is collected
- Right to delete personal information
- Right to opt-out of sale of personal information (we don't sell data)
- Right to non-discrimination for exercising privacy rights

## European Privacy Rights (GDPR)

EU/UK residents have rights including:
- Right of access to your personal data
- Right to rectification of inaccurate data
- Right to erasure ("right to be forgotten")
- Right to restrict processing
- Right to data portability
- Right to object to processing

To exercise these rights, delete the app or revoke Strava access.

## Contact Us

If you have questions, concerns, or requests regarding this Privacy Policy or your data:

**Email**: [YOUR_SUPPORT_EMAIL]
**Response Time**: We aim to respond within 48 hours

For issues related to your Strava account or data, contact Strava directly:
- Strava Support: https://support.strava.com/

## Strava API Compliance

This app:
- Uses Strava API in accordance with their API Agreement
- Displays Strava branding where required
- Respects Strava's rate limits and usage guidelines
- Does not misuse or redistribute Strava data

## Open Source

This app may use open-source components. Each component is governed by its respective license.

---

**Summary**: DCC Weekly Activities is a simple, privacy-focused app that only stores data locally on your device. We don't have servers, we don't collect analytics, and we don't share your data. You maintain full control through your Strava account settings.

**By using this app, you acknowledge that you have read and understood this Privacy Policy.**

---

*This privacy policy was created for DCC Weekly Activities and is effective as of February 13, 2026.*

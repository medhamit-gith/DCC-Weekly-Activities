# App Store Description
**DCC Weekly Activities - Version 1.0.0**

---

## APP NAME
**DCC Weekly Activities**

(Matches Xcode project target name exactly)

---

## SUBTITLE
*30 characters maximum*

**Track your cycling club stats**

(29 characters - fits within limit)

---

## PROMOTIONAL TEXT
*170 characters maximum - displayed at top of App Store listing, updatable without new version*

**See how you stack up against your clubmates! Compare your weekly rides, discover top performers, and track your progress with beautiful charts powered by Strava data.**

(169 characters - fits within limit)

---

## DESCRIPTION
*4000 characters maximum*

**Transform your cycling club's Strava data into actionable insights.** DCC Weekly Activities is designed for members of cycling clubs who want to track their performance, celebrate achievements, and stay motivated through friendly competition. See at a glance who rode the most, climbed the highest, and pushed the hardest—all in a beautifully designed, privacy-first iOS app.

**WHAT YOU CAN DO:**

• **Connect your Strava account securely** via official OAuth 2.0 authentication  
• **See your club's weekly ride summary** at a glance with total distance, rides, elevation, and active members  
• **Tap any stat to dive into detailed analysis** across three powerful views:  
  - **Just My Stats**: Your personal performance with club average comparisons  
  - **Me vs Top 3 Riders**: Head-to-head charts comparing you against the distance leaders  
  - **Worst Performer & Why**: Data-driven insights into who had a tough week (and how to improve)  
• **Explore individual performance** by tapping any rider's name to see their full stats and activity list  
• **Drill into activity details** including distance, elevation, speed, power (watts), heart rate, and suffer score  
• **Beautiful visualizations** powered by Swift Charts with bar graphs, pie charts, and trend indicators  
• **Face ID / Touch ID protection** to keep your stats private  
• **Automatic 2-week data fallback** ensures you never see an empty screen during slow weeks

**YOUR PRIVACY IS GUARANTEED:**

DCC Weekly Activities is built privacy-first from the ground up. The app **reads Strava data only**—it never posts, modifies, or deletes any of your Strava activities. All data processing happens **on your device**, in memory only. When you close the app, everything is cleared except your secure login token, which is stored in iOS Keychain with encryption.

**We do not operate any servers that store your data.** The only external connections are to Strava's official API (to fetch your club's public activity feed) and a Cloudflare Worker (to securely exchange OAuth tokens without exposing secrets in the app binary). No analytics. No tracking. No third-party SDKs. No advertising. Your ride data stays between you and Strava.

**STRAVA ACCOUNT REQUIRED:**

This app requires a free Strava account and membership in a Strava club. During first launch, you'll be redirected to Strava's login page to grant read-only permissions:

• **Read your basic profile** (name, location) - used to personalize your dashboard greeting  
• **Read club activity data** (distances, times, speeds) - used to calculate and display weekly performance stats

These are **read-only permissions**. The app cannot and will not post rides, modify your activities, or interact with Strava in any way beyond viewing publicly available club data. You can revoke access anytime via Strava's settings at strava.com/settings/apps.

**Join the DCC community and see your progress come to life.**

---

## KEYWORDS
*100 characters maximum - comma-separated, no duplicates from app name or subtitle*

**cycling,strava,club,rides,performance,leaderboard,training,elevation,speed,distance,watts,heart**

(99 characters - fits within limit)

---

## CATEGORY

**Primary**: Health & Fitness  
**Secondary**: Sports

---

## SUPPORT URL

⚠️ **PLACEHOLDER - DEVELOPER ACTION REQUIRED**

Suggested: `https://www.desicyclingclub.com/support`

**STATUS**: Must be live and accessible before App Store submission

---

## MARKETING URL

⚠️ **PLACEHOLDER - DEVELOPER ACTION REQUIRED** (Optional)

Suggested: `https://www.desicyclingclub.com`

**STATUS**: Optional - can be left blank for v1.0 submission

---

## PRIVACY POLICY URL

⚠️ **CRITICAL - DEVELOPER ACTION REQUIRED**

Suggested: `https://www.desicyclingclub.com/privacy`

**STATUS**: **MUST be live and accessible before submission** - Apple requires this for all apps

See `docs/legal/PRIVACY_POLICY.md` for the content that must be hosted at this URL.

---

## WHAT'S NEW
*Version 1.0.0 - Initial Submission*

**Leave blank for initial App Store submission** - this field is only used for app updates

For future updates (v1.1+), use this format:

```
Version 1.1.0

• New feature: [description]
• Improved: [description]
• Fixed: [description]
```

---

## AGE RATING

**4+** (No objectionable content)

- No violence
- No mature themes
- No social features that enable strangers to contact each other
- No user-generated content
- Displays publicly available Strava activity data only

---

## CONTENT RIGHTS

**Strava API Terms of Service**: This app complies with Strava's API Agreement and Brand Guidelines. All activity data displayed is:

1. Already publicly visible on Strava to club members
2. Accessed via official Strava API with user consent (OAuth 2.0)
3. Used only for display/analysis purposes (read-only)
4. Not modified, stored externally, or transmitted to third parties

**Copyright**: All app design, code, and UI elements © 2026 Desi Cycling Club (or developer name)

**No trademarked material used beyond**:
- Strava® logo and branding (authorized use for API integrations per Strava Brand Guidelines)
- SF Symbols (provided by Apple for iOS app development)

---

## CONTACT INFORMATION

⚠️ **DEVELOPER ACTION REQUIRED**

**Support Email**: `support@desicyclingclub.com`  
**Privacy Contact**: `privacy@desicyclingclub.com`  
**General Inquiries**: `info@desicyclingclub.com`

**STATUS**: Replace with actual developer email addresses before submission

---

## SCREENSHOTS REQUIRED

App Store Connect requires screenshots for the following device sizes:

### iPhone (Required)
- **6.9" Display** (iPhone 16 Pro Max, 15 Pro Max) - 1320 x 2868 pixels
- **6.5" Display** (iPhone 14 Plus, 15 Plus, 14 Pro Max) - 1284 x 2778 pixels

### iPad (If supported)
- **13" Display** (iPad Pro 13") - 2064 x 2752 pixels
- **12.9" Display** (iPad Pro 12.9") - 2048 x 2732 pixels

**Recommended screenshots to capture**:
1. Main dashboard with weekly summary cards
2. Chart view showing bar graph and pie chart
3. "Just My Stats" view with club comparisons
4. "Me vs Top 3 Riders" comparison charts
5. Individual activity detail screen
6. Welcome/login screen with "Connect with Strava" button

**Design guidelines**:
- Use real data (not Lorem Ipsum or obvious test data)
- Ensure text is readable at thumbnail size
- Maintain consistent visual style across all screenshots
- Consider adding localized screenshots for non-English markets (future)

---

## APP PREVIEW VIDEO (Optional but Recommended)

While not required for v1.0 submission, an App Preview video can significantly increase conversion rates.

**Suggested flow** (30 seconds):
1. Open app to welcome screen (2s)
2. Tap "Connect with Strava" (2s)
3. Show Strava OAuth login (skip actual credentials entry) (3s)
4. Dashboard loads with weekly summary cards (3s)
5. Scroll through bar chart and pie chart (4s)
6. Tap a summary card → mode selection sheet appears (3s)
7. Tap "Just My Stats" → personal stats view (4s)
8. Return → tap "Me vs Top 3 Riders" → comparison charts (4s)
9. Tap a rider name → member detail screen (3s)
10. Close with app icon and tagline (2s)

**Technical specs**:
- Resolution: 1920x1080 (landscape) or 1080x1920 (portrait)
- Duration: 15-30 seconds
- Format: .mov, .m4v, or .mp4
- Audio: Optional (background music must be licensed)

---

## LOCALIZATION

**Version 1.0.0**: English (United States) only

**Future versions** (consider for v1.1+):
- English (UK)
- Hindi (India market)
- Spanish (global market)
- French
- German
- Chinese (Simplified)

**Localization impact**:
- App Store listing (description, keywords, screenshots)
- In-app text and labels
- Date/time formatting (already handled via Locale.current)
- Number formatting (km vs miles - consider for US market)

---

## EXPORT COMPLIANCE

**Does your app use encryption?**

**Answer**: **YES** - Standard iOS encryption only

**Explanation**: This app uses HTTPS (TLS) for network communication and iOS Keychain (AES-256) for token storage. Both are standard platform-provided encryption.

**Export Compliance Classification**: **NO** - Does not require export documentation

Apple's App Store Connect will ask: "Is your app designed to use cryptography or does it contain or incorporate cryptography?"

**Answer "NO"** if you are only using:
- HTTPS/TLS for API calls
- iOS Keychain for storage
- Standard Apple-provided encryption

**Answer "YES"** only if you implement custom encryption beyond Apple's APIs.

---

## ADVERTISING IDENTIFIER (IDFA)

**Does this app use the Advertising Identifier (IDFA)?**

**Answer**: **NO**

This app:
- ❌ Does not serve ads
- ❌ Does not track users across apps and websites
- ❌ Does not use any advertising SDKs (Google Ads, Facebook Ads, etc.)
- ❌ Does not implement ATTrackingManager or AppTrackingTransparency

**App Store Connect checkbox**: Leave **unchecked** - "This app uses the Advertising Identifier"

---

## THIRD-PARTY CONTENT

**Does this app display third-party content?**

**Answer**: **YES** - Displays Strava activity data

**Explanation**: The app displays publicly available cycling activity data (distances, times, speeds) from Strava's API. This data is:

- Already visible to club members on Strava
- Accessed with user consent via OAuth 2.0
- Subject to Strava's Terms of Service and Privacy Policy
- Not user-generated content in the traditional sense (no comments, posts, or social interactions)

**Content moderation**: Not applicable - the app displays structured activity data (numbers/metrics), not free-form user content.

---

## DOCUMENT VERSION CONTROL

**Version**: 1.0  
**Last Updated**: February 24, 2026  
**Status**: Ready for submission (pending URL placeholders)  
**Reviewed By**: [Developer Name]  
**Next Review Date**: Before v1.1 submission

---

## PRE-SUBMISSION CHECKLIST

Before copying content to App Store Connect, confirm:

- [ ] App name is unique on App Store (search to verify)
- [ ] Subtitle is 30 characters or fewer
- [ ] Promotional text is 170 characters or fewer
- [ ] Description is 4000 characters or fewer
- [ ] Keywords are 100 characters or fewer, comma-separated
- [ ] Support URL is live and accessible
- [ ] Privacy Policy URL is live and accessible
- [ ] All placeholder emails replaced with actual addresses
- [ ] Screenshots captured for all required device sizes
- [ ] Age rating questionnaire completed in App Store Connect
- [ ] Export compliance questions answered
- [ ] IDFA usage correctly declared (NO for this app)
- [ ] Content rights confirmed (Strava API compliance)
- [ ] All text proofread for typos and grammar

---

**⚠️ CRITICAL REMINDERS**:

1. **Privacy Policy URL must be live** before submission - Apple will reject if it's inaccessible
2. **Test account credentials** must be provided in Review Notes (see APPLE_REVIEW_NOTES.md)
3. **Support URL** should load a help page, FAQ, or contact form (not a 404 error)
4. **All placeholder emails** must be replaced with real, monitored addresses
5. **Bundle ID must match** Xcode project, provisioning profile, and Strava OAuth redirect URI

---


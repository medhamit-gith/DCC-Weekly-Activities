# Submission Checklist — DCC Weekly Activities v1.0
_Last updated: February 17, 2026_

Mark each item ✅ as you complete it. Everything here must be done before
clicking "Submit for Review" in App Store Connect.

---

## 🔴 MUST DO — Code / Security  (already fixed in this session)

- [x] Client secret removed from source code
- [x] Token exchange moved to Cloudflare Worker (`cloudflare-worker/worker.js`)
- [x] All debug `print()` statements wrapped in `#if DEBUG`
- [x] Privacy policy HTML created (`docs/privacy-policy.html`)
- [x] Support page HTML created (`docs/support.html`)

---

## 🔴 MUST DO — Your 1-hour tasks today

### 1. Deploy the Cloudflare Worker  (~10 min)
- [ ] Go to https://workers.cloudflare.com — sign up free (no credit card)
- [ ] Click **Create a Worker** → paste `cloudflare-worker/worker.js`
- [ ] Click **Settings → Variables** and add:
      - `STRAVA_CLIENT_ID`     = `161984`
      - `STRAVA_CLIENT_SECRET` = `6bb21cc2260c0be095a4fd647a8e8acfaba58295`
      (Mark the secret as **Encrypted**)
- [ ] Click **Save and Deploy**
- [ ] Copy your worker URL (e.g. `https://dcc-strava.YOURNAME.workers.dev`)
- [ ] Paste it into `AppConfiguration.swift` → `Strava.tokenWorkerURL`
- [ ] Build and test login still works

### 2. Push to GitHub + enable GitHub Pages  (~10 min)
- [ ] Commit and push everything to GitHub (main branch)
- [ ] In your repo: **Settings → Pages → Source: main branch → /docs folder**
- [ ] Save — GitHub gives you a URL like `https://YOURNAME.github.io/DCC-Weekly-Activities/`
- [ ] Replace `YOUR_GITHUB_USERNAME` in `AppConfiguration.swift` with your real username
- [ ] Visit the privacy policy URL in a browser and confirm it loads
- [ ] Visit the support URL and confirm it loads

### 3. Add NSFaceIDUsageDescription to Info.plist  (~5 min)
- [ ] In Xcode, open your app target → **Info** tab
- [ ] Add row: `Privacy - Face ID Usage Description`
- [ ] Value: `DCC Weekly Activities uses Face ID to protect your Strava data.`

### 4. App Icon  (~30 min)
- [ ] Design or commission a 1024×1024 PNG icon (no transparency, no rounded corners — Apple adds them)
  - Quick option: use https://www.canva.com (search "app icon")
  - The existing saffron/bicycle theme from the app works great
- [ ] Upload to https://appicon.co to generate all required sizes
- [ ] Drag the generated folder into Xcode → `Assets.xcassets → AppIcon`
- [ ] Confirm the icon appears in the Xcode asset catalogue at all sizes
- [ ] Build and confirm icon appears on the simulator home screen

### 5. Screenshots  (~30 min)
Take these on the **iPhone 16 Pro Max simulator** (6.7"):
- [ ] Screenshot 1: Dashboard with real data loaded (the leaderboard visible)
- [ ] Screenshot 2: Member detail sheet open (tap a performer row)
- [ ] Screenshot 3: Hero card / stats overview
Capture with **⌘S** in the simulator. They land in ~/Desktop.
Minimum 3, maximum 10. First screenshot is shown in search results — make it count.

### 6. Strava API — confirm app is registered  (~5 min)
- [ ] Go to https://www.strava.com/settings/api
- [ ] Confirm your app is listed and **not** in sandbox/dev-only mode
- [ ] Confirm the redirect URI matches: `dccweeklyactivities://strava-callback`
- [ ] Add your Cloudflare Worker domain to the authorised domains if Strava asks

---

## 🟡 App Store Connect setup  (~20 min)

### Create the app record
- [ ] Go to https://appstoreconnect.apple.com
- [ ] My Apps → **+** → New App
  - Platform: iOS
  - Name: `DCC Weekly Activities`
  - Primary language: English (UK) or English (US)
  - Bundle ID: your bundle ID from Xcode (e.g. `com.yourname.dccweeklyactivities`)
  - SKU: `dcc-weekly-v1` (any unique string, not shown publicly)

### App Information
- [ ] Subtitle: `Track Club Cycling Stats`
- [ ] Category: Health & Fitness / Sports
- [ ] Privacy Policy URL: your GitHub Pages URL (e.g. `https://YOURNAME.github.io/DCC-Weekly-Activities/privacy-policy.html`)

### Version 1.0 Information
- [ ] What's New: see APP_STORE_LISTING.md
- [ ] Description: see APP_STORE_LISTING.md
- [ ] Keywords (100 chars): `cycling,strava,club,activities,stats,bike,rides,fitness,tracking,leaderboard`
- [ ] Support URL: your GitHub Pages support URL
- [ ] Screenshots uploaded (from step 5)
- [ ] Build attached (from archive step below)

### Review Information (CRITICAL — without this Apple rejects immediately)
- [ ] Contact name, email, phone
- [ ] Demo Strava account credentials — create a test Strava account, join your club with it
- [ ] Notes for reviewer:
  ```
  This app requires a Strava account and membership in the Desi Cycling Club
  (Club ID 212760) on Strava to display data.

  Test account provided:
    Email: [test account email]
    Password: [test account password]

  Steps to test:
  1. Tap "Connect with Strava"
  2. Log in with the credentials above
  3. Authorise the app
  4. The dashboard shows this week's club ride statistics

  Note: The app uses Face ID for subsequent logins. In the simulator this
  can be triggered via Features → Face ID → Matching Face.

  Contact: [your email]  [your phone]
  ```

### App Privacy
- [ ] Complete the privacy questionnaire in App Store Connect
  - Data Not Linked to You: Health & Fitness (activity data from Strava)
  - No data used for tracking
  - No data linked to identity

### Age Rating
- [ ] Complete age rating questionnaire → result should be **4+**

### Pricing
- [ ] Price: Free

---

## 🟢 Archive & Upload  (~15 min)

- [ ] In Xcode: select **Any iOS Device (arm64)** as destination (not a simulator)
- [ ] **Product → Clean Build Folder** (⌘⇧K)
- [ ] **Product → Archive**
- [ ] In Organizer: select the archive → **Validate App** → fix any errors
- [ ] **Distribute App → App Store Connect → Upload**
- [ ] Wait ~15 min for processing email from Apple
- [ ] In App Store Connect, attach the build to your version

---

## ✅ Final check before submitting

- [ ] Privacy policy URL loads in a browser
- [ ] Support URL loads in a browser
- [ ] Test account credentials work in the live app
- [ ] All screenshots uploaded and in the right order
- [ ] Build is attached to the version
- [ ] No placeholder text anywhere in the metadata
- [ ] Click **Submit for Review** 🚀

---

## After submission
Typical review time: 1–3 days.
Check email and App Store Connect daily.
Be ready to answer quickly if Apple contacts you — fast responses = faster approval.

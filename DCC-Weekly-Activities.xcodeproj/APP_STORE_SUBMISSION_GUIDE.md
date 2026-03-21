# App Store Submission Process - Step by Step
## DCC Weekly Activities - Complete Submission Guide
**Date:** March 5, 2026

---

## ✅ PRE-SUBMISSION VERIFICATION

Before we start, confirm these are complete:

- [x] NSFaceIDUsageDescription added to Info.plist
- [x] URL scheme `dcc-activities` registered
- [x] App Transport Security verified (no arbitrary loads)
- [ ] Privacy Policy URL ready (required!)
- [ ] App icon (1024x1024) ready
- [ ] Screenshots ready (minimum 3)
- [ ] Test account credentials ready

---

## 📱 PHASE 1: PREPARE YOUR APP FOR ARCHIVE

### Step 1: Final Code Review

**Check for Debug Code:**
```swift
// Search your project for:
print(          // Remove or wrap in #if DEBUG
NSLog(          // Remove or wrap in #if DEBUG
TODO:           // Review and fix
FIXME:          // Review and fix
```

**Action:**
1. Open Xcode
2. **Edit** → **Find** → **Find in Project** (⌘⇧F)
3. Search for `print(`
4. For each result, either:
   - Delete it (if not needed)
   - Wrap in `#if DEBUG ... #endif`

**Example:**
```swift
#if DEBUG
print("[Debug] User logged in: \(username)")
#endif
```

### Step 2: Verify Version Numbers

1. In Xcode, select your target → **General** tab
2. Check:
   - **Display Name:** DCC Weekly (or your preferred name)
   - **Version:** 1.0.0 (or your version)
   - **Build:** 1 (increment this for each upload)
   - **Bundle Identifier:** Should be unique (e.g., com.yourname.dccweekly)

### Step 3: Set Build Configuration to Release

1. **Product** → **Scheme** → **Edit Scheme** (or ⌘<)
2. Select **Run** in left sidebar
3. **Info** tab → **Build Configuration** → Select **Release**
4. Click **Close**

### Step 4: Select Destination

1. At the top of Xcode, next to the scheme selector
2. Click on device/simulator dropdown
3. Select **Any iOS Device (arm64)**
   - NOT a specific device
   - NOT a simulator

---

## 📦 PHASE 2: ARCHIVE YOUR APP

### Step 5: Clean Build

1. **Product** → **Clean Build Folder** (⌘⇧K)
2. Wait for completion

### Step 6: Create Archive

1. **Product** → **Archive**
2. Wait for build to complete (can take 2-10 minutes)
3. If successful, the **Organizer** window opens automatically
4. You'll see your archive listed with:
   - App name
   - Version number
   - Date/time
   - Size

**Common Errors:**
- **Build Failed:** Check error messages, fix issues, try again
- **Code Signing Error:** Go to **Signing & Capabilities** → Select your team
- **Missing Provisioning Profile:** Let Xcode manage signing automatically

### Step 7: Validate Archive

**Before uploading, validate to catch issues early:**

1. In **Organizer**, select your archive
2. Click **Validate App** button (on right side)
3. Follow the wizard:
   - **Destination:** App Store Connect
   - **App Store Connect distribution options:**
     - ✅ Upload your app's symbols (for crash reports)
     - ✅ Manage Version and Build Number (recommended)
   - **App Store Connect signing:**
     - ☑️ Automatically manage signing (recommended)
     - OR manually select certificates if you prefer
4. Click **Validate**
5. Wait for validation (2-5 minutes)

**Validation Results:**

**✅ Success:**
- "Archive validation was successful"
- Proceed to upload!

**⚠️ Warnings (Usually OK):**
- "Missing recommended icon sizes" → Can ignore if you have main icons
- "Uses non-exempt encryption" → We'll handle this in App Store Connect

**❌ Errors (Must Fix):**
- **Code signing issues** → Check certificates in developer account
- **Missing entitlements** → Check Signing & Capabilities
- **Invalid bundle** → Check bundle identifier is unique
- **Missing Info.plist keys** → Add required privacy descriptions

### Step 8: Upload to App Store Connect

**After validation passes:**

1. Click **Distribute App** button
2. Select **App Store Connect**
3. Select **Upload**
4. Review options (same as validation):
   - ✅ Upload symbols
   - ✅ Manage version/build
5. Click **Upload**
6. Wait for upload (5-30 minutes depending on size/connection)
7. You should see: "Upload Successful"

**What happens next:**
- App Store Connect processes your build
- You'll get email: "Your app is processing"
- Processing takes 15-60 minutes
- You'll get email: "Build is ready to submit"

---

## 🌐 PHASE 3: APP STORE CONNECT SETUP

### Step 9: Go to App Store Connect

1. Open browser
2. Go to: https://appstoreconnect.apple.com
3. Sign in with your Apple ID
4. Click **My Apps**

### Step 10: Create Your App (First Time Only)

**If this is your first submission:**

1. Click **+** icon → **New App**
2. Fill in:
   - **Platforms:** iOS (check the box)
   - **Name:** DCC Weekly Activities (30 chars max)
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** Select from dropdown (must match Xcode)
   - **SKU:** Any unique ID (e.g., dcc-weekly-2026)
   - **User Access:** Full Access
3. Click **Create**

**If app already exists:**
- Click on your app name
- Proceed to Step 11

### Step 11: Fill in App Information

**Click on your app, then go to App Information section:**

#### Localizable Information:
- **Name:** DCC Weekly Activities
- **Subtitle:** Track Club Cycling Stats (30 chars max)
- **Privacy Policy URL:** ⚠️ **REQUIRED** - Must be public URL
  - Example: https://yourwebsite.com/privacy
  - Or use GitHub Pages
  - See below for quick privacy policy creation

#### General Information:
- **Primary Category:** Health & Fitness
- **Secondary Category:** Sports (optional)
- **Content Rights:** Check if you own all content

#### Age Rating:
- Click **Edit**
- Answer questionnaire honestly
- Most likely: **4+** (no objectionable content)

### Step 12: Pricing and Availability

1. Click **Pricing and Availability** in left sidebar
2. **Price:** Select **Free** (or set price)
3. **Availability:**
   - Select countries where you want app available
   - Recommend: All territories (or at minimum: India, US, UK, Canada)

### Step 13: Prepare for Submission

**Click on your version (e.g., 1.0.0) in left sidebar:**

You'll see sections to complete. Let's go through each:

---

## 📝 PHASE 4: VERSION INFORMATION

### Step 14: App Previews and Screenshots

**⚠️ REQUIRED - Minimum 3 screenshots per device size**

**iPhone 6.7" Display (iPhone 15 Pro Max) - REQUIRED:**
1. Click **+** under iPhone 6.7" Display
2. Upload 3-10 screenshots (1290 x 2796 pixels)
3. Drag to reorder (first screenshot is most important!)

**How to create screenshots:**
1. Open Xcode
2. Run app on **iPhone 15 Pro Max simulator**
3. Navigate to screens you want to capture
4. **⌘S** to save screenshot
5. Screenshots saved to Desktop
6. Upload to App Store Connect

**Recommended screenshots:**
1. **Dashboard** - Show weekly stats, hero numbers
2. **Leaderboard** - Show top riders with podium
3. **Charts** - Show beautiful data visualization
4. **Login/Welcome** - Show glass card with Face ID icon
5. **Activities List** - Show recent rides

**Pro tip:** Add device frames and text overlays using:
- Canva
- Keynote/PowerPoint
- Online tools like appure.io

### Step 15: Promotional Text (Optional)

**170 character description that can be updated without review:**

```
Stay connected with your cycling club! Track weekly stats, compare with members, and celebrate achievements together. 🚴‍♂️
```

### Step 16: Description

**4000 character app description:**

```
🚴‍♂️ DCC WEEKLY ACTIVITIES - Track Your Cycling Club's Journey

Stay connected with your Desi Cycling Club and track everyone's weekly achievements in one beautiful app!

📊 COMPREHENSIVE WEEKLY STATISTICS
• View total distance, rides, and elevation for all club members
• See real-time updates as activities are logged
• Beautiful charts and data visualizations
• Track club totals and individual performances

🏆 LEADERBOARDS & RANKINGS
• Weekly leaderboard with podium for top performers
• Compare your stats with other club members
• Celebrate achievements together
• Indian flag-inspired design honoring our heritage

📈 DETAILED INSIGHTS
• Individual rider analysis and trends
• Week-over-week performance comparison
• Personal bests and achievements
• Activity history and patterns

🔒 SECURE & PRIVATE
• Biometric authentication (Face ID/Touch ID)
• Secure Strava integration
• Your data stays private
• Local data storage

🎨 BEAUTIFUL DESIGN
• Dark mode optimized
• Glass morphism UI inspired by Indian flag colors
• Smooth animations and transitions
• Professional, modern interface

⚡️ POWERED BY STRAVA
Seamlessly connects to your Strava account to automatically track and sync all your cycling activities. No manual entry needed!

📱 BUILT FOR CYCLISTS, BY CYCLISTS
Whether you're training for your next century ride or just enjoying weekend spins with the club, DCC Weekly Activities keeps you motivated and connected with your cycling community.

FEATURES AT A GLANCE:
✓ Automatic activity tracking via Strava
✓ Weekly leaderboards and statistics
✓ Individual performance insights
✓ Beautiful data visualizations
✓ Biometric security
✓ Dark mode support
✓ iPad and iPhone support

Perfect for cycling clubs, teams, and groups who want to stay connected and motivated!

REQUIREMENTS:
• Active Strava account (free)
• Membership in Desi Cycling Club
• iOS 17.0 or later

SUPPORT:
Have questions or feedback? Contact us at support@desicyclingclub.com

Join the DCC community and make every ride count! 🚴‍♀️💪
```

### Step 17: Keywords

**100 characters max, comma-separated, no spaces:**

```
cycling,strava,club,bike,rides,fitness,stats,tracking,leaderboard,performance,activities
```

**Tips:**
- No spaces after commas (saves characters)
- Don't repeat words from app name
- Use singular form (Apple adds plurals)

### Step 18: Support URL

**Required - public URL for user support:**

Options:
1. **Email link:** `mailto:support@desicyclingclub.com`
2. **Website:** Your club website
3. **GitHub:** If you have a public repo with wiki
4. **Social media:** Facebook page, Instagram link

### Step 19: Marketing URL (Optional)

Your club's website or social media page.

### Step 20: Version Information

**What's New in This Version:**

```
🎉 Welcome to DCC Weekly Activities!

📊 Track your Desi Cycling Club's weekly achievements
🏆 View leaderboards and member rankings
📈 Beautiful charts and data visualizations
🔒 Secure Face ID authentication
🎨 Indian flag-inspired design
📱 Support for iPhone and iPad

Happy riding! 🚴‍♂️🚴‍♀️
```

---

## 🔐 PHASE 5: APP PRIVACY

### Step 21: App Privacy Details

**⚠️ CRITICAL - Required by Apple**

1. Click **Set Up App Privacy** (or edit if exists)
2. Answer questions honestly:

**Data Collection:**

**Question:** Does your app collect data?
**Answer:** YES

**Data Types You Collect:**

1. **Health & Fitness → Physical Activity**
   - What: Cycling activities, distance, speed, elevation
   - Why: App functionality
   - Linked to user: NO (you don't link to identity)
   - Used for tracking: NO

**That's it!** You only collect Strava activity data.

**Do NOT select:**
- Contact Info (you don't collect)
- Location (Strava handles this, you don't access)
- Identifiers (unless using analytics)
- Usage Data (unless using analytics)

### Step 22: Privacy Policy URL

**⚠️ REQUIRED**

You need a public privacy policy. Quick options:

**Option 1: GitHub Pages (Free, Quick)**
1. Create file `privacy-policy.html` in your repo
2. Enable GitHub Pages in repo settings
3. URL: `https://yourusername.github.io/dcc-weekly/privacy-policy.html`

**Option 2: Use Generator**
1. Go to: https://app-privacy-policy-generator.firebaseapp.com/
2. Fill in your app details
3. Copy generated policy
4. Host on free platform (GitHub Pages, Netlify, etc.)

**Minimum Privacy Policy Content:**

```markdown
# Privacy Policy - DCC Weekly Activities

Last Updated: March 5, 2026

## Data We Collect
DCC Weekly Activities collects cycling activity data from your Strava account, including:
- Ride distance
- Average speed
- Elevation gain
- Activity dates and times

## How We Use Your Data
Your activity data is used solely to:
- Display weekly club statistics
- Show leaderboards and rankings
- Compare performance week-over-week

## Data Storage
All data is stored locally on your device. We do not store your data on external servers.

## Data Sharing
We do not share, sell, or transfer your data to third parties.

## Third-Party Services
This app connects to Strava's API to fetch your cycling activities. Please review Strava's privacy policy at: https://www.strava.com/legal/privacy

## Security
We use Face ID/Touch ID to protect access to your data.

## Your Rights
You can delete all data by:
- Disconnecting your Strava account
- Deleting the app

## Contact
For privacy questions, contact: support@desicyclingclub.com
```

---

## 👤 PHASE 6: APP REVIEW INFORMATION

### Step 23: Contact Information

**If Apple needs to contact you during review:**

- **First Name:** Your first name
- **Last Name:** Your last name
- **Phone Number:** Your phone (with country code)
- **Email:** Your email (CHECK THIS DAILY during review!)

### Step 24: Demo Account (CRITICAL!)

**⚠️ Your app requires Strava login - MUST provide test account**

**Sign-in required:** YES

**Username:** [Your test Strava account email]
**Password:** [Test account password]

**If you don't have a test account:**
1. Create new Strava account
2. Join Desi Cycling Club
3. Log a few test activities
4. Provide these credentials

### Step 25: Notes for Reviewer

**Very important - explain how your app works:**

```
IMPORTANT: This app requires a Strava account and membership in the Desi Cycling Club to function.

TEST ACCOUNT PROVIDED:
The demo account provided above is:
- An active Strava account
- A member of the Desi Cycling Club
- Has logged several cycling activities

TESTING INSTRUCTIONS:
1. Launch the app
2. Tap "Connect with Strava"
3. Log in with provided credentials
4. Grant permissions when prompted
5. App will redirect back and show club statistics

FEATURES TO REVIEW:
• Strava OAuth authentication
• Face ID/Touch ID security
• Weekly activity statistics dashboard
• Leaderboard with member rankings
• Individual rider insights
• Activity list view

NOTES:
• App only displays data for Desi Cycling Club members
• Data is fetched from Strava's public API
• No user data is stored on external servers
• Face ID prompt uses approved description string

SUPPORT:
If you have any questions, please contact me at [your-email@example.com]

Thank you for reviewing our app!
```

### Step 26: Attachment (Optional)

You can upload a video showing how to use the app (recommended!)

---

## 🔒 PHASE 7: EXPORT COMPLIANCE

### Step 27: Export Compliance

**Question:** Does your app use encryption?

**Answer for most apps:** NO

**Why?**
- Standard HTTPS doesn't count as "encryption" for export purposes
- You're not using custom encryption
- You're just making API calls

**If asked to elaborate:**
- Select: "No, my app does not use encryption"
- You're done!

---

## 🏗️ PHASE 8: BUILD SELECTION

### Step 28: Add Your Build

1. Scroll to **Build** section
2. Click **+ Select a build before you submit your app**
3. Wait for your build to appear (may take 15-60 min after upload)
4. Select your build from the list
5. Click **Done**

**If build doesn't appear:**
- Check your email for processing status
- Wait - processing can take up to an hour
- Refresh the page
- If failed, you'll get email with reason

---

## ✅ PHASE 9: FINAL REVIEW & SUBMIT

### Step 29: Review Everything

Go through each section and verify:

- [ ] App icon shows correctly
- [ ] Screenshots uploaded (minimum 3)
- [ ] Description looks good
- [ ] Keywords filled in
- [ ] Support URL works
- [ ] Privacy Policy URL works
- [ ] Privacy details completed
- [ ] Demo account credentials provided
- [ ] Notes for reviewer filled in
- [ ] Build selected
- [ ] Version number correct
- [ ] All required fields have ✅ checkmark

### Step 30: Save

Click **Save** button at top right frequently!

### Step 31: Submit for Review

1. Click **Add for Review** or **Submit for Review** button
2. Review the summary
3. Click **Submit**
4. Confirm submission

**You'll see:**
- Status changes to **Waiting for Review**
- Confirmation email sent
- Can no longer edit (unless you cancel submission)

---

## ⏰ PHASE 10: WHAT HAPPENS NEXT

### Timeline:

**Waiting for Review:** 0-3 days (usually 1-2 days)
**In Review:** 1-48 hours (usually 12-24 hours)
**Total:** Typically 1-7 days

### Status Meanings:

| Status | What It Means | Your Action |
|--------|---------------|-------------|
| **Waiting for Review** | In queue | Wait |
| **In Review** | Apple is actively testing | Check email often |
| **Pending Developer Release** | ✅ APPROVED! | Release when ready |
| **Ready for Sale** | 🎉 LIVE on App Store! | Celebrate! |
| **Rejected** | Issues found | Fix and resubmit |
| **Developer Rejected** | You cancelled | Can resubmit |

### If Approved:

**Automatic Release:**
- App goes live immediately
- Appears in App Store within 24 hours
- Searchable by name and keywords

**Manual Release:**
- You choose when to release
- Click "Release this version" when ready
- Good for coordinated launches

### If Rejected:

**DON'T PANIC - Very common for first submission!**

1. Read rejection email carefully
2. Note specific issues mentioned
3. Fix each issue
4. Reply in Resolution Center (if needed)
5. Resubmit (usually faster review second time)

**Common rejection reasons:**
- Missing demo account or doesn't work
- Privacy policy issues
- App crashes on reviewer's device
- Metadata doesn't match app functionality
- Missing required legal info

---

## 📊 POST-SUBMISSION CHECKLIST

### While Waiting:

- [ ] Check email twice daily
- [ ] Keep phone available (they may call!)
- [ ] Test your demo account still works
- [ ] Prepare social media posts
- [ ] Plan launch announcement

### After Approval:

- [ ] Share with club members
- [ ] Post on social media
- [ ] Monitor crash reports
- [ ] Respond to user reviews
- [ ] Plan first update

---

## 🆘 TROUBLESHOOTING

### "I can't find where to create a new app"
- Go to App Store Connect → My Apps
- Click **+** icon at top left
- Select **New App**

### "My bundle ID isn't in the dropdown"
- Go to developer.apple.com
- Certificates, Identifiers & Profiles
- Create new App ID
- Use same bundle ID as Xcode

### "Build validation failed"
- Read the error message carefully
- Common fixes:
  - Update signing certificates
  - Check bundle identifier matches
  - Add missing privacy descriptions
  - Fix code signing issues

### "Upload stuck at 'Processing'"
- Normal - can take up to 1 hour
- Check email for status
- If > 2 hours, try re-uploading

### "Build disappeared from list"
- Check email - may have failed processing
- Try uploading again
- Increment build number

---

## 📞 NEED HELP?

### Apple Resources:
- App Store Connect Help: https://help.apple.com/app-store-connect/
- Developer Support: https://developer.apple.com/support/
- Phone: 1-800-633-2152 (US)

### Review Guidelines:
https://developer.apple.com/app-store/review/guidelines/

### Strava:
- API Docs: https://developers.strava.com/
- Brand Guidelines: https://developers.strava.com/guidelines/

---

## ✅ FINAL CHECKLIST

Before clicking Submit:

- [ ] App builds and runs without errors
- [ ] Tested on real device (not just simulator)
- [ ] All features work correctly
- [ ] Face ID prompt shows correct description
- [ ] OAuth login works (tested with demo account)
- [ ] Screenshots show accurate app features
- [ ] Description proofread (no typos!)
- [ ] Privacy policy URL works and is public
- [ ] Demo account credentials verified working
- [ ] Support email/URL accessible
- [ ] Build uploaded and processing complete
- [ ] All App Store Connect sections complete
- [ ] Saved all changes

**Ready? Click Submit for Review!** 🚀

---

**Good luck with your submission! 🎉**

Most apps are approved within 24-48 hours. You've got this!

---

*Last updated: March 5, 2026*  
*For DCC Weekly Activities v1.0.0*

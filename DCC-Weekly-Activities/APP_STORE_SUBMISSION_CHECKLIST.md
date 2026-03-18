# App Store Submission Checklist
## DCC Weekly Activities - Complete Pre-Launch Guide

Use this checklist to ensure you have everything ready before submitting to the App Store.

---

## 🎨 VISUAL ASSETS

### App Icon (REQUIRED)
- [ ] 1024x1024 App Store icon created
- [ ] All iOS icon sizes generated (20px to 180px)
- [ ] Icons added to Assets.xcassets/AppIcon
- [ ] No transparency in any icons
- [ ] All icons are PNG format
- [ ] Icons look good at small sizes (test at 60x60)
- [ ] Icon tested on actual device
- [ ] Icon approved by team/stakeholders

**Tool recommendations:**
- appicon.co - Generate all sizes from 1024x1024
- Canva - Design original icon
- Fiverr - Hire designer ($5-50)

---

### Screenshots (REQUIRED - minimum 3 per device)

#### iPhone 6.7" (1290 x 2796) - iPhone 15 Pro Max
- [ ] Screenshot 1: Dashboard/Home screen
- [ ] Screenshot 2: Charts/Statistics view
- [ ] Screenshot 3: Table view
- [ ] Screenshot 4: Activities list (optional)
- [ ] Screenshot 5: Additional feature (optional)
- [ ] All screenshots are exactly 1290 x 2796 pixels
- [ ] Screenshots show realistic data (not empty states)
- [ ] Screenshots captured from iPhone 15 Pro Max simulator

#### iPhone 6.5" (1284 x 2778) - OPTIONAL but recommended
- [ ] Same screens as above at 1284 x 2778
- [ ] Captured from iPhone 11 Pro Max simulator

#### iPad Pro 12.9" (2048 x 2732) - If supporting iPad
- [ ] Screenshot 1: Dashboard
- [ ] Screenshot 2: Charts
- [ ] Screenshot 3: Table view
- [ ] Screenshots show iPad-optimized layouts
- [ ] All exactly 2048 x 2732 pixels

#### Screenshot Enhancement (OPTIONAL but professional)
- [ ] Device frames added (using Frameit or online tool)
- [ ] Text overlays added to explain features
- [ ] Consistent branding across all screenshots
- [ ] Text is readable when shrunk in App Store

**Tools:**
- Xcode Simulator - Capture screenshots (Cmd+S)
- Frameit/Appure.io - Add device frames
- Canva/Keynote - Add text overlays

---

### App Preview Video (OPTIONAL but increases downloads by 30%)
- [ ] 15-30 second video created
- [ ] Captures key features in action
- [ ] No audio required (text overlays instead)
- [ ] Same dimensions as screenshots
- [ ] Exported as .mp4 or .mov
- [ ] File size under 500MB
- [ ] Uploaded to App Store Connect

**Tools:**
- QuickTime Screen Recording
- iMovie - Edit and add titles
- Final Cut Pro - Professional editing

---

## 📱 XCODE PROJECT

### General Settings
- [ ] App name set correctly in project
- [ ] Bundle identifier is unique (com.yourname.dccweeklyactivities)
- [ ] Team selected in Signing & Capabilities
- [ ] Deployment target set appropriately (iOS 15+)
- [ ] Supported devices configured (iPhone, iPad)
- [ ] Orientations set (usually Portrait only)
- [ ] Version number set (e.g., 1.0.0)
- [ ] Build number set (e.g., 1)

### Capabilities
- [ ] Required capabilities enabled:
  - [ ] Networking (for Strava API)
  - [ ] Face ID/Touch ID (if using biometric auth)
- [ ] Unnecessary capabilities removed

### Privacy - Usage Descriptions
Add these to Info.plist:

- [ ] NSFaceIDUsageDescription
  ```
  "DCC Weekly Activities uses Face ID to securely protect your Strava data."
  ```

- [ ] NSPhotoLibraryAddUsageDescription (if saving screenshots)
  ```
  "DCC Weekly Activities would like to save statistics to your Photos."
  ```

### Build Settings
- [ ] Build configuration set to "Release"
- [ ] Bitcode enabled (if required)
- [ ] Symbols included for crash reporting
- [ ] No debug code or print statements in production

### Testing
- [ ] App builds without errors
- [ ] App builds without warnings (fix all warnings!)
- [ ] App runs on iOS Simulator
- [ ] App runs on real device
- [ ] All features tested:
  - [ ] Strava authentication works
  - [ ] Club data loads correctly
  - [ ] Charts display properly
  - [ ] Table sorting works
  - [ ] Activities list loads
  - [ ] Error handling works
  - [ ] Biometric auth works (if implemented)
  - [ ] Dark mode looks good
  - [ ] iPad layout works (if supporting iPad)
  - [ ] tvOS works (if supporting tvOS)
- [ ] No crashes in normal usage
- [ ] Memory usage is reasonable
- [ ] App responds quickly to user input

---

## 📝 APP STORE CONNECT - INFORMATION

### App Information

#### Name & Category
- [ ] App Name (30 chars max): "DCC Weekly Activities"
- [ ] Subtitle (30 chars max): "Track Club Cycling Stats"
- [ ] Primary Category: Health & Fitness
- [ ] Secondary Category: Sports

#### Privacy & URL
- [ ] Privacy Policy URL created and active
  - Required if collecting ANY data
  - Must be publicly accessible
  - Can use app-privacy-policy-generator.firebaseapp.com
- [ ] Support URL created and active
  - Can be website, email link, or contact form
  - Must be accessible without login
- [ ] Marketing URL (optional)

#### App Review Information
- [ ] Contact Name (your name)
- [ ] Contact Phone (your phone number)
- [ ] Contact Email (your email - checked regularly!)
- [ ] Demo account provided (if app requires login)
  - [ ] Username: [test Strava account]
  - [ ] Password: [test password]
- [ ] Notes for reviewer:
  ```
  This app requires a Strava account and membership in 
  the Desi Cycling Club to function. Test account provided 
  above is a member of the club. The app fetches and displays 
  weekly cycling activity statistics from Strava's API.
  
  Features to test:
  1. Login with provided Strava account
  2. View weekly statistics dashboard
  3. Switch between Charts, Table, and Activities views
  4. Verify data loads correctly
  
  Contact me at [your email] with any questions.
  Thank you!
  ```

### Version Information

#### What's New (Version 1.0.0)
```
🎉 Welcome to DCC Weekly Activities!

Track your Desi Cycling Club's weekly achievements with:

📊 Comprehensive weekly statistics
🏆 Member rankings and leaderboards  
📈 Beautiful charts and visualizations
🔒 Secure biometric authentication
🎨 Indian flag-inspired design
📱 Support for iPhone, iPad, and Apple TV

Happy riding! 🚴‍♂️🚴‍♀️
```

#### Promotional Text (170 chars - can update without review)
```
Stay connected with your cycling club! View weekly stats, compare with members, and celebrate achievements together. Powered by Strava.
```

#### Description (4000 chars max)
- [ ] Compelling opening paragraph
- [ ] Key features listed with emojis
- [ ] How it works section
- [ ] Perfect for section (target audience)
- [ ] Strava integration explained
- [ ] Privacy assurances
- [ ] Support information
- [ ] Keywords naturally integrated
- [ ] No spelling/grammar errors
- [ ] Formatted for readability

**See APP_STORE_LISTING.md for complete description**

#### Keywords (100 chars max, comma-separated)
```
cycling,strava,club,activities,stats,bike,rides,fitness,tracking,leaderboard,performance
```

**Tips:**
- No spaces after commas (saves characters)
- Don't repeat words from app name/subtitle
- Focus on what users search for
- Research competitors' keywords
- Use singular (Apple adds plurals)

### Age Rating
- [ ] Age rating questionnaire completed
- [ ] Recommended: 4+ (no objectionable content)

### Pricing & Availability
- [ ] Price: Free (or set pricing)
- [ ] Available territories selected
  - [ ] All territories where Strava is available
  - Or specific countries: US, UK, Canada, India, Australia, EU
- [ ] Pre-order (optional): No

---

## 🔐 PRIVACY & SECURITY

### App Privacy Details (IMPORTANT!)

#### Data Collection
Answer honestly:

**Contact Info**
- [ ] Do you collect? No

**Health & Fitness**
- [ ] Do you collect? Yes (cycling activities from Strava)
- [ ] Linked to user? No (you don't link it to identity)
- [ ] Used for tracking? No

**Usage Data**
- [ ] Do you collect? No (unless you have analytics)
- [ ] If yes, for what purpose? Analytics
- [ ] Linked to user? No

**Identifiers**
- [ ] Do you collect? No (unless using analytics)

**Other Data**
- [ ] Athletic activity from Strava? Yes
- [ ] Linked to user identity? No
- [ ] Used for tracking? No

### Privacy Policy Content

Must include:
- [ ] What data you collect (Strava activities)
- [ ] Why you collect it (display club statistics)
- [ ] How you use it (local display only)
- [ ] Who you share with (nobody)
- [ ] How users can request deletion
- [ ] Contact information
- [ ] Date of last update

**Quick generator:** https://app-privacy-policy-generator.firebaseapp.com/

---

## 🚀 ARCHIVE & UPLOAD

### Prepare for Archive

1. **Clean project**
   - [ ] Product → Clean Build Folder (Cmd+Shift+K)
   - [ ] Delete DerivedData folder
   - [ ] Close and reopen Xcode

2. **Select build configuration**
   - [ ] Select "Any iOS Device" (not simulator!)
   - [ ] Build configuration: Release
   - [ ] Scheme: Production (if you have multiple)

3. **Verify settings one last time**
   - [ ] Version: 1.0.0
   - [ ] Build: 1
   - [ ] Bundle ID: correct
   - [ ] Team: selected
   - [ ] Signing: Automatic or manual certificates valid

### Archive

- [ ] Product → Archive
- [ ] Wait for build to complete (can take 1-10 minutes)
- [ ] Archive appears in Organizer
- [ ] Archive date/time is correct

### Validate

- [ ] In Organizer, select archive
- [ ] Click "Validate App"
- [ ] Select distribution method: App Store Connect
- [ ] Select signing: Automatically manage signing
- [ ] Complete validation
- [ ] Fix any errors or warnings
- [ ] All validations pass ✅

### Upload

- [ ] Click "Distribute App"
- [ ] Select: App Store Connect
- [ ] Select: Upload
- [ ] Select signing options
- [ ] Review content
- [ ] Click "Upload"
- [ ] Wait for upload to complete (can take 5-30 minutes)
- [ ] Success message received

### Processing

- [ ] Check email for "Ready to Submit" notification
- [ ] Processing usually takes 15-60 minutes
- [ ] Check App Store Connect for build status
- [ ] Build shows "Processing" then "Ready to Submit"

---

## 📊 APP STORE CONNECT - FINAL STEPS

### Add Build
- [ ] Go to App Store Connect
- [ ] Select your app
- [ ] Click "Prepare for Submission" (or your version)
- [ ] Under "Build", click "+" to add a build
- [ ] Select the build you just uploaded
- [ ] Save

### Upload Screenshots
- [ ] iPhone 6.7" screenshots uploaded (3-10 images)
- [ ] iPhone 6.5" screenshots uploaded (if applicable)
- [ ] iPad screenshots uploaded (if supporting iPad)
- [ ] Screenshots in correct order (most important first)
- [ ] Preview video uploaded (if you have one)

### Export Compliance
- [ ] Does your app use encryption? Usually NO
- [ ] If yes, complete export compliance questionnaire
- [ ] Most apps: Select "No" to encryption questions

### Advertising Identifier (IDFA)
- [ ] Does your app use IDFA? Usually NO (unless using ads)
- [ ] If yes, explain usage

### Content Rights
- [ ] I certify that my app contains no copyrighted material
- [ ] I have permission to use Strava API
- [ ] I acknowledge app follows Strava guidelines

---

## ✅ FINAL REVIEW

### Before Submitting

- [ ] All information entered correctly
- [ ] No typos in description or keywords
- [ ] All URLs work and are accessible
- [ ] Screenshots show accurate app features
- [ ] Version "What's New" makes sense
- [ ] Contact information is correct
- [ ] Age rating is appropriate
- [ ] Privacy details are accurate
- [ ] Build is attached
- [ ] Export compliance answered

### Submit for Review

- [ ] Click "Submit for Review"
- [ ] Confirm submission
- [ ] Status changes to "Waiting for Review"
- [ ] Confirmation email received

---

## ⏰ WHAT HAPPENS NEXT

### Review Timeline

**Typical timeline:**
- Waiting for Review: 0-3 days
- In Review: 1-48 hours
- Total: Usually 1-7 days

**Status meanings:**
- **Waiting for Review** - In queue
- **In Review** - Apple is actively reviewing
- **Pending Developer Release** - Approved! Ready when you are
- **Ready for Sale** - Live on App Store!
- **Rejected** - Need to fix issues and resubmit

### If Approved
- [ ] Release immediately or schedule release
- [ ] Share with DCC members
- [ ] Promote on social media
- [ ] Monitor downloads and reviews
- [ ] Respond to user reviews
- [ ] Plan first update

### If Rejected
- [ ] Read rejection reason carefully
- [ ] Don't panic - very common for first submission
- [ ] Fix the issues mentioned
- [ ] Resubmit (usually faster review second time)
- [ ] Use Resolution Center to communicate with Apple

**Common rejection reasons:**
1. Incomplete information
2. Crashes or bugs
3. Privacy policy missing/incorrect
4. Metadata issues (screenshots don't match app)
5. Design guideline violations
6. Third-party trademark issues

---

## 🎉 POST-LAUNCH

### Day 1
- [ ] Monitor crash reports
- [ ] Check user reviews
- [ ] Verify app appears in search
- [ ] Test download and installation
- [ ] Share with friends and club members

### Week 1
- [ ] Respond to all reviews (positive and negative)
- [ ] Fix any critical bugs
- [ ] Monitor analytics (downloads, usage)
- [ ] Gather user feedback
- [ ] Plan improvements

### Month 1
- [ ] Analyze user behavior
- [ ] Identify most-used features
- [ ] Identify pain points
- [ ] Plan version 1.1 features
- [ ] Submit update if needed

---

## 📊 MARKETING (OPTIONAL)

### App Store Optimization (ASO)
- [ ] Monitor keyword rankings
- [ ] Test different screenshots
- [ ] Update promotional text regularly
- [ ] Encourage users to leave reviews

### Social Media
- [ ] Share on club's social media
- [ ] Create launch announcement
- [ ] Share screenshots/videos
- [ ] Engage with users

### Community
- [ ] Email DCC members about app
- [ ] Demo app at club events
- [ ] Create tutorial video
- [ ] Gather testimonials

---

## 🔧 MAINTENANCE

### Regular Updates
- [ ] Fix bugs as reported
- [ ] Add requested features
- [ ] Keep up with iOS updates
- [ ] Update for new devices/screen sizes
- [ ] Refresh screenshots yearly

### Monitoring
- [ ] Set up crash reporting (Crashlytics/Sentry)
- [ ] Monitor API usage/limits
- [ ] Check Strava API for changes
- [ ] Monitor app size (keep under 150MB ideally)

---

## 📞 RESOURCES

**Apple:**
- App Store Connect: https://appstoreconnect.apple.com
- Developer Portal: https://developer.apple.com
- Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Support: https://developer.apple.com/support/

**Strava:**
- API Documentation: https://developers.strava.com/
- Brand Guidelines: https://developers.strava.com/guidelines/
- API Status: https://status.strava.com/

**Tools:**
- App Icon Generator: https://appicon.co
- Screenshot Frames: https://www.appure.io
- Privacy Policy Generator: https://app-privacy-policy-generator.firebaseapp.com
- Keyword Tool: https://www.apptweak.com (paid)

**Communities:**
- r/iOSProgramming - Reddit
- Stack Overflow - Q&A
- Apple Developer Forums

---

## 🎯 SUCCESS METRICS

After launch, track:

**Downloads:**
- [ ] Total downloads
- [ ] Downloads per day
- [ ] Conversion rate (page views to downloads)

**Engagement:**
- [ ] Daily active users
- [ ] Session length
- [ ] Feature usage

**Retention:**
- [ ] Day 1 retention
- [ ] Day 7 retention
- [ ] Day 30 retention

**Quality:**
- [ ] Average rating
- [ ] Number of reviews
- [ ] Crash rate
- [ ] App size

**Goals for v1.0:**
- 50+ downloads in first week
- 4.0+ star rating
- <1% crash rate
- Positive user feedback

---

## ⚠️ COMMON MISTAKES TO AVOID

1. **Wrong screenshot dimensions** - Must be exact!
2. **Placeholder/fake data in screenshots** - Show real features
3. **Missing privacy policy** - Required if collecting data
4. **Broken URLs** - Test all links before submitting
5. **Typos in description** - Proofread everything
6. **App crashes on launch** - Test thoroughly
7. **Missing test account** - Provide working demo credentials
8. **Strava branding violations** - Follow their guidelines
9. **Not responding to review feedback** - Check email daily
10. **Submitting too early** - Test, test, test!

---

## 🎓 PRO TIPS

1. **Screenshot tip:** First screenshot is most important - make it amazing!

2. **Description tip:** Front-load the description with most important info (people don't read past first paragraph)

3. **Keyword tip:** Research what users actually search for, don't guess

4. **Review tip:** Respond to ALL reviews within 24 hours - shows you care

5. **Update tip:** Regular updates (every 4-6 weeks) show active development

6. **Crash tip:** Even one crash in review = rejection. Test thoroughly!

7. **Timeline tip:** Submit 1-2 weeks before you want to launch (buffer for rejections)

8. **Communication tip:** Be polite and professional with review team

9. **Testing tip:** Have someone else test your app before submission

10. **Launch tip:** Don't launch on Friday (can't fix issues over weekend)

---

## ✨ FINAL CHECKLIST

Right before clicking "Submit for Review":

- [ ] I have tested the app thoroughly
- [ ] All assets are uploaded and look professional
- [ ] All text is proofread and accurate
- [ ] All URLs work
- [ ] Privacy policy is complete and accessible
- [ ] Test account credentials are provided and work
- [ ] I have reviewed similar apps to ensure uniqueness
- [ ] I am available to respond quickly if contacted
- [ ] I have read Apple's Review Guidelines
- [ ] I have followed Strava's API guidelines
- [ ] I am ready to launch!

---

**🎉 You're ready to submit! Good luck! 🚀**

**Remember:** Most apps get rejected on first submission. Don't be discouraged - it's part of the process. Fix the issues and resubmit. You've got this!

---

*Checklist last updated: February 13, 2026*
*For DCC Weekly Activities v1.0.0*

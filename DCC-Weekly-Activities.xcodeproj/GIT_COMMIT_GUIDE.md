# 🚀 Git Commit & TestFlight Upload Guide

**Date**: February 19, 2026  
**Changes**: OAuth mobile migration + JSON decoding fixes

---

## 📋 Quick Checklist

Before you commit:
- [x] OAuth fixes applied to `StravaAPI.swift`
- [x] Code tested on physical device
- [x] OAuth authorization works
- [x] Activities fetch successfully
- [ ] Strava API callback domain set to `localhost` (manual step)
- [ ] Ready to commit to Git
- [ ] Ready to upload to TestFlight

---

## 🔧 Step 1: Commit to Git

### Option A: Simple Commit (Recommended)

```bash
# Navigate to your project directory
cd /path/to/DCC-Weekly-Activities

# Check what files changed
git status

# Add all changed files
git add .

# Commit with a clear message
git commit -m "Fix: OAuth mobile migration and JSON decoding errors

- Migrate to Strava mobile OAuth endpoint for better UX
- Fix invalid scope error (club:read → activity:read)
- Fix JSON decoding crashes (make fields optional)
- Remove invalid id field from decoder
- Add error logging for diagnostics

Fixes #[issue-number] if applicable"

# Push to GitHub
git push origin main
```

### Option B: Detailed Commit (For Documentation)

```bash
# Add files
git add StravaAPI.swift OAUTH_FIX_CHANGELOG.md GIT_COMMIT_GUIDE.md

# Commit with detailed message
git commit -m "feat: Fix OAuth flow and enable mobile authentication

BREAKING CHANGES:
- Migrate from web OAuth (/oauth/authorize) to mobile OAuth (/oauth/mobile/authorize)
- Update OAuth scope from 'read,club:read' to 'read,activity:read'

FIXES:
- Fix 'field scope code invalid' error during authorization
- Fix 'data from Strava could not be read' JSON decoding error
- Fix crashes on activities with missing/null fields (distance, speed, etc)
- Fix crashes due to missing 'id' field in club activities response

IMPROVEMENTS:
- Mobile OAuth deep-links into Strava app when installed
- Fallback to Safari if Strava app not available
- Better error diagnostics with raw JSON logging
- Support for sport_type field (newer Strava API)

TECHNICAL DETAILS:
- Made StravaActivityResponse fields optional (distance, moving_time, etc)
- Removed 'id' field (not present in club activities endpoint)
- Added defensive decoding with fallback values
- Enhanced error messages in catch blocks

FILES CHANGED:
- StravaAPI.swift: OAuth endpoint, scope, JSON decoder (40 lines)
- OAUTH_FIX_CHANGELOG.md: Comprehensive documentation (new file)
- GIT_COMMIT_GUIDE.md: Commit and deployment guide (new file)

TESTING:
- ✅ OAuth authorization succeeds
- ✅ Club activities fetch correctly  
- ✅ Handles edge cases (manual, indoor, partial data)
- ✅ No crashes with null/missing fields
- ✅ Tested on iOS 17+ physical device

MANUAL STEPS REQUIRED:
1. Update Strava API settings at https://www.strava.com/settings/api
2. Set 'Authorization Callback Domain' to 'localhost'
3. Verify redirect URI matches: dcc-activities://localhost/oauth/strava

Version: 1.0.1 (or 1.1.0 for minor release)
Platform: iOS 17.0+
Status: ✅ Ready for TestFlight"

# Push to remote
git push origin main
```

---

## 📊 Step 2: Verify GitHub Push

After pushing, verify on GitHub:

1. Go to your repository: `https://github.com/[username]/DCC-Weekly-Activities`
2. Check that latest commit shows your changes
3. Verify files updated:
   - ✅ `StravaAPI.swift`
   - ✅ `OAUTH_FIX_CHANGELOG.md` (new)
   - ✅ `GIT_COMMIT_GUIDE.md` (new)

---

## 🍎 Step 3: Update Version in Xcode

Before archiving for TestFlight:

### Update Version Number

1. Open your project in Xcode
2. Select project in Navigator (blue icon)
3. Select your app target
4. Go to **General** tab
5. Under **Identity**:
   - **Version**: Change to `1.0.1` (or `1.1.0`)
   - **Build**: Increment by 1 (e.g., `1` → `2`, or `23` → `24`)

### Quick Command (Alternative)
```bash
# Using agvtool (if enabled)
agvtool new-marketing-version 1.0.1
agvtool next-version -all
```

---

## 📦 Step 4: Archive for TestFlight

### In Xcode:

1. **Select Real Device or Generic iOS Device**
   - Top toolbar: Select "Any iOS Device (arm64)"
   - DO NOT use Simulator

2. **Clean Build Folder**
   ```
   Product → Clean Build Folder (⇧⌘K)
   ```

3. **Archive**
   ```
   Product → Archive (⌘B to build first if needed)
   ```
   - Wait for archive to complete (can take 2-5 minutes)

4. **Organizer Window Opens**
   - Shows your archives
   - Select the newest archive
   - Click **Distribute App**

5. **Distribution Options**
   - Select: **App Store Connect**
   - Click **Next**

6. **Distribution Method**
   - Select: **Upload**
   - Click **Next**

7. **App Store Connect Options**
   - ✅ Include bitcode (if available)
   - ✅ Upload symbols (for crash reports)
   - ✅ Manage version and build number
   - Click **Next**

8. **Signing**
   - Select: **Automatically manage signing**
   - Click **Next**
   - Review certificate info
   - Click **Upload**

9. **Wait for Upload**
   - Progress bar shows upload status
   - Usually takes 2-10 minutes depending on connection
   - ✅ "Upload Successful" message

---

## ⚡ Step 5: TestFlight Configuration

### In App Store Connect:

1. **Go to App Store Connect**
   - Visit: [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
   - Sign in with Apple ID

2. **Select Your App**
   - Click "My Apps"
   - Select "DCC Weekly Activities"

3. **Go to TestFlight Tab**
   - Wait 5-15 minutes for build to process
   - You'll get email when ready: "Your app is ready for testing"

4. **Add What's New Text (Release Notes)**
   ```
   OAuth Authentication Fixed
   
   ✅ Fixed login issues with Strava
   ✅ Improved authentication experience  
   ✅ Better handling of activity data
   ✅ More reliable data fetching
   
   Please try connecting your Strava account and verify club activities load correctly. Report any issues via TestFlight feedback!
   ```

5. **Add Internal Testers** (Skip if already added)
   - TestFlight → Internal Testing
   - Click "+" to add testers
   - Enter email addresses

6. **Add External Testers** (Optional)
   - TestFlight → External Testing
   - Create new group: "Beta Testers"
   - Add up to 10,000 testers
   - Requires Beta App Review (1-2 days)

7. **Enable Testing**
   - Select build
   - Click "Start Testing"
   - Testers receive email invitation

---

## 📱 Step 6: Test the TestFlight Build

### As a Tester:

1. **Install TestFlight App**
   - Download from App Store (if not installed)

2. **Accept Invitation**
   - Check email for invitation
   - Click "View in TestFlight"
   - Or enter code manually in TestFlight app

3. **Install Beta**
   - Open TestFlight app
   - Find "DCC Weekly Activities"
   - Tap "Install"

4. **Test Critical Flows**
   - ✅ Launch app
   - ✅ Tap "Connect with Strava"
   - ✅ Authorize with Strava (should deep-link to Strava app)
   - ✅ Return to app
   - ✅ Activities load successfully
   - ✅ No crashes
   - ✅ Charts display correctly

5. **Provide Feedback**
   - TestFlight → App → "Send Beta Feedback"
   - Include screenshots if issues found

---

## 🐛 Troubleshooting

### Common Issues

#### Issue: `git push` fails with "permission denied"
**Solution**:
```bash
# Set up SSH key or use HTTPS with personal access token
git remote set-url origin https://github.com/[username]/DCC-Weekly-Activities.git

# Or configure SSH
ssh-keygen -t ed25519 -C "your_email@example.com"
# Add ~/.ssh/id_ed25519.pub to GitHub Settings → SSH Keys
```

#### Issue: Archive fails with signing error
**Solution**:
1. Xcode → Settings → Accounts
2. Verify Apple ID is signed in
3. Download manual profiles if needed
4. Try "Automatically manage signing"

#### Issue: Upload fails with "Invalid binary"
**Solution**:
1. Check minimum iOS version (should be 17.0+)
2. Verify all required icons are present
3. Check Info.plist for errors
4. Clean build folder and try again

#### Issue: Build stuck on "Processing" in App Store Connect
**Solution**:
- Normal processing time: 5-15 minutes
- If > 30 minutes, check email for issues
- May need to re-upload if processing fails

#### Issue: TestFlight beta review rejection
**Solution**:
1. Read rejection email carefully
2. Common issues:
   - Missing NSFaceIDUsageDescription
   - Crashes on launch
   - Missing features described
3. Fix issue and resubmit

---

## ✅ Success Checklist

After completing all steps:

- [x] Changes committed to Git
- [x] Pushed to GitHub successfully
- [x] Version number updated (1.0.1 or 1.1.0)
- [x] Build number incremented
- [x] App archived successfully
- [x] Uploaded to App Store Connect
- [x] Build processing complete
- [x] TestFlight configured with release notes
- [x] Internal testers added
- [x] Build available for testing
- [x] Tested personally and confirmed working
- [x] OAuth authorization works
- [x] Activities load correctly

---

## 📋 Git Command Quick Reference

```bash
# Check status
git status

# See what changed
git diff

# Add all changes
git add .

# Add specific files
git add StravaAPI.swift OAUTH_FIX_CHANGELOG.md

# Commit
git commit -m "Your message here"

# Push to main branch
git push origin main

# View commit history
git log --oneline

# Create a tag for this release
git tag -a v1.0.1 -m "OAuth fixes and mobile migration"
git push origin v1.0.1

# If you need to undo (CAREFUL!)
git reset --soft HEAD~1  # Undo last commit, keep changes
git reset --hard HEAD~1  # Undo last commit, discard changes
```

---

## 🎯 Quick Commands Summary

### Full Flow (Copy-Paste Friendly)

```bash
# 1. Commit changes
cd /path/to/your/project
git add .
git commit -m "Fix: OAuth mobile migration and JSON decoding"
git push origin main

# 2. Create release tag
git tag -a v1.0.1 -m "OAuth fixes - ready for TestFlight"
git push origin v1.0.1

# 3. Open Xcode to archive
open DCC-Weekly-Activities.xcodeproj

# Then follow Xcode steps above for archiving
```

---

## 📞 Need Help?

### Resources

1. **Git Issues**
   - [GitHub Docs](https://docs.github.com)
   - [Git Documentation](https://git-scm.com/doc)

2. **Xcode/TestFlight Issues**
   - [Apple Developer Documentation](https://developer.apple.com/documentation/)
   - [TestFlight Help](https://developer.apple.com/testflight/)
   - [App Store Connect Help](https://help.apple.com/app-store-connect/)

3. **Common Error Messages**
   - Google the exact error message
   - Check Stack Overflow
   - Review Apple Developer Forums

---

## 🎉 After Successful Upload

### Celebrate! 🎊

You've successfully:
✅ Fixed critical OAuth bugs  
✅ Committed changes to Git  
✅ Pushed to GitHub  
✅ Uploaded to TestFlight  
✅ Made app usable again  

### Next Steps:

1. **Monitor TestFlight**
   - Check crash reports daily
   - Review beta feedback
   - Respond to tester questions

2. **Plan Next Release**
   - Any new features?
   - Performance improvements?
   - UI enhancements?

3. **Prepare for App Store**
   - Review APP_STORE_CHECKLIST.md
   - Prepare screenshots
   - Write app description
   - Submit for review

---

## 📊 Timeline

**Estimated time for this entire process:**

- ⏱️ Git commit: 5 minutes
- ⏱️ Xcode archive: 5-10 minutes
- ⏱️ Upload to App Store Connect: 5-15 minutes
- ⏱️ Processing: 10-30 minutes
- ⏱️ TestFlight configuration: 5 minutes

**Total: 30-60 minutes** ⏰

---

**You're all set! Start with Step 1 and work through the checklist.** 🚀

**Good luck with your TestFlight release!** 🎊

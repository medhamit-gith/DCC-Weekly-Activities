# 📋 Quick Reference Card — v1.0.1 Release

**Print this or keep it open while deploying!**

---

## ⚡ 5-Minute Overview

### What Changed?
- ✅ Fixed OAuth "invalid scope" error
- ✅ Fixed JSON decoding crashes
- ✅ Migrated to mobile OAuth flow

### What You Need to Do?
1. Update Strava callback domain to `localhost`
2. Commit changes to Git
3. Upload to TestFlight
4. Test and verify

### How Long?
**~90 minutes total**

---

## 🚨 CRITICAL: Do This FIRST

### Update Strava API Settings

**URL**: https://www.strava.com/settings/api

**What to change**:
- Field: "Authorization Callback Domain"
- Old value: (anything else)
- New value: **localhost**
- Action: Click "Update"

**This is mandatory or OAuth will fail!**

---

## 📝 Git Commands (Copy-Paste)

```bash
# Navigate to project
cd /path/to/DCC-Weekly-Activities

# Add all changes
git add .

# Commit
git commit -m "Fix: OAuth mobile migration and JSON decoding

- Migrate to Strava mobile OAuth endpoint
- Fix invalid scope (club:read → activity:read)
- Fix JSON decoding crashes (optional fields)
- Remove invalid id field from decoder
- Add comprehensive error logging

Version: 1.0.1"

# Push
git push origin main

# Tag (optional)
git tag -a v1.0.1 -m "OAuth fixes"
git push origin v1.0.1
```

---

## 🍎 Xcode Checklist

### Version Update
1. Open project in Xcode
2. Select project (blue icon)
3. Select app target
4. General tab → Identity section
5. Version: **1.0.1**
6. Build: Increment by 1

### Archive & Upload
1. Select: **Any iOS Device (arm64)**
2. Product → Clean Build Folder (⇧⌘K)
3. Product → Archive
4. Wait 2-5 minutes
5. Organizer opens → Distribute App
6. Select: App Store Connect → Upload
7. Enable: ✅ Upload symbols
8. Click: Upload
9. Wait 5-15 minutes

---

## ✅ TestFlight Setup

### After Upload Processing

1. Go to appstoreconnect.apple.com
2. My Apps → DCC Weekly Activities
3. TestFlight tab
4. Wait for email: "Ready for testing"
5. Add build to Internal Testing
6. Write release notes (see below)
7. Add testers (yourself first!)
8. Install and test

### Release Notes Template

```
OAuth Authentication Fixed — v1.0.1

🔧 FIXES:
• Fixed "field scope code invalid" error
• Fixed "data from Strava could not be read" error
• Improved OAuth with mobile flow
• Better handling of missing activity data

✅ PLEASE TEST:
1. Tap "Connect with Strava"
2. Authorize (may deep-link to Strava app)
3. Verify activities load
4. Report any issues via TestFlight feedback

Status: All critical bugs fixed
```

---

## 🧪 Testing Checklist

### Must Work
- [ ] App launches
- [ ] "Connect with Strava" button appears
- [ ] OAuth authorization completes
- [ ] Returns to app automatically
- [ ] Activities load
- [ ] Statistics display
- [ ] No crashes

### Should Work
- [ ] Pull-to-refresh
- [ ] All 3 view modes (Charts/Table/Activities)
- [ ] Data persists after restart

---

## 📞 Troubleshooting

### OAuth Fails
- ✅ Callback domain set to `localhost`?
- ✅ Using physical device (not Simulator)?
- ✅ Info.plist has `dcc-activities` URL scheme?

### Archive Fails
- ✅ Signing certificates valid?
- ✅ "Automatically manage signing" enabled?
- ✅ Correct team selected?

### Upload Fails
- ✅ Build configuration = Release?
- ✅ All required icons present?
- ✅ Info.plist complete?

### Processing Stuck
- Normal: 10-30 minutes
- If > 1 hour: Check email for errors
- May need to re-upload

---

## 📚 Documentation Map

**Overwhelmed? Read in this order:**

1. **RELEASE_SUMMARY.md** (5 min read)
   - Executive overview
   - What changed and why
   
2. **TESTFLIGHT_RELEASE_CHECKLIST.md** (15 min read)
   - Complete step-by-step process
   - Everything you need to do
   
3. **GIT_COMMIT_GUIDE.md** (Reference)
   - Detailed Git instructions
   - Troubleshooting guide
   
4. **OAUTH_FIX_CHANGELOG.md** (Technical)
   - Deep technical details
   - Before/after code

---

## ⏱️ Time Estimates

| Task | Duration |
|------|----------|
| Strava API update | 2 min |
| Git commit | 5 min |
| Xcode version update | 3 min |
| Archive | 5 min |
| Upload | 10 min |
| Processing wait | 15-30 min |
| TestFlight config | 10 min |
| Install & test | 15 min |
| **TOTAL** | **~65-90 min** |

---

## 🎯 Success = All Green

- ✅ OAuth authorization works
- ✅ Activities load without errors
- ✅ No crashes
- ✅ Charts display correctly
- ✅ Tested by 3+ people

---

## 📊 Version Info

**Current Version**: 1.0.1  
**Previous Version**: 1.0.0  
**Release Type**: Bug Fix  
**Priority**: Critical  
**Status**: Ready for TestFlight

---

## 🚀 Deploy Command

**If you're ready RIGHT NOW:**

```bash
# 1. Update Strava settings (manually)
open https://www.strava.com/settings/api

# 2. Commit to Git (5 min)
cd /path/to/project
git add .
git commit -m "Fix: OAuth mobile migration and JSON decoding"
git push origin main

# 3. Open Xcode (then follow archive steps above)
open DCC-Weekly-Activities.xcodeproj
```

---

## ✨ Post-Deployment

### Immediately After Upload
- [ ] Verify build appears in App Store Connect
- [ ] Wait for processing email
- [ ] Test build yourself first
- [ ] Then invite other testers

### Within 24 Hours
- [ ] Check crash reports
- [ ] Review tester feedback
- [ ] Fix critical bugs if found
- [ ] Upload v1.0.2 if needed

### Within 1 Week
- [ ] Gather feedback from 5+ testers
- [ ] Verify OAuth works for everyone
- [ ] Plan next release (v1.1)
- [ ] Prepare for App Store submission

---

## 🎉 You're Ready!

**Everything you need:**
- ✅ Code is fixed
- ✅ Documentation complete
- ✅ Process documented
- ✅ Troubleshooting covered

**Start here**: `TESTFLIGHT_RELEASE_CHECKLIST.md`

**Let's ship it!** 🚀

---

## 📞 Help Resources

**Apple**: developer.apple.com  
**Strava**: developers.strava.com  
**Git**: git-scm.com/doc  
**Stack Overflow**: stackoverflow.com

---

**Bookmark this page!**  
**Good luck!** 💪

---

```
┌─────────────────────────────────────────┐
│  DCC WEEKLY ACTIVITIES v1.0.1           │
│  OAuth Fix Release                       │
│  Status: ✅ Ready for TestFlight        │
│  ETA: ~90 minutes                        │
└─────────────────────────────────────────┘
```

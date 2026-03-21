# OAuth Debugging Guide - Simulator Issues
## DCC Weekly Activities - March 5, 2026

---

## 🔍 CHANGES MADE FOR DEBUGGING

### Added Detailed Logging To:

1. **GlassWelcomeCard.swift** (button tap)
2. **StravaAPI.swift** (OAuth flow)

---

## 📋 HOW TO DEBUG

### Step 1: Clean & Rebuild

```bash
1. Product → Clean Build Folder (⌘⇧K)
2. Delete Derived Data:
   - Xcode → Settings → Locations → Derived Data → Arrow icon
   - Delete DCC-Weekly-Activities folder
3. Close and reopen Xcode
4. Build (⌘B)
```

### Step 2: Run in Simulator

```bash
1. Select iPhone 15 Pro simulator
2. Run app (⌘R)
3. Wait for app to load
4. Open Debug Console: View → Debug Area → Show Debug Area (⌘⇧Y)
```

### Step 3: Test OAuth Flow

```bash
1. App shows login screen
2. Click "Connect with Strava" button
3. Watch console output
```

---

## 🎯 EXPECTED CONSOLE OUTPUT

### **If Everything Works:**

```
🎯 [UI] Connect button tapped
✅ [UI] onConnect() called
🚀 [OAuth] Starting OAuth flow...
📋 [OAuth] Client ID: 161984
🔗 [OAuth] Redirect URI: dcc-activities://localhost/oauth/strava
🌐 [OAuth] Authorization URL: https://www.strava.com/oauth/mobile/authorize?client_id=161984&response_type=code&redirect_uri=dcc-activities://localhost/oauth/strava&approval_prompt=auto&scope=read,activity:read
🎬 [OAuth] Starting ASWebAuthenticationSession...
✅ [OAuth] Session started and stored
```

Then Safari/browser should open with Strava login page.

---

## ❌ COMMON ERRORS & SOLUTIONS

### **ERROR 1: Nothing in Console**

**Symptoms:**
```
(no output at all)
```

**Possible Causes:**
1. Button not actually being tapped
2. Console filter hiding output
3. App crashed silently

**Solutions:**
- Check Console filter (should be "All Output")
- Try clicking button multiple times
- Check device log for crashes

---

### **ERROR 2: "Invalid URL Scheme"**

**Symptoms:**
```
❌ [OAuth] Error code: 1000
❌ [OAuth] Error domain: com.apple.AuthenticationServices.WebAuthenticationSession
```

**Cause:** URL scheme not registered in Info.plist

**Solution:**
1. Xcode → Target → Info tab
2. Add URL Types → `dcc-activities`
3. Rebuild

---

### **ERROR 3: "The operation couldn't be completed"**

**Symptoms:**
```
❌ [OAuth] Error: The operation couldn't be completed
❌ [OAuth] Error code: 1
```

**Cause:** ASWebAuthenticationSession doesn't work well in simulator

**Solution:**
✅ **TEST ON REAL DEVICE INSTEAD**

This is expected - OAuth works on devices, not simulators!

---

### **ERROR 4: Session Starts But Nothing Happens**

**Symptoms:**
```
✅ [OAuth] Session started and stored
(then nothing)
```

**Cause:** Simulator limitation - can't open Safari/authentication

**Solution:**
✅ **THIS IS NORMAL IN SIMULATOR**
Test on real device for full OAuth flow

---

### **ERROR 5: "Callback URL is nil"**

**Symptoms:**
```
❌ [OAuth] Callback URL is nil
```

**Cause:** Redirect didn't work or URL scheme not registered

**Solution:**
1. Verify URL scheme in Info.plist
2. Check redirect URI matches Strava dashboard
3. Test on real device

---

## 🚨 SIMULATOR VS DEVICE BEHAVIOR

### **Simulator (Limited):**
- ❌ OAuth often fails silently
- ❌ Can't open external apps
- ❌ May not show ASWebAuthenticationSession
- ✅ Good for UI testing only

### **Real Device (Full Functionality):**
- ✅ OAuth works perfectly
- ✅ Opens Safari or Strava app
- ✅ Completes full flow
- ✅ Redirects back to app

---

## 🎯 INTERPRETATION GUIDE

### **Scenario A: See 🎯 but nothing after**

**What you see:**
```
🎯 [UI] Connect button tapped
✅ [UI] onConnect() called
```

**Meaning:** Button works, but OAuth not starting

**Action:** Check StravaAPI.shared is initialized

---

### **Scenario B: See 🚀 but error immediately**

**What you see:**
```
🚀 [OAuth] Starting OAuth flow...
❌ [OAuth] Error: ...
```

**Meaning:** OAuth trying to start but failing

**Action:** Read specific error message and follow solutions above

---

### **Scenario C: See ✅ Session started but nothing**

**What you see:**
```
✅ [OAuth] Session started and stored
(nothing else)
```

**Meaning:** This is NORMAL in simulator!

**Action:** 
✅ Test on real device
✅ This is expected simulator behavior

---

### **Scenario D: See 📥 Callback received**

**What you see:**
```
📥 [OAuth] Callback received
✅ [OAuth] Callback URL: dcc-activities://localhost/oauth/strava?code=...
```

**Meaning:** ✅ **SUCCESS!** OAuth working perfectly!

**Action:** Continue testing, this is perfect!

---

## 🔧 QUICK FIXES

### Fix 1: Simulator Doesn't Support OAuth

**Problem:** ASWebAuthenticationSession doesn't work in simulator

**Solution:**
```
STOP trying to test OAuth in simulator!

Instead:
1. Connect real iPhone via USB
2. Select your device in Xcode
3. Run app on device (⌘R)
4. Test OAuth flow
```

---

### Fix 2: URL Scheme Not Registered

**Check:**
```bash
1. Xcode → Select Target
2. Info tab
3. Look for "URL Types"
4. Should see: dcc-activities
```

**If missing:**
```bash
1. Click + to add URL Type
2. Identifier: com.dcc.weeklyactivities
3. URL Schemes: dcc-activities
4. Role: Editor
5. Rebuild
```

---

### Fix 3: Strava Config Issues

**Verify in StravaAPI.swift:**

```swift
static let clientID = "161984"    // ✅ Should be your client ID
static let redirectURI = "dcc-activities://localhost/oauth/strava"  // ✅ Must match Strava dashboard
```

**Check Strava Dashboard:**
1. Go to: https://www.strava.com/settings/api
2. Find your app
3. Verify "Authorization Callback Domain" = `localhost`
4. Save if changed

---

## ✅ RECOMMENDED TESTING FLOW

### **For Development (Now):**

1. ✅ Test UI in simulator (button works?)
2. ✅ Check console logs
3. ❌ Don't expect OAuth to complete in simulator
4. ✅ Test full OAuth on REAL DEVICE

### **For App Store Submission:**

1. ✅ Test on real iPhone with Face ID
2. ✅ Complete full OAuth flow
3. ✅ Verify Face ID prompt shows
4. ✅ Verify data loads
5. ✅ Then archive and submit

---

## 📱 TESTING ON REAL DEVICE

### **How to test on your iPhone:**

```bash
1. Connect iPhone to Mac via USB
2. Unlock iPhone
3. Xcode → Select your iPhone from device dropdown
4. Click "Trust This Computer" on iPhone
5. Run app (⌘R)
6. App installs and launches on iPhone
7. Tap "Connect with Strava"
8. Safari opens with Strava login
9. Log in → Grant permissions
10. Redirects back to your app ✅
```

---

## 🎯 WHAT TO DO RIGHT NOW

### **Immediate Action:**

1. **Build and run** with the new debug logging
2. **Tap "Connect with Strava"**
3. **Check console output**
4. **Report back what you see:**
   - Scenario A, B, C, or D?
   - Specific error message?
   - Or working perfectly?

---

## 📊 DECISION TREE

```
Click Connect Button
├─ See 🎯 in console?
│  ├─ NO → Button not wired correctly (shouldn't happen)
│  └─ YES → Continue
│
├─ See 🚀 in console?
│  ├─ NO → StravaAPI not being called
│  └─ YES → Continue
│
├─ See ❌ Error?
│  ├─ YES → Read error, apply fix from above
│  └─ NO → Continue
│
├─ See ✅ Session started?
│  ├─ YES, nothing after → NORMAL for simulator, test on device
│  └─ NO → Check console for crash
│
└─ See 📥 Callback?
   ├─ YES → SUCCESS! OAuth working!
   └─ NO → Expected in simulator, test on device
```

---

## 🚀 NEXT STEPS

**After reviewing console output:**

1. If you see errors → Apply fixes above
2. If you see "Session started" but nothing → Test on real device
3. If you see callback → Everything working!

**For submission:**
- Archive and upload must be tested on real device
- Simulator is NOT sufficient for App Store
- Apple reviewers use real devices

---

**Now run the app and tell me what you see in the console!** 🔍

---

*Debugging guide created: March 5, 2026*  
*Added comprehensive logging to OAuth flow*

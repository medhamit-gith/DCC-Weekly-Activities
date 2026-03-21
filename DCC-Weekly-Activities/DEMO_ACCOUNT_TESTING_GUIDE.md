# Testing with Demo Account - Complete Guide
## DCC Weekly Activities - March 5, 2026

---

## ✅ GREAT NEWS!

OAuth is working on your iPhone! 🎉

Now let's test with the demo account.

---

## 🔄 THREE WAYS TO SWITCH ACCOUNTS

### **METHOD 1: Delete & Reinstall (FASTEST - 30 seconds)**

**Best for:** Quick testing, clean slate

```bash
1. On iPhone:
   - Find DCC Weekly app
   - Long-press app icon
   - Tap "Remove App"
   - Tap "Delete App"
   
2. In Xcode:
   - iPhone still selected in device dropdown
   - Click Run (⌘R)
   - App reinstalls fresh
   
3. On iPhone:
   - App opens to login screen
   - Tap "Connect with Strava"
   - Safari opens Strava login
   
4. Log in with DEMO ACCOUNT:
   Username: [your-demo-email@example.com]
   Password: [your-demo-password]
   
5. Grant permissions
6. Safari redirects back to app ✅
7. See demo account data!
```

**Why this is fastest:**
- Clears all Keychain data
- No settings to change
- Fresh install every time
- Takes 30 seconds

---

### **METHOD 2: Use New Logout Menu (EASIEST - 10 seconds)**

**I just added a logout option!**

```bash
1. In Xcode: Rebuild app (⌘B)
2. Run on iPhone (⌘R)
3. On iPhone:
   - Tap profile icon (top right - your initial)
   - Menu appears with two options
   - Tap "Log Out" (red text)
   - Confirm
4. App returns to login screen
5. Tap "Connect with Strava"
6. Log in with demo account
7. Done! ✅
```

**How the new menu works:**
- **Tap** profile icon → Opens menu
- **Performance Stats** → Opens performance dashboard (old behavior)
- **Log Out** → Logs out and returns to login screen (NEW!)

---

### **METHOD 3: Clear Safari Data (SLOWER - 2 minutes)**

**Best for:** Testing OAuth flow from scratch

```bash
1. On iPhone, open Settings app
2. Scroll down → Safari
3. Tap "Clear History and Website Data"
4. Tap "Clear History and Data" (confirm)
5. Delete DCC Weekly app
6. Reinstall from Xcode
7. Log in with demo account
```

**Why this works:**
- Clears Safari cookies
- Removes Strava session
- Forces fresh OAuth login

---

## 🎯 RECOMMENDED: Use Method 1 or 2

### **For Testing Demo Account NOW:**

**Use Method 1 (Delete & Reinstall):**
```
Time: 30 seconds
Steps: Delete app → Run in Xcode → Login with demo
Result: Fresh install, guaranteed clean state
```

### **For Future Account Switching:**

**Use Method 2 (Logout Menu):**
```
Time: 10 seconds
Steps: Tap profile → Log Out → Login with different account
Result: Quick switching between accounts
```

---

## 📋 TESTING CHECKLIST WITH DEMO ACCOUNT

Once logged in with demo account, verify:

### **Login & Authentication:**
- [x] OAuth worked on real device
- [ ] Logged in with demo account credentials
- [ ] Face ID prompt appeared (with your description)
- [ ] Successfully authenticated with Face ID
- [ ] App loaded dashboard

### **Data Display:**
- [ ] Dashboard shows club statistics
- [ ] Hero number shows total club distance
- [ ] Quick stats cards show data
- [ ] Leaderboard shows DCC members
- [ ] Demo account appears in leaderboard (if has activities)

### **Personal Tabs:**
- [ ] Insights tab works (shows demo account data if has activities)
- [ ] Analysis tab works (shows demo account analysis if has activities)
- [ ] Overview tab shows club data
- [ ] Leaders tab shows full rankings

### **Navigation:**
- [ ] All tabs switchable
- [ ] Animated cyclist visible in header (home button)
- [ ] Profile menu works (tap to open)
- [ ] Logout works (returns to login screen)

---

## 🧪 TESTING SCENARIOS

### **Scenario 1: Demo Account WITH Activities**

**If your demo account has logged activities this week:**

✅ **Expected behavior:**
```
Dashboard:
- ✅ Club totals show
- ✅ Leaderboard includes demo account
- ✅ Demo account ranked by distance

Insights tab:
- ✅ Shows demo account's stats
- ✅ Personal distance, rides, elevation
- ✅ Week-over-week comparison (if week 2+)

Analysis tab:
- ✅ Shows demo account's trends
- ✅ Performance charts
```

### **Scenario 2: Demo Account WITHOUT Activities**

**If demo account has NO activities yet:**

✅ **Expected behavior:**
```
Dashboard:
- ✅ Club totals show (other members)
- ✅ Leaderboard shows other DCC members
- ❌ Demo account NOT in leaderboard (no rides)

Insights tab:
- ⚠️ Shows "No activities" empty state
- OR shows minimal data

Analysis tab:
- ⚠️ Shows "No data" empty state
```

**This is OKAY for App Review** as long as you explain in notes:
"Demo account may have limited activities. App displays club-wide data correctly."

---

## 📸 TAKE SCREENSHOTS WITH DEMO ACCOUNT

**While logged in with demo account:**

### **Screenshot 1: Dashboard**
```
1. Navigate to Main tab (home icon)
2. Ensure data is visible
3. iPhone → Side button + Volume Up
4. Screenshot saved to Photos
```

### **Screenshot 2: Leaderboard**
```
1. Tap Leaders tab
2. Shows podium and rankings
3. Take screenshot
```

### **Screenshot 3: Insights**
```
1. Tap Insights tab
2. Shows personal data (if available)
3. Take screenshot
```

### **Screenshot 4: Login Screen**
```
1. Logout (profile menu → Log Out)
2. Shows glass welcome card
3. Take screenshot
```

**Transfer screenshots to Mac:**
```
1. AirDrop to Mac
2. OR connect iPhone via USB
3. Import to Mac
4. Upload to App Store Connect
```

---

## ⚠️ IMPORTANT: VERIFY DEMO ACCOUNT BEFORE SUBMISSION

### **Demo Account Verification Checklist:**

Before submitting to App Store:

- [ ] Demo account email/password written down
- [ ] Demo account IS member of DCC club (verified on strava.com)
- [ ] Demo account has 2-3 activities (recommended)
- [ ] Can login successfully on your iPhone
- [ ] Face ID works after login
- [ ] Data loads correctly
- [ ] No errors or crashes

### **Test Demo Account One More Time:**

```bash
1. Delete app from iPhone
2. Run fresh install
3. Login with demo account
4. Verify everything works
5. Take screenshots
6. Write down any issues
```

---

## 🎯 READY FOR APP STORE?

**After testing with demo account:**

### **If Everything Works:**

✅ **Proceed to archive:**
```
1. In Xcode, select "Any iOS Device (arm64)"
2. Product → Archive
3. Wait for archive to complete
4. Validate
5. Upload to App Store Connect
```

### **If Something Doesn't Work:**

❌ **Debug first:**
```
1. Check console logs for errors
2. Verify demo account is DCC member
3. Test OAuth flow again
4. Fix issues before archiving
```

---

## 💡 PRO TIPS

### **Tip 1: Keep Demo Account Active**

```
Every few weeks:
- Log in to demo account on strava.com
- Add a manual activity
- Keeps account active
- Prevents Strava from deactivating
```

### **Tip 2: Save Demo Credentials**

```
Create note file:
---
DCC Weekly - Demo Account
Email: demo@example.com
Password: DemoPassword123
Created: March 5, 2026
Status: Active, DCC member
Last tested: [Date]
---
```

### **Tip 3: Test Multiple Scenarios**

```
Before submission:
1. Test with demo account (fresh install)
2. Test logout → login again
3. Test Face ID multiple times
4. Test each tab
5. Check for any crashes
```

---

## 🚀 NEXT STEPS

### **After Testing with Demo Account:**

1. ✅ Verified demo account works
2. ✅ Took screenshots
3. ✅ Noted any issues
4. ✅ Ready to archive

### **Then:**

```
1. Archive app (see APP_STORE_SUBMISSION_GUIDE.md)
2. Upload to App Store Connect
3. Fill in demo account credentials
4. Submit for review
```

---

## 📞 TROUBLESHOOTING

### **"Demo account login works but no data"**

**Check:**
- Is demo account member of DCC club?
- Go to strava.com → Clubs → Desi Cycling Club
- Verify demo account in member list

### **"Demo account shows 403 error"**

**Fix:**
- You hit API limit
- Use Method 1 (delete/reinstall)
- OR wait 15 minutes
- OR use your personal account for demo

### **"Can't see logout menu"**

**Fix:**
1. Rebuild app in Xcode (⌘B)
2. Run on iPhone (⌘R)
3. Tap profile icon (should show menu)
4. If not, use Method 1 (delete/reinstall)

---

## ✅ YOU'RE READY!

**Once you've tested with demo account and everything works:**

🎉 **You're ready to submit to App Store!**

Follow **APP_STORE_SUBMISSION_GUIDE.md** for the rest.

---

*Testing guide created: March 5, 2026*  
*Added logout menu for easy account switching*

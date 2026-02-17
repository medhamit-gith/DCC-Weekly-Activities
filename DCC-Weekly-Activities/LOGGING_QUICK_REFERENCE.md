# Quick Logging Reference Card

## 🚀 Quick Start

### tvOS Simulator
```bash
1. Xcode → Select "DCC Weekly Activities TV" scheme
2. Cmd+R to run
3. Cmd+Shift+Y to show console
4. Type "📺" in filter box
5. Watch logs appear
```

### iOS Simulator
```bash
1. Xcode → Select "DCC Weekly Activities" scheme
2. Cmd+R to run
3. Cmd+Shift+Y to show console
4. Type "📱" in filter box
5. Watch logs appear
```

---

## 🔍 What to Look For

### ✅ Success Pattern (tvOS)
```
🚀 TV APP INIT
🎬 ContentView INIT - Platform: tvOS
📺 onAppear fired
📺 ⚡ .task executing
📺 ✅ Conditions met
📺 🧪 loadMockData called
📺 ✅ Mock data loaded: 15 activities, 8 members
📺 ✅ TabView appeared
```

### ✅ Success Pattern (iOS)
```
🎬 ContentView INIT - Platform: iOS
📱 onAppear fired
📱 ⚡ .task fired
📱 🔐 Biometric type: Face ID
📱 🔑 Token found
📱 🔐 Auth result: SUCCESS
📱 🌐 fetchClubActivities called
📱 ✅ API call succeeded!
📱 ✅ Activities loaded
```

### ❌ Common Failures

#### tvOS: Task Never Fires
```
📺 onAppear fired
[... nothing else ...]

FIX: Check task modifier exists in tvOSContent
```

#### tvOS: Conditions Not Met
```
📺 ⚡ .task executing
📺 ⚠️  Skipping auto-load:
📺    - activities.isEmpty: false

FIX: Reset simulator or clean build
```

#### iOS: No Internet
```
📱 🌐 fetchClubActivities called
📱 ❌ ERROR
📱 URLError Code: -1009

FIX: Enable WiFi/cellular
```

#### iOS: Token Expired
```
📱 ❌ ERROR
📱 Error: Unauthorized [401]

FIX: Log out and log in again
```

---

## 📊 Key Log Sections

### State Dumps
```
📺 📊 Current state:
📺    - activities.count: 15
📺    - memberStats.count: 8
📺    - isLoading: false
📺    - errorMessage: nil
```

**What it means:** Complete snapshot of app state

### Before/After Comparison
```
📺 📊 BEFORE loading:
📺    - activities.count: 0
[... operation ...]
📺 📊 AFTER loading:
📺    - activities.count: 15
```

**What it means:** Shows data changes clearly

### Operation Sections
```
📺 ═══════════════════════════════════════
📺 🧪 loadMockData() called
📺 ═══════════════════════════════════════
[... detailed logs ...]
📺 ═══════════════════════════════════════
📺 ✅ Mock data loaded successfully!
📺 ═══════════════════════════════════════
```

**What it means:** Clear operation boundaries

---

## 🎯 Emoji Cheat Sheet

### Platforms
- 📱 = iOS logs
- 📺 = tvOS logs
- 🎬 = Both platforms (init)

### Status
- ✅ = Success
- ❌ = Error
- ⚠️ = Warning
- ℹ️ = Info

### Operations
- ⚡ = Task started
- 🌐 = Network call
- 🔐 = Auth/security
- 🧪 = Mock data
- 🔄 = Processing
- 💾 = State update

### UI
- 🎨 = View rendering
- 🏗️ = View building
- 📐 = Body evaluated

### Data
- 📊 = Statistics
- 📦 = Data received
- 👥 = Member info

### Time
- ⏳ = Loading/waiting
- ⏰ = Timing info

---

## 🛠️ Debug Commands

### Filter Console
```
📺     → tvOS logs only
📱     → iOS logs only
❌     → Errors only
✅     → Successes only
⚡     → Async tasks only
🌐     → Network only
```

### Clear Console
```
Cmd+K  → Clear all logs
```

### Save Logs
```
Right-click in console → Save Selected Text
```

---

## 📋 Troubleshooting Checklist

### tvOS Not Working?

1. [ ] See `🚀 TV APP INIT`?
   - No → Wrong target/scheme
   
2. [ ] See `📺 onAppear fired`?
   - No → View never appeared
   
3. [ ] See `📺 ⚡ .task executing`?
   - No → Task modifier issue
   
4. [ ] See `📺 ✅ Conditions met`?
   - No → Check state values in logs
   
5. [ ] See `📺 ✅ Mock data loaded`?
   - No → Loading crashed mid-way
   
6. [ ] Final count shows `15 activities, 8 members`?
   - No → State not updating
   
7. [ ] See `📺 ✅ TabView appeared`?
   - No → Rendering issue

### iOS Not Working?

1. [ ] Token loaded or login shown?
   - Check for `🔑 Token found` or `ℹ️  No token`
   
2. [ ] Biometric worked?
   - Check for `🔐 Auth result: SUCCESS`
   
3. [ ] Network call succeeded?
   - Check for `🌐 API call succeeded`
   
4. [ ] Data processed?
   - Check for `🔄 aggregateMemberStats()`
   
5. [ ] Final state correct?
   - Check `📊 Final state` logs

---

## 💡 Pro Tips

### Tip 1: Timestamps Matter
Big gaps = something is stuck:
```
📺 10:00:01 ⏰ Simulating delay...
📺 10:00:11 ⏰ Delay completed  ← Should be 10:00:02!
```

### Tip 2: Copy Section Blocks
When reporting issues, copy from `═══` to `═══`:
```
📺 ═══════════════════════════════════════
📺 🧪 loadMockData() called
[... complete operation ...]
📺 ═══════════════════════════════════════
```

### Tip 3: Watch State Changes
Every `💾` should trigger view re-render

### Tip 4: Count Success Markers
Each operation should have:
- Start (⚡ or 🧪)
- Progress (⏳, 📦)
- End (✅ or ❌)

Missing end = operation didn't complete

### Tip 5: Filter Strategically
Too many logs? Filter by:
- Error phase: `❌`
- Success phase: `✅`
- Operation: `🧪` or `🌐`

---

## 🎓 Common Scenarios

### Scenario 1: "Nothing in Console"

**Check:**
1. Console open? (Cmd+Shift+Y)
2. Filter box empty or has emoji?
3. Correct simulator running?
4. Clean build? (Cmd+Shift+K)

### Scenario 2: "Data Loads But Screen Blank"

**Look for:**
```
📺 ✅ Mock data loaded: 15 activities
[... later ...]
📺 🎨 tvMainContent building...
📺 🎨    - activities.count: 0  ← WRONG!
```

**Means:** State update failed

### Scenario 3: "Logs Stop Mid-Operation"

**Example:**
```
📺 🧪 loadMockData called
📺 ⏰ Simulating delay...
[... nothing else ...]
```

**Means:** Task crashed or cancelled

### Scenario 4: "Error But No Details"

**Look for:**
```
📱 ❌❌❌ ERROR
📱 Error type: URLError
📱 🌐 URLError details:
📱    - Code: -1009
```

**Gives:** Specific error code to Google

---

## 📞 When to Report Issue

If you see **all of these**:

✅ Correct simulator running  
✅ Build successful  
✅ Logs show data loaded  
✅ State values correct  
❌ But screen still blank  

**Then:** Save full console log and report

Include:
1. Platform (iOS/tvOS)
2. Simulator model
3. Xcode version
4. Full console log (filtered by 📺 or 📱)
5. Screenshot of blank screen

---

## 🆘 Emergency Debug

If totally stuck:

```bash
1. Product → Clean Build Folder (Cmd+Shift+K)
2. Close Xcode
3. Delete DerivedData:
   rm -rf ~/Library/Developer/Xcode/DerivedData
4. Restart Xcode
5. Open project
6. Run again
7. Watch console from start
```

---

## ✅ Success Indicators

### tvOS Working:
```
✅ 15 activities
✅ 8 members  
✅ TabView appeared
✅ Stats tab showing
✅ Can switch tabs
```

### iOS Working:
```
✅ Login shown OR biometric prompt
✅ Can authenticate
✅ Data loads
✅ Dashboard showing
✅ Can refresh
```

---

## 📚 Full Documentation

For complete details:
- `LOGGING_GUIDE.md` - Full interpretation guide
- `LOGGING_IMPROVEMENTS_SUMMARY.md` - All changes made
- `TVOS_COMPLETE_FIX.md` - tvOS technical details

---

**Remember:** Logs are your friend! They show exactly what's happening, when, and why. 🚀

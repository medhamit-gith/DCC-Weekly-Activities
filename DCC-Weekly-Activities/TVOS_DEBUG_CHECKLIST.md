# tvOS Debug Checklist

## Problem
The tvOS simulator shows blank screen with "Select an item" message and NO console output.

## Changes Made
1. ✅ Set `TestData.useMockData = true` by default on tvOS
2. ✅ Added extensive debug logging throughout the app
3. ✅ Added init() to ContentView with print
4. ✅ Added init() and debug logs to TV App

## What to Check

### 1. Are you running the correct target?
- In Xcode, check the target selector at the top
- It should say **"DCC Weekly Activities TV"** (not "DCC-Weekly-Activities")
- The destination should be an Apple TV simulator

### 2. Check the Scheme
- Product > Scheme > Make sure "DCC Weekly Activities TV" is selected
- Edit Scheme > Run > Build Configuration should be "Debug"

### 3. Look for Build Errors
- Open the Report Navigator (⌘9)
- Check for any build errors or warnings
- Look for red/yellow indicators

### 4. Check Console Output Location
- Make sure the console is visible (View > Debug Area > Show Debug Area, or ⌘⇧Y)
- Check the filter settings - make sure it says "All Output" not just "Errors"
- Try Product > Clean Build Folder (⌘⇧K) then rebuild

### 5. Verify Target Membership
These files MUST be in the TV target:
- ContentView.swift
- TestData.swift
- TVViews.swift
- Activity.swift
- MemberStats.swift
- StravaAPI.swift
- BiometricAuth.swift
- Item.swift

**To check:** Select each file in Xcode, open File Inspector (⌘⌥1), verify "DCC Weekly Activities TV" is checked.

### 6. Reset the Simulator
- Device > Erase All Content and Settings...
- Then relaunch the app

### 7. Expected Console Output
If the app launches correctly, you should see:
```
🚀🚀🚀 TV APP INIT CALLED 🚀🚀🚀
📦 Creating ModelContainer...
✅ ModelContainer created successfully
🏗️ Building WindowGroup scene...
🎬🎬🎬 ContentView INIT called 🎬🎬🎬
📺 ========================================
📺 tvOS ContentView appeared
📺 Mock data enabled: true
... (more debug output)
```

### 8. Common Issues

**Issue: Wrong target selected**
- Solution: Select "DCC Weekly Activities TV" from target menu

**Issue: Files not in TV target**
- Solution: Select file > File Inspector > check TV target membership

**Issue: TestData not available**
- Solution: Verify TestData.swift is in Debug configuration and TV target

**Issue: Build caching**  
- Solution: Clean build folder (⌘⇧K), delete DerivedData, rebuild

**Issue: Simulator stuck**
- Solution: Device > Erase All Content and Settings, restart Xcode

## Quick Test
After making changes:
1. Clean Build (⌘⇧K)
2. Select "DCC Weekly Activities TV" target
3. Select an Apple TV simulator
4. Build and Run (⌘R)
5. Check Console immediately - you should see 🚀 within 2-3 seconds

## Still Not Working?
Check:
1. Is Xcode actually building? Look for "Build Succeeded" message
2. Did the simulator actually launch the app? Look for the app icon appearing
3. Are there crash logs? Window > Devices and Simulators > Select simulator > View Device Logs

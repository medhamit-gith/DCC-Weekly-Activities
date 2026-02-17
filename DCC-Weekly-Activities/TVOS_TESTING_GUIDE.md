# 📺 tvOS Simulator Testing Guide

## Complete Step-by-Step Instructions for Testing DCC Weekly Activities on Apple TV

---

## Part 1: Setting Up and Launching

### Step 1: Select the tvOS Target
1. Look at the **top toolbar** in Xcode
2. Find the **scheme selector** (usually shows "DCC Weekly Activities" or similar)
3. Click on it to open the dropdown
4. Select **"DCC Weekly Activities TV"**
5. The scheme name should now show the TV version

### Step 2: Choose the Apple TV Simulator
1. Next to the scheme name, click the **device selector**
2. From the list, choose:
   - **Apple TV 4K (3rd generation)** ← Recommended
   - Or **Apple TV 4K (at 1080p)** for lower resolution
3. If you don't see any Apple TV simulators:
   - Go to **Xcode → Settings → Platforms**
   - Download tvOS simulators if needed

### Step 3: Build and Run
1. Click the **Play button (▶️)** or press **Cmd + R**
2. Wait for:
   - Build to complete (watch progress at top)
   - Simulator window to open
   - App to install and launch

**⏱️ First Launch**: May take 1-2 minutes as the simulator boots up

---

## Part 2: Controlling the tvOS Simulator

### 🎮 Navigation Methods

#### Option A: Keyboard (Easiest)
- **Arrow Keys** → Navigate between buttons/items
- **Return/Enter** → Select focused item
- **Escape** → Go back / Menu button
- **Space** → Play/Pause
- **Cmd + Shift + H** → Home button (exit to TV home)

#### Option B: Mouse/Trackpad
- **Click and drag** → Move the focus highlight
- **Click** → Select the focused item
- **Scroll** → Scroll through content

#### Option C: Virtual Remote
1. Menu bar: **I/O → Input → Send Apple TV Remote**
   - Or press **Cmd + Shift + R**
2. A virtual Siri Remote appears
3. Click the touchpad area to navigate
4. Click center to select

### 💡 Pro Tips:
- The white **focus ring** shows what's currently selected
- Unlike iOS, you can't just tap anywhere - you must navigate to items first
- Focus flows in logical order (top to bottom, left to right)

---

## Part 3: Testing Your App

### What You'll See on Launch

#### Scenario 1: No Login (Default)
You'll see the **Login Screen** with:
- 🇮🇳 Tricolor background (saffron, white, green)
- 🚴 DCC logo (bicycle in blue circle)
- "Desi Cycling Club" title
- Two buttons:
  1. **"Load Test Data"** (green, DEBUG only)
  2. **"Visit dcc.club on iPhone to login"** (orange/saffron)

### Using Test Data (Recommended for First Test)

1. **Navigate** to the **"Load Test Data"** button using arrow keys
2. **Press Return/Enter** to activate it
3. The app will:
   - Show a loading spinner for 1 second
   - Load mock data with 15 activities from 8 members
   - Display the statistics dashboard

### Exploring the App Interface

Once test data is loaded, you'll see:

#### 📊 Stats Tab (Default View)
- **4 Summary Cards** at top:
  - Total Distance (km)
  - Total Rides
  - Total Elevation (m)
  - Active Members
  
- **Top Performers List**:
  - Ranked 1-10
  - Gold/Silver/Bronze colors for top 3
  - Shows: Rank, Name, Distance, Rides, Avg Speed
  - Trend indicators (↑↓→★)

#### 📋 Activities Tab
1. Use the **Tab bar** at bottom to switch views
2. Navigate to **"Activities"** tab
3. Shows **individual rides** with:
   - Member name
   - Activity name
   - Distance (km)
   - Speed, elevation, time

### Testing Navigation

**Practice these actions:**

1. **Scrolling Lists**:
   - Use **Up/Down arrows** to scroll
   - Or **click and drag** on trackpad

2. **Switching Tabs**:
   - Navigate to bottom tab bar
   - Use **Left/Right arrows** to select tab
   - Press **Return** to switch

3. **Going Back**:
   - Press **Escape** to return to login screen
   - Toggle test data off/on to reload

---

## Part 4: What to Test

### ✅ Testing Checklist

- [ ] **Launch** - App opens without crashes
- [ ] **UI Layout** - All text is readable (large fonts for TV)
- [ ] **Tricolor Header** - Indian flag colors display correctly
- [ ] **Focus Navigation** - Can navigate all buttons smoothly
- [ ] **Load Test Data** - Button works and loads mock activities
- [ ] **Stats Cards** - Display correct totals
- [ ] **Leaderboard** - Shows top performers ranked correctly
- [ ] **Activities List** - All 15 mock activities visible
- [ ] **Tab Switching** - Can switch between Stats and Activities
- [ ] **Scrolling** - Long lists scroll smoothly
- [ ] **Colors** - DCC theme colors (saffron, green, blue) look good
- [ ] **Icons** - System icons render properly

### 🔍 Things to Look For

**Layout Issues:**
- Text too small or too large
- Overlapping elements
- Cards or buttons cut off at edges

**Performance:**
- Smooth scrolling (should be 60fps)
- No lag when switching tabs
- Fast data loading (1 second for test data)

**Visual Polish:**
- Colors match DCC branding
- Proper spacing between elements
- Focus states clearly visible

---

## Part 5: Advanced Testing

### Testing with Different TV Models

Try your app on different simulators:

1. **Apple TV 4K (3rd generation)** - Latest, fastest
2. **Apple TV 4K (at 1080p)** - Lower resolution, tests readability
3. **Apple TV (3rd generation)** - Older hardware, performance test

**How to switch:**
- Stop the app (⌘+. )
- Change device selector
- Run again (⌘+R)

### Testing Dark Mode

tvOS apps should work in light and dark modes:

1. In Simulator, go to **Settings app**
2. Navigate to **Appearance**
3. Toggle **Light/Dark**
4. Return to your app to see changes

### Testing with Different Languages

1. Settings → General → Language
2. Change to Hindi or another language
3. Check if layouts still work (text might be longer)

---

## Part 6: Common Issues and Solutions

### Problem: Simulator Won't Launch
**Solution:**
- Go to **Xcode → Settings → Platforms**
- Ensure tvOS simulator is downloaded
- Try **Product → Clean Build Folder** (Cmd+Shift+K)

### Problem: App Crashes on Launch
**Solution:**
- Check Console for error messages (Cmd+Shift+Y)
- Verify all tvOS files are included in target
- Check that all `#if os(tvOS)` conditionals are correct

### Problem: Can't Navigate with Arrow Keys
**Solution:**
- Click inside the simulator window first
- Make sure simulator has focus (not Xcode)
- Try using the virtual remote instead

### Problem: Focus Not Visible
**Solution:**
- Buttons need `.buttonStyle(.card)` for tvOS
- Check that focusable elements have proper modifiers
- Try toggling focus with Tab key

### Problem: Test Data Button Not Appearing
**Solution:**
- Make sure you're running in **Debug** configuration
- Check **Product → Scheme → Edit Scheme → Run → Build Configuration**
- Should be set to "Debug" not "Release"

---

## Part 7: Debugging Tips

### Viewing Console Output

1. Show debug area: **Cmd + Shift + Y**
2. Look for print statements:
   ```
   📊 Total KM fetched: ...
   📊 Total activities: ...
   ```

### Setting Breakpoints

1. Click line numbers in code to add breakpoints
2. Run app in debug mode
3. When breakpoint hits, inspect variables

### Using Print Debugging

Add prints in your tvOS code:
```swift
print("🎬 tvOS: Loaded \(activities.count) activities")
```

---

## Part 8: Making Changes and Retesting

### Quick Iteration Workflow

1. **Make code changes** in Xcode
2. **No need to stop** - just press **Cmd + R** again
3. Xcode will rebuild and relaunch
4. Test your changes

### Testing UI Tweaks

Common things you might want to adjust:

- **Font sizes** - Change `.font(.system(size: 36))` values
- **Spacing** - Adjust `.padding()` values
- **Colors** - Modify Color.dccSaffron, etc.
- **Card sizes** - Change `.frame()` dimensions

### Hot Reload Tip

SwiftUI supports live previews:
1. Open a view file (e.g., TVViews.swift)
2. Click **Resume** in preview pane (or Cmd+Opt+P)
3. See changes instantly without full rebuild

---

## Summary: Quick Start

**For your FIRST test, do this:**

1. ✅ Select **"DCC Weekly Activities TV"** scheme
2. ✅ Choose **"Apple TV 4K (3rd generation)"** device
3. ✅ Press **Cmd + R** to run
4. ✅ Use **arrow keys** to navigate
5. ✅ Select **"Load Test Data"** button
6. ✅ Explore the **Stats** and **Activities** tabs

**🎉 You're now testing your tvOS app!**

---

## Next Steps

- Test on real Apple TV hardware (if available)
- Implement real authentication flow for tvOS
- Add more interactive features
- Test with very long member names or activity counts
- Optimize performance for larger datasets

---

## Need Help?

**Common Resources:**
- Apple's tvOS Human Interface Guidelines
- Xcode Simulator documentation
- SwiftUI for tvOS tutorials

**Debug Info to Share:**
- Xcode version
- macOS version
- Simulator model being used
- Console error messages

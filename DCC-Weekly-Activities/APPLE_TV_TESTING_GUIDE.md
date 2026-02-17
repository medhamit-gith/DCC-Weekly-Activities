# Testing on Apple TV Simulator - Complete Guide

## Quick Start

### Step 1: Add tvOS Target in Xcode

1. **Open your project** in Xcode
2. Click on your **project file** in the navigator (top of left sidebar)
3. At the bottom of the targets list, click the **"+"** button
4. Select **tvOS → App**
5. **Product Name**: "DCC Weekly Activities TV" (or your preferred name)
6. **Organization Identifier**: Same as your iOS app
7. Click **Finish**
8. When prompted "Activate scheme?", click **Activate**

### Step 2: Share Code Files with tvOS Target

For each file you want to share:

1. Select the file in Project Navigator (e.g., `ContentView.swift`)
2. Open **File Inspector** (right sidebar, first tab)
3. Under **Target Membership**, check BOTH:
   - ✅ Your iOS app target
   - ✅ Your tvOS app target

**Files to share:**
- ✅ `ContentView.swift`
- ✅ `StravaAPI.swift`
- ✅ `BiometricAuth.swift`
- ✅ `Activity.swift`
- ✅ `MemberStats.swift`
- ✅ `MemberStatsChartView.swift`
- ✅ `MemberStatsTableView.swift`
- ✅ `TVViews.swift`

### Step 3: Copy Assets to tvOS

1. In Project Navigator, find your tvOS app's **Assets.xcassets**
2. Open it
3. Drag your club photos into the tvOS Assets catalog:
   - `club_photo_1`
   - `club_photo_2`

### Step 4: Select Apple TV Simulator

1. In Xcode's toolbar, click the **device selector** (next to your app name)
2. Under "tvOS Simulators", choose one:
   - **Apple TV 4K (3rd generation)** - Recommended, latest
   - **Apple TV 4K (2nd generation)**
   - **Apple TV 4K (at 1080p)**

### Step 5: Build and Run

1. Press **⌘R** (Cmd+R) or click the **Play button**
2. Wait for simulator to boot (first time takes longer)
3. Your app launches on Apple TV!

## Navigating Apple TV Simulator

### Keyboard Controls

#### **Navigation:**
- **Arrow Keys** ↑↓←→ - Move focus between elements
- **Return/Enter** ⏎ - Select focused item
- **Escape** ⎋ - Back/Menu button
- **Space** - Play/Pause (in media)

#### **Touchpad Simulation:**
- **Click and drag** on simulator - Swipe gesture
- **Option + drag** - Rotate view
- **Shift + arrow keys** - Faster navigation

#### **Siri Remote Buttons:**
- **Menu**: Escape key
- **Select**: Return/Enter key
- **Play/Pause**: Space bar
- **Home**: Cmd+Shift+H

### Mouse/Trackpad Controls

1. **Click on simulator** - Tap
2. **Click and drag** - Swipe
3. **Hover** - Shows focus (automatic)

## Testing Your App Features

### Test 1: Launch Screen

**What to see:**
- Tricolor background (saffron, white, green)
- Large "Desi Cycling Club" title
- "Visit dcc.club on iPhone to login" message
- TV icon and instructions

**How to test:**
1. Launch app
2. Use arrow keys to navigate
3. Focus moves to the login instruction button
4. Blue glow around focused elements

### Test 2: Biometric Authentication (tvOS uses Passcode)

Since tvOS doesn't have Face ID, it uses:
- System passcode authentication
- Same secure keychain storage
- Simulated automatically in simulator

**To test:**
1. If you have a saved token, you'll be prompted
2. Simulator auto-approves in development mode
3. Production builds require actual Apple TV

### Test 3: Statistics View

**Prerequisites:** Need to login on iPhone first and sync token

**What to see:**
- Tricolor header strip (12px high)
- Large stat cards (2x2 grid):
  - Total Distance
  - Total Rides
  - Total Elevation
  - Active Members
- Top performers list with large fonts
- Smooth focus animations

**How to test:**
1. Navigate with arrow keys
2. Focus moves through stat cards
3. Press Enter to select
4. Scroll through performers list

### Test 4: Activities Tab

**What to see:**
- Tab bar at top
- "Stats" and "Activities" tabs
- Large activity cards with member info
- Scrollable list

**How to test:**
1. Use **left/right arrows** to switch tabs
2. Use **up/down arrows** to scroll activities
3. Each activity shows:
   - Member name (36pt font)
   - Activity name (28pt font)
   - Distance (42pt font, saffron color)
   - Speed and elevation

### Test 5: Focus Engine

Apple TV's focus engine highlights interactive elements.

**What to test:**
- Blue glow around focused item
- Smooth transitions between elements
- Focus remembers last position
- Tab groups work correctly

**How to verify:**
1. Navigate with arrows
2. Only one item focused at a time
3. Focus follows logical path
4. Can reach all interactive elements

## Debugging tvOS

### Enable Debug Logging

Your app already has debug prints. To see them:

1. **Open Console.app** (on Mac)
2. **Select your simulator** from devices
3. **Filter**: Enter "DCC" or "📊" to see your logs
4. Watch for:
   ```
   🏃 Fetching club activities...
   📊 Total KM fetched: 664.4
   ✅ Token loaded from keychain
   ```

### Xcode Console

Alternatively, in Xcode:
1. **Show Debug Area**: Cmd+Shift+Y
2. Watch console output during testing
3. Look for errors or warnings

## Common Issues & Solutions

### Issue 1: "No such module 'Charts'"

**Solution:**
1. Select tvOS target
2. Go to **Build Phases** → **Link Binary with Libraries**
3. Click **"+"**
4. Add **Charts.framework**

### Issue 2: Images Not Showing

**Solution:**
1. Check tvOS Assets.xcassets has the images
2. Verify image names match exactly
3. Check Target Membership for image assets

### Issue 3: Focus Not Working

**Solution:**
1. Ensure buttons use `.buttonStyle(.card)` or `.buttonStyle(.plain)`
2. Add `.focusable()` to custom views
3. Use `.focused($focusedButton, equals: .someCase)` for state tracking

### Issue 4: Fonts Too Small

**Solution:**
- tvOS fonts should be 2-3x larger than iOS
- Minimum: 28pt for body text
- Recommended: 36-48pt for headlines
- Your app already uses correct sizes!

### Issue 5: OAuth Doesn't Work

**Expected Behavior:**
- OAuth is iOS-only feature
- tvOS shows instruction screen
- Users must login on iPhone first
- Token syncs via iCloud Keychain (production)

## Simulator Limitations

### What Works in Simulator:
- ✅ UI layout and navigation
- ✅ Focus engine
- ✅ Data fetching (if authenticated)
- ✅ Keychain (simulated)
- ✅ Tab navigation
- ✅ Scrolling

### What Doesn't Work:
- ❌ Real biometric auth (auto-approves)
- ❌ OAuth flow (no web browser)
- ❌ Siri Remote features
- ❌ iCloud Keychain sync between devices
- ❌ Actual hardware performance

## Testing on Real Apple TV

### Requirements:
1. **Apple TV 4K or HD** (4th gen+)
2. **Apple Developer account** (free or paid)
3. **USB-C cable** (for Apple TV 4K)

### Steps:
1. Connect Apple TV to Mac via USB-C
2. Open **Xcode** → **Window** → **Devices and Simulators**
3. Select your Apple TV
4. Click **"+"** to pair
5. Select Apple TV in device menu
6. Build and run (⌘R)

### Advantages:
- Real Siri Remote navigation
- Actual biometric/passcode auth
- iCloud Keychain sync works
- True performance testing
- Living room UX validation

## Simulator Shortcuts Cheatsheet

```
⌘R          - Build and Run
⌘.          - Stop running app
⌘K          - Clear console
⌘Shift+Y    - Toggle debug area

Arrow Keys  - Navigate focus
Return      - Select
Escape      - Menu/Back
Space       - Play/Pause
⌘Shift+H    - Home button

⌘1          - Show Project Navigator
⌘2          - Show Source Control
⌘0          - Toggle Navigator
⌘Option+0   - Toggle Inspector
```

## Verifying Your Setup

### Checklist:

- [ ] tvOS target created
- [ ] All Swift files have tvOS target checked
- [ ] Assets copied to tvOS
- [ ] Apple TV simulator selected
- [ ] App builds without errors
- [ ] Launch screen shows correctly
- [ ] Navigation with keyboard works
- [ ] Focus engine highlights elements
- [ ] Fonts are large and readable
- [ ] Tricolor theme appears correctly

## Next Steps

Once simulator testing passes:

1. **Test on real Apple TV** for complete validation
2. **Archive your app** (Product → Archive)
3. **Submit to App Store** with both iOS and tvOS builds
4. **TestFlight** for beta testing

Your Desi Cycling Club app is ready for Apple TV! 🍎📺🚴‍♂️

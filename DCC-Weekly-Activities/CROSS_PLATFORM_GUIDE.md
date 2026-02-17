# Cross-Platform Support - iPhone & Apple TV

## Overview

Your DCC Weekly Activities app now supports both iPhone/iPad and Apple TV!

## Platform-Specific Features

### 📱 **iPhone/iPad**
- Full OAuth authentication with Strava
- Touch-optimized UI
- Photo carousel on login screen
- Swipe gestures
- Segmented picker for view modes
- Pull-to-refresh
- Compact layouts

### 📺 **Apple TV**
- tvOS-optimized large fonts and spacing
- Focus-based navigation (Siri Remote)
- Read-only display of statistics
- Large, TV-friendly cards
- Simplified navigation
- Living room viewing experience

## How to Add tvOS Target in Xcode

### Step 1: Add tvOS Target
1. Open your project in Xcode
2. Go to **File → New → Target**
3. Select **tvOS → App**
4. Name it "DCC Weekly Activities TV"
5. Click **Finish**

### Step 2: Share Code
1. Select your source files (ContentView.swift, Activity.swift, etc.)
2. In the **File Inspector** (right panel), check both targets:
   - ✅ DCC-Weekly-Activities (iOS)
   - ✅ DCC Weekly Activities TV (tvOS)

### Step 3: Add Images to tvOS
1. Open the tvOS Assets catalog
2. Add the same club photos
3. Ensure they're included in the tvOS target

### Step 4: Update Info.plist (tvOS)
Add URL scheme for deep linking (though OAuth won't work on tvOS):
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>dccweeklyactivities</string>
        </array>
    </dict>
</array>
```

## Platform Detection

The app uses `#if os(tvOS)` compiler directives to show different UI:

```swift
#if os(tvOS)
tvOSContent  // Large fonts, focus-based navigation
#else
iOSContent   // Touch-optimized, OAuth login
#endif
```

## Key Differences

| Feature | iPhone/iPad | Apple TV |
|---------|-------------|----------|
| Login | ✅ OAuth | ⚠️  Read instruction screen |
| Font Size | Standard | 2-3x larger |
| Navigation | Touch | Focus (Siri Remote) |
| Interaction | Tap/Swipe | Select/Swipe |
| Layout | Compact | Spacious (10ft viewing) |
| Photos | Carousel | Static display |

## Authentication Note

**Apple TV Limitation**: OAuth authentication doesn't work directly on tvOS because it doesn't have Safari or ASWebAuthenticationSession.

**Solution**: 
- Show instruction screen on tvOS
- User logs in on iPhone first
- Use shared keychain or iCloud sync to share auth token
- Or implement a TV code-based auth flow

## Running on Different Devices

### iPhone/iPad
1. Select iPhone simulator or device
2. Select the iOS target
3. Build and run (Cmd+R)

### Apple TV
1. Select Apple TV simulator
2. Select the tvOS target  
3. Build and run (Cmd+R)
4. Use keyboard arrows or trackpad to navigate

## Simulator Testing

### iPhone Simulator
- Use mouse for touch
- Cmd+Shift+H for home button
- Cmd+L for lock screen

### Apple TV Simulator  
- Arrow keys for navigation
- Return/Enter to select
- Esc to go back

## Universal Binary

To create a universal app:
1. Keep both targets in the same project
2. Share common code files
3. Each platform gets optimized UI
4. Submit both to App Store

Your app now works beautifully on both iPhone and Apple TV with platform-appropriate experiences! 🚴‍♂️📱📺

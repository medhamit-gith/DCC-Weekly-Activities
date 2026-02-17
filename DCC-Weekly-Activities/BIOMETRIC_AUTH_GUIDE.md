# Face ID & Touch ID Authentication Setup

## Overview

Your DCC Weekly Activities app now supports biometric authentication using Face ID (iPhone X+, iPad Pro) and Touch ID (older iPhones, iPads) for secure, quick access!

## Features

### 🔐 **Security**
- Strava access token stored in iOS Keychain (encrypted)
- Token only accessible with biometric authentication
- Automatic logout on failed authentication
- Secure enclave protection

### 📱 **Supported Biometrics**
- **Face ID** - iPhone X and newer, iPad Pro
- **Touch ID** - iPhone 5s to 8, MacBook Pro, iPad Air/Mini
- **Passcode Fallback** - If biometrics fail or unavailable

### 🍎 **tvOS Support**
- Apple TV uses passcode authentication
- Same secure keychain storage
- Living room-friendly authentication flow

## How It Works

### First Time Login
1. User taps "Connect with Strava"
2. Completes OAuth login
3. Token saved to Keychain automatically
4. Next launch requires biometric auth

### Subsequent Launches
1. App checks for saved token
2. Shows lock screen with biometric prompt
3. User authenticates with Face ID/Touch ID
4. App loads data automatically

### Logout
1. User taps "Log Out"
2. Token removed from Keychain
3. Biometric protection cleared
4. User must re-authenticate with Strava

## Required Info.plist Entries

Add these to your Info.plist:

### For Face ID (Required)
```xml
<key>NSFaceIDUsageDescription</key>
<string>We use Face ID to securely access your DCC cycling activities and protect your Strava connection.</string>
```

### For tvOS Passcode
```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Access your cycling activities on Apple TV.</string>
```

## Privacy & Security

### What We Store
- ✅ Strava access token (encrypted in Keychain)
- ✅ Authentication state (in-memory only)

### What We DON'T Store
- ❌ No Strava password
- ❌ No biometric data (handled by iOS)
- ❌ No activity data (fetched live)

### Security Features
- **kSecAttrAccessibleWhenUnlockedThisDeviceOnly** - Token only accessible when device unlocked
- **Keychain encryption** - Hardware-encrypted storage
- **Biometric-only access** - No plain-text token access
- **Auto-logout on failure** - Failed auth clears everything

## User Experience Flow

### iPhone with Face ID
```
App Launch
  ↓
Lock Screen Shown
  ↓
User glances at phone
  ↓
Face ID authenticates
  ↓
App loads data automatically
```

### iPhone with Touch ID
```
App Launch
  ↓
Lock Screen Shown
  ↓
"Unlock with Touch ID" button
  ↓
User touches sensor
  ↓
App loads data
```

### Apple TV
```
App Launch
  ↓
Check for saved token
  ↓
Prompt for TV passcode
  ↓
User enters passcode on remote
  ↓
App loads data
```

## Error Handling

### User Cancels Authentication
- Shows cancel button
- Option to logout and re-authenticate
- Token remains secure in Keychain

### Biometrics Unavailable
- Automatic fallback to passcode
- Same security level
- Seamless user experience

### Authentication Fails
- User can retry
- Option to cancel and logout
- Clear error messages

## Testing

### Test Face ID in Simulator
1. Run app in iPhone simulator with Face ID
2. When prompted, go to **Features → Face ID → Enrolled**
3. Trigger authentication
4. Use **Features → Face ID → Matching Face** to approve

### Test Touch ID in Simulator
1. Run app in iPhone 8 simulator
2. When prompted, go to **Features → Touch ID → Enrolled**
3. Trigger authentication
4. Use **Features → Touch ID → Matching Touch** to approve

### Test on Real Device
1. Install app on iPhone/iPad
2. Login with Strava
3. Close app completely
4. Reopen - biometric prompt appears
5. Authenticate with Face ID/Touch ID

## Benefits

✅ **Faster login** - No need to re-enter credentials
✅ **More secure** - Token encrypted in Keychain
✅ **Better UX** - Quick glance or touch to unlock
✅ **Privacy** - Apple handles biometric data
✅ **Reliable** - Automatic fallback to passcode
✅ **Cross-platform** - Works on iPhone, iPad, and Apple TV

Your app is now enterprise-grade secure with biometric protection! 🔐🚴‍♂️

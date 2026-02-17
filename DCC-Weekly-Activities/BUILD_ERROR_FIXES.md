# Common Build Errors & Fixes

## Quick Fixes Applied

✅ **Fixed**: Added `import SwiftUI` to ContentView.swift
✅ **Fixed**: Added tvOS compatibility guards to BiometricAuth.swift
✅ **Fixed**: Added UIKit import guard for cross-platform support

## Common Build Errors

### Error 1: "Cannot find 'TVMemberStatsView' in scope"

**Cause**: TVViews.swift not included in target

**Fix**:
1. Select `TVViews.swift` in Project Navigator
2. Open File Inspector (right sidebar)
3. Under Target Membership, check:
   - ✅ Your iOS target
   - ✅ Your tvOS target (if you have one)

### Error 2: "Cannot find 'BiometricAuth' in scope"

**Cause**: BiometricAuth.swift not included in target

**Fix**:
1. Select `BiometricAuth.swift`
2. Check Target Membership for your target
3. Rebuild (Cmd+B)

### Error 3: "No such module 'Charts'"

**Cause**: Swift Charts not added to target

**Fix**:
1. Select your **project** (top of navigator)
2. Select your **target**
3. Go to **Build Phases** tab
4. Expand **Link Binary with Libraries**
5. Click **"+"** button
6. Search for "Charts"
7. Add **Charts.framework**

### Error 4: "'biometryType' is unavailable in tvOS"

**Cause**: LAContext.biometryType not available on tvOS

**Fix**: Already fixed! BiometricAuth.swift now has:
```swift
#if !os(tvOS)
switch context.biometryType {
    // ...
}
#else
biometricType = .none
#endif
```

### Error 5: "Missing import for 'SwiftUI'"

**Fix**: Already fixed! ContentView.swift now has `import SwiftUI`

### Error 6: "Use of unresolved identifier 'MemberStatsChartView'"

**Cause**: File not in target or not created

**Fix**:
1. Check if `MemberStatsChartView.swift` exists
2. Check Target Membership
3. If missing, the file needs to be created

### Error 7: "Expression type '...' is ambiguous without more context"

**Cause**: Type inference issue with Color extensions

**Fix**: Use `Color.dccSaffron` instead of `.dccSaffron` in shape fills

### Error 8: Info.plist Missing Face ID Description

**Warning**: "This app has crashed because it attempted to access privacy-sensitive data..."

**Fix**: Add to Info.plist:
```xml
<key>NSFaceIDUsageDescription</key>
<string>We use Face ID to securely access your DCC cycling activities.</string>
```

## Build Clean Steps

If you're getting persistent errors:

1. **Clean Build Folder**
   - Product → Clean Build Folder (Cmd+Shift+K)

2. **Delete Derived Data**
   - Xcode → Preferences → Locations
   - Click arrow next to Derived Data path
   - Delete the folder for your project
   - Restart Xcode

3. **Reset Package Cache** (if using SPM)
   - File → Packages → Reset Package Caches

4. **Restart Xcode**
   - Quit Xcode completely
   - Reopen your project

## Verification Checklist

Run through this checklist:

### Files Exist:
- [ ] ContentView.swift
- [ ] StravaAPI.swift
- [ ] BiometricAuth.swift
- [ ] Activity.swift
- [ ] MemberStats.swift
- [ ] MemberStatsChartView.swift
- [ ] MemberStatsTableView.swift
- [ ] TVViews.swift (for tvOS)

### All Files Have Correct Imports:
- [ ] `import SwiftUI` in all View files
- [ ] `import Foundation` in model files
- [ ] `import Charts` in chart view files
- [ ] `import LocalAuthentication` in BiometricAuth

### Target Membership:
- [ ] All .swift files checked for your target
- [ ] Assets checked for your target
- [ ] Info.plist configured

### Dependencies:
- [ ] Swift Charts added (if using charts)
- [ ] No red errors in Project Navigator
- [ ] Build succeeds (Cmd+B)

## Platform-Specific Issues

### iOS Only:
- ✅ Face ID/Touch ID works
- ✅ OAuth flow works
- ✅ ASWebAuthenticationSession available

### tvOS Only:
- ✅ Use `#if os(tvOS)` guards
- ✅ TVViews.swift for TV-specific UI
- ✅ Larger fonts (2-3x iOS sizes)
- ✅ Focus-based navigation

## Still Getting Errors?

Please share:
1. **Exact error message**
2. **Which file** the error is in
3. **Line number** of the error
4. **Full error text** from Xcode

Example:
```
ContentView.swift:45:23: Cannot find 'TVMemberStatsView' in scope
```

This helps me give you the exact fix!

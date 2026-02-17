# Quick Fix Summary

## What Was Wrong
1. ❌ **Face ID crash** - Missing `NSFaceIDUsageDescription` in Info.plist
2. ❌ **401 Unauthorized** - Your Strava access token expired

## What I Fixed
1. ✅ Added Face ID privacy description to Info.plist
2. ✅ Added proper 401 error handling that automatically logs you out
3. ✅ Added smart error display that shows "Log In Again" for auth errors

## What You Need to Do
1. **Rebuild the app**: `Cmd+Shift+K` (clean) then `Cmd+R` (run)
2. **Tap "Log In Again"** when you see the error
3. **Authenticate with Strava** again

## Why This Happened
- Face ID requires a privacy description (Apple requirement)
- Strava tokens expire after ~6 hours or if you revoked access
- The app now handles this gracefully!

---

**You're all set!** Just rebuild and re-authenticate. 🎉

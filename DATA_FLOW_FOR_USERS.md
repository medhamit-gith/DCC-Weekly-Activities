# DCC Weekly Activities App - Data Flow for Novice Users

## 🎯 What Does This App Do?

This app helps **Desi Cycling Club members** track their weekly cycling activities by connecting to Strava (a popular fitness tracking app). Think of it as a dashboard that shows:
- 📊 How many kilometers everyone rode this week
- 🏆 Who's the top rider
- 📈 Charts and stats for the whole club

---

## 📱 How the App Works (Simple Explanation)

### For iPhone/iPad Users:

```
┌─────────────────────────────────────────┐
│  You Open the App                       │
│  📱                                      │
└─────────────────┬───────────────────────┘
                  │
                  ▼
         ┌────────────────┐
         │ First Time?    │
         └───┬────────┬───┘
             │        │
         YES │        │ NO
             │        │
             ▼        ▼
    ┌────────────┐  ┌────────────────────┐
    │ Login      │  │ Use Face ID or     │
    │ with       │  │ Touch ID to unlock │
    │ Strava     │  │                    │
    └──────┬─────┘  └─────────┬──────────┘
           │                  │
           │                  │
           └────────┬─────────┘
                    │
                    ▼
           ┌────────────────┐
           │ App connects   │
           │ to Strava and  │
           │ downloads your │
           │ club's data    │
           └────────┬───────┘
                    │
                    ▼
           ┌────────────────┐
           │ See Dashboard: │
           │ • Stats        │
           │ • Charts       │
           │ • Activities   │
           └────────────────┘
```

### For Apple TV Users:

```
┌─────────────────────────────────────────┐
│  You Open the App on TV                 │
│  📺                                      │
└─────────────────┬───────────────────────┘
                  │
                  ▼
         ┌────────────────┐
         │ App            │
         │ automatically  │
         │ loads test     │
         │ data           │
         │ (Demo Mode)    │
         └────────┬───────┘
                  │
                  ▼
         ┌────────────────┐
         │ Dashboard      │
         │ appears        │
         │ immediately    │
         │ on TV screen   │
         └────────────────┘

Note: TV version shows demo data
for display purposes. Real login
happens on iPhone/iPad.
```

---

## 🔄 Complete Data Journey (iOS/iPadOS)

Let me walk you through exactly what happens when you use the app:

### Step 1: Opening the App

```
YOU: Tap app icon on iPhone
     │
     ▼
APP: Checks - "Do I have a saved login?"
     │
     ├─ NO → Show login screen
     │
     └─ YES → Show Face ID/Touch ID prompt
```

### Step 2: Logging In (First Time)

```
YOU: See "Connect with Strava" button
     │
     ▼
YOU: Tap the button
     │
     ▼
APP: Opens Strava website in browser
     │
     ▼
STRAVA WEBSITE: "Allow DCC Weekly Activities to access your data?"
     │
     ▼
YOU: Click "Authorize"
     │
     ▼
STRAVA: Sends back to the app with a special "key" (called token)
     │
     ▼
APP: Saves the key securely in your iPhone
     │
     ▼
APP: Uses the key to ask Strava for club data
```

### Step 3: Loading Data

```
APP: Sends request to Strava
     "Hey Strava, give me Desi Cycling Club's activities"
     │
     ▼
STRAVA: "Here are 50 activities from this week"
     │
     ▼
APP: Receives data and processes it:
     ├─ Sorts activities by member
     ├─ Calculates total distance per person
     ├─ Finds average speed
     ├─ Counts total rides
     └─ Ranks members by distance
     │
     ▼
APP: Shows you the dashboard!
```

### Step 4: Using the App (After First Login)

```
YOU: Open app again tomorrow
     │
     ▼
APP: Shows Face ID prompt
     │
     ▼
YOU: Look at camera (Face ID unlocks)
     │
     ▼
APP: Automatically refreshes data from Strava
     │
     ▼
YOU: See updated stats!
```

---

## 📊 What Data Does the App Use?

### From Strava:

The app asks Strava for this information about each ride:

```
Activity Information:
├─ 🚴 Member Name          (e.g., "Amit K")
├─ 📝 Activity Name        (e.g., "Morning Ride")
├─ 📏 Distance             (e.g., 45.2 km)
├─ 📅 Date                 (e.g., Feb 12, 2026)
├─ ⚡ Average Speed        (e.g., 28.5 km/h)
├─ 🏔️  Elevation Gain      (e.g., 320 meters)
└─ ⏱️  Moving Time          (e.g., 1 hour 35 mins)
```

### What the App Calculates:

From the raw activity data, the app creates these statistics:

```
Member Statistics:
├─ 📊 Total Distance       (sum of all rides)
├─ 🚴 Total Rides          (count of activities)
├─ 🏔️  Total Elevation     (sum of all climbs)
├─ ⚡ Average Speed        (mean across rides)
├─ 📈 Trend                (👍 improving or 👎 declining)
└─ 🏆 Rank                 (#1, #2, #3, etc.)

Club Statistics:
├─ 📊 Total Distance       (all members combined)
├─ 🚴 Total Rides          (all rides this week)
├─ 🏔️  Total Elevation     (sum of all climbing)
├─ 👥 Active Members       (people who rode)
└─ 📅 Week Range           (Monday to Sunday)
```

---

## 🏗️ App Architecture (Technical View)

Here's how the app is structured (for developers):

```
┌─────────────────────────────────────────────────────────┐
│                    USER INTERFACE                        │
│                    (What You See)                        │
├──────────────┬──────────────┬──────────────┬────────────┤
│ Login Screen │ Stats View   │ Chart View   │ Activities │
│              │              │              │ List       │
└──────┬───────┴──────┬───────┴──────┬───────┴──────┬─────┘
       │              │              │              │
       └──────────────┴──────────────┴──────────────┘
                       │
                       ▼
       ┌───────────────────────────────────────────┐
       │         ContentView (Main Controller)      │
       │  • Manages what screen to show            │
       │  • Handles user interactions               │
       │  • Stores app state (data & loading)      │
       └───────────────┬───────────────────────────┘
                       │
                       ├─────────────┬─────────────┐
                       │             │             │
                       ▼             ▼             ▼
           ┌───────────────┐ ┌─────────────┐ ┌──────────┐
           │ StravaAPI     │ │ BiometricAuth│ │ TestData │
           │               │ │              │ │          │
           │ Talks to      │ │ Handles      │ │ Demo     │
           │ Strava        │ │ Face ID      │ │ data for │
           │ servers       │ │ Touch ID     │ │ testing  │
           └───────┬───────┘ └──────┬───────┘ └────┬─────┘
                   │                │              │
                   │                │              │
                   ▼                ▼              ▼
       ┌────────────────────────────────────────────────┐
       │            DATA STORAGE                        │
       ├────────────────┬───────────────────────────────┤
       │ iOS Keychain   │  Local App Memory             │
       │ (secure)       │  (temporary)                  │
       │                │                               │
       │ • Strava token │  • Activities list            │
       │ • Saved login  │  • Member stats               │
       │                │  • Chart data                 │
       └────────────────┴───────────────────────────────┘
```

---

## 🔐 Security & Privacy (How Your Data is Protected)

### What Happens to Your Data:

```
┌──────────────────────────────────────────┐
│  Your Strava Login Token                 │
│  (The "key" that allows access)          │
└────────────┬─────────────────────────────┘
             │
             ▼
    ┌────────────────┐
    │ iOS Keychain   │ ← Most secure place on iPhone
    │ (Encrypted)    │   Same place your passwords go
    └────────────────┘

┌──────────────────────────────────────────┐
│  Activity Data (rides, stats)            │
│  (Downloaded from Strava)                │
└────────────┬─────────────────────────────┘
             │
             ▼
    ┌────────────────┐
    │ iPhone Memory  │ ← Stored temporarily
    │ (Local only)   │   Never sent anywhere
    └────────────────┘

IMPORTANT: This app does NOT:
❌ Send your data to any server
❌ Share your data with anyone
❌ Track your location
❌ Collect analytics
❌ Show you ads

✅ All data stays on YOUR device only
```

---

## 📱 vs 📺 Platform Differences

### iPhone/iPad Version:
```
Features:
✅ Full Strava login
✅ Real-time data sync
✅ Biometric security (Face ID/Touch ID)
✅ Refresh button to update data
✅ Log out option
✅ Multiple view modes (Charts, Table, List)

User Journey:
1. Login with Strava
2. Authorize app access
3. See real club data
4. Refresh anytime
5. Use Face ID for quick access
```

### Apple TV Version:
```
Features:
✅ Auto-loads demo data
✅ No login required
✅ Perfect for display in club house
✅ Big screen optimized

User Journey:
1. Open app
2. Data loads automatically
3. See dashboard immediately

Note: TV version shows sample data.
Use iPhone to see real data.
```

---

## 🎨 User Interface Breakdown

### What Each Screen Does:

#### 1. Login Screen (iPhone/iPad)
```
┌─────────────────────────────────┐
│  🚴 Desi Cycling Club           │
│     Weekly Activities           │
│                                 │
│  [Connect with Strava] button   │
│                                 │
│  Secured with Face ID 🔒        │
└─────────────────────────────────┘

Purpose: Get permission to access
your Strava data
```

#### 2. Stats/Charts View
```
┌─────────────────────────────────┐
│  📊 Total Distance: 540 km      │
│  🚴 Total Rides: 15             │
│  🏔️  Total Elevation: 4,000 m   │
│  👥 Active Members: 8           │
│                                 │
│  🏆 Top Performers              │
│  🥇 #1 Amit K    146.4 km       │
│  🥈 #2 Anita P   103.9 km       │
│  🥉 #3 Neha D     77.0 km       │
│  ...                            │
└─────────────────────────────────┘

Purpose: See who's riding the most
```

#### 3. Activities List
```
┌─────────────────────────────────┐
│  Amit K                         │
│  Morning Ride                   │
│  45.2 km • 28.5 km/h • 320m 🏔️  │
│                                 │
│  Priya S                        │
│  Hill Training                  │
│  32.4 km • 24.2 km/h • 520m 🏔️  │
│  ...                            │
└─────────────────────────────────┘

Purpose: See every single ride
```

---

## ⚡ What Happens Behind the Scenes (Technical)

### When You Tap "Refresh":

```
Step 1: App checks internet connection
        │
        ▼
Step 2: App sends request to Strava API
        URL: https://www.strava.com/api/v3/clubs/12345/activities
        Headers: Authorization: Bearer [your-token]
        │
        ▼
Step 3: Strava responds with JSON data
        {
          "activities": [
            {
              "athlete": {"firstname": "Amit", "lastname": "K"},
              "name": "Morning Ride",
              "distance": 45200,  // in meters
              "average_speed": 7.9,  // in m/s
              ...
            },
            ...
          ]
        }
        │
        ▼
Step 4: App converts units
        - Distance: 45200 m → 45.2 km
        - Speed: 7.9 m/s → 28.5 km/h
        │
        ▼
Step 5: App groups by member
        - Amit K: [activity1, activity2, ...]
        - Priya S: [activity1, activity2, ...]
        │
        ▼
Step 6: App calculates totals
        For each member:
          total_distance = sum(all activity distances)
          total_rides = count(activities)
          avg_speed = mean(all speeds)
        │
        ▼
Step 7: App sorts members by distance
        [Amit K (146.4km), Anita P (103.9km), ...]
        │
        ▼
Step 8: App updates the screen
        You see fresh data! 🎉
```

---

## 🐛 Common Issues & Solutions (Troubleshooting)

### Issue: "Can't see any activities"

```
Possible Causes:
├─ Not logged in → Solution: Tap "Connect with Strava"
├─ Not in club → Solution: Join DCC on Strava first
├─ No internet → Solution: Check WiFi/cellular
└─ Token expired → Solution: Log out and log in again
```

### Issue: "Too many requests"

```
Cause: Strava limits how often you can refresh
Solution: Wait 15 minutes before trying again

Technical: Strava allows 100 requests per 15 minutes
```

### Issue: App shows old data

```
Solution: Tap the refresh button (circular arrow)

What it does:
1. Clears old data
2. Fetches fresh data from Strava
3. Recalculates all stats
4. Updates the display
```

---

## 📚 Glossary (Terms Explained)

| Term | What It Means |
|------|---------------|
| **Strava** | A fitness tracking app/website for cyclists and runners |
| **OAuth** | A secure way to login without sharing your password |
| **Token** | A special "key" that lets the app access your Strava data |
| **API** | Application Programming Interface - how the app talks to Strava |
| **Keychain** | iPhone's secure storage for passwords and tokens |
| **Biometric** | Face ID or Touch ID - using your face/fingerprint to unlock |
| **Aggregate** | Combining multiple pieces of data (like summing distances) |
| **Mock Data** | Fake sample data used for testing |
| **Rate Limit** | Maximum number of requests allowed per time period |
| **Elevation Gain** | How much you climbed during a ride |

---

## 🎓 Learning More

### For Non-Technical Users:

**Want to understand your stats better?**
- Distance: Total kilometers ridden
- Rides: Number of separate activities
- Elevation: How much uphill climbing
- Average Speed: Your typical pace

**Want to improve your ranking?**
- Ride more often (more activities)
- Ride longer distances
- Stay consistent through the week

### For Developers:

**Want to understand the code?**

Key files:
- `ContentView.swift` - Main app logic and UI
- `StravaAPI.swift` - Handles Strava communication
- `BiometricAuth.swift` - Manages Face ID/Touch ID
- `TestData.swift` - Sample data for testing
- `TVViews.swift` - Apple TV optimized layouts

Technologies used:
- SwiftUI (user interface)
- Swift Concurrency (async/await for network calls)
- Keychain Services (secure storage)
- Local Authentication (Face ID/Touch ID)
- Combine (reactive updates)

---

## 🎯 Summary: Data Flow in One Picture

```
┌─────────────┐
│    YOU      │
│   👤       │
└──────┬──────┘
       │
       │ Tap app
       ▼
┌─────────────┐
│  IPHONE 📱  │
│             │
│  DCC Weekly │
│  Activities │
│  App        │
└──────┬──────┘
       │
       │ Login
       ▼
┌─────────────┐       Internet      ┌─────────────┐
│  STRAVA     │◄─────────────────────│  STRAVA     │
│  Website    │                      │  Servers    │
│  Login      │──────────────────────►  🌐        │
└─────────────┘    Give permission   └──────┬──────┘
                                            │
       ┌────────────────────────────────────┘
       │ Send activities data
       ▼
┌─────────────┐
│  IPHONE 📱  │
│             │
│  Processes  │
│  calculates │
│  displays   │
└──────┬──────┘
       │
       │ Show dashboard
       ▼
┌─────────────┐
│    YOU      │
│   👤       │
│             │
│  See stats! │
│  🏆📊📈     │
└─────────────┘
```

**In Simple Terms:**
1. You give the app permission to read your Strava data
2. The app asks Strava for your club's rides
3. The app does math to calculate totals and rankings
4. You see a beautiful dashboard with all the info

**Key Point:** Your data never leaves your phone. The app only talks to Strava (which you already use) and stores everything locally on your device.

---

## 💡 Fun Fact

The app uses the colors of the Indian flag (saffron, white, green) to celebrate the Desi Cycling Club's heritage! 🇮🇳🚴‍♂️

---

*Questions? See the support.html page or email support!*

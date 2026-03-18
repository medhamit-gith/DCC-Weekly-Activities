# DCC Weekly — UI Flow

## iOS / iPadOS

```
┌─────────────────────────────────────────────────────────────────┐
│                         APP LAUNCH                              │
└───────────────────────────┬─────────────────────────────────────┘
                            │
              ┌─────────────▼─────────────┐
              │  Is a saved token stored? │
              └──────┬──────────┬─────────┘
                    YES         NO
                     │          │
         ┌───────────▼──┐   ┌───▼──────────────────────────────┐
         │  BIOMETRIC   │   │           LOGIN SCREEN            │
         │  LOCK SCREEN │   │                                   │
         │              │   │  🚲  Desi Cycling Club            │
         │  🔒 Locked   │   │      Weekly Activities            │
         │              │   │  "Track rides · View stats ·      │
         │  [Face ID /  │   │   Celebrate together"             │
         │  Touch ID    │   │                                   │
         │  button]     │   │  [ Connect with Strava ]  ←───── │─── opens Safari
         │              │   │  🔐 Secured with Face ID          │    OAuth flow
         │  [Cancel]    │   └──────────────────────────────────-┘
         └──────┬───────┘
                │
       ┌────────▼──────────┐
       │  Auth succeeds?   │
       └────┬──────────────┘
           YES    NO → stays on lock screen
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      DASHBOARD  (main content)                  │
│  NavigationStack                                                │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Navigation Bar:  "This Week"          [↺]  [→ logout]  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ── date range pill ──  e.g. "10 Feb – 17 Feb"                 │
│                                                                 │
│  ┌─────────────── HERO CARD ────────────────────────────────┐   │
│  │           Animated ring (total KM / 500 km goal)         │   │
│  │                  [ 342 ]  kilometres                      │   │
│  │  ─────────────────────────────────────────────────────   │   │
│  │  🚲 Rides     👥 Riders       ⛰ Elevation               │   │
│  │   28            9             1,240 m                     │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌──────────────── TOP PERFORMERS CARD ─────────────────────┐   │
│  │  Top Performers          9 members rode this week         │   │
│  │                                                [See All]  │   │
│  │  🥇 1  Amit K     ████████████████░░░░  210 km           │   │
│  │  🥈 2  Priya S    ██████████████░░░░░░  185 km           │   │
│  │  🥉 3  Raj M      ████████████░░░░░░░░  162 km           │   │
│  │     4  …          ██████████░░░░░░░░░░  140 km           │   │
│  │     5  …          ████████░░░░░░░░░░░░  112 km           │   │
│  │            ↑ tap any row → Member Detail Sheet           │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌──────────────── RECENT RIDES CARD ───────────────────────┐   │
│  │  Recent Rides                                            │   │
│  │  🚴 Amit K     Morning Ride          52.3 km   Mon       │   │
│  │  ──────────────────────────────────────────────────────  │   │
│  │  🚴 Priya S    Weekend Warrior       48.0 km   Sun       │   │
│  │  ──────────────────────────────────────────────────────  │   │
│  │  …  (up to 6 most recent rides shown)                   │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              ↑                                  │
│              Pull-to-refresh calls Strava API                   │
└─────────────────────────────────────────────────────────────────┘
                            │
              Tap a performer row
                            │
                            ▼  (NavigationStack push — full screen, back button)
┌─────────────────────────────────────────────────────────────────┐
│              RIDER PROFILE  RiderProfileView.swift              │
│  ← This Week            Amit K                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  ● AK   Amit K                                           │   │
│  │         ↑ Improving   Rank #1 of 9                       │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  📅 This Week                                                   │
│  ┌──────────────┐  ┌──────────────┐                            │
│  │ 🛣 210.0 km  │  │  🚲 3 rides  │                            │
│  └──────────────┘  └──────────────┘                            │
│  ┌──────────────┐  ┌──────────────┐                            │
│  │ ⚡ 28.4 km/h │  │  ⛰ 640 m   │                            │
│  └──────────────┘  └──────────────┘                            │
│                                                                 │
│  👥 vs. Club Average                                           │
│  Distance   ████████████▓▓▓▓▓ 210 km  ↑  avg 145 km           │
│  Avg Speed  ████████▓▓▓▓▓▓▓▓▓ 28.4    ↑  avg 25.1 km/h        │
│  Elevation  ████▓▓▓▓▓▓▓▓▓▓▓▓▓ 640 m   ↓  avg 280 m            │
│  Rides      ████████▓▓▓▓▓▓▓▓▓ 3        →  avg 2.8              │
│  (█ = rider  ▓ = club avg,  ↑ above / ↓ below)                 │
│                                                                 │
│  🏆 Club Ranking (percentile rings)                            │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐               │
│  │  Distance  │  │   Speed    │  │ Elevation  │               │
│  │   ○ 88%    │  │   ○ 75%    │  │   ○ 44%    │               │
│  │  Top 20%   │  │  Top 40%   │  │   Middle   │               │
│  └────────────┘  └────────────┘  └────────────┘               │
│                                                                 │
│  📊 Rides This Week (bar chart, one bar per ride)              │
│      62.5 ┐                                                    │
│      52.3 ┤  ██                                                │
│      38.7 ┤  ██  ██                                            │
│           └──────────────── Mon  Wed  Sat                      │
│      ── Club avg 145 km ──                                     │
│                                                                 │
│  💡 Where to Improve                                           │
│  ⛰  Add more climbing                                         │
│      Your elevation (640 m) is 360 m below club avg.          │
│      Hill routes will strengthen legs and build stamina.       │
│                                                                 │
│  ✓   Distance — leading the pack                               │
│      You're 65 km above the club avg. Keep pushing!           │
│                                                                 │
│  📋 All Rides (3)                                              │
│  🚴 Weekend Long Ride  62.5 km  27.8 km/h  Sat  ⛰ 450 m      │
│  🚴 Morning Ride       52.3 km  28.5 km/h  Wed  ⛰ 320 m      │
│  🚴 Evening Loop       38.7 km  26.3 km/h  Mon  ⛰ 180 m      │
└─────────────────────────────────────────────────────────────────┘


── ALTERNATIVE DASHBOARD STATES ────────────────────────────────────

  Loading                        Empty / No rides
  ─────────────────────────      ─────────────────────────────────
  ⏳  (spinner)                  🚲  (large thin bicycle icon)
  "Loading rides…"               "No rides this week"
                                 "Everyone's resting…"
                                 [ Sync Now ]

  Error (auth/token expired)     Error (other)
  ─────────────────────────      ─────────────────────────────────
  ⚠️  Something went wrong       ⚠️  Something went wrong
  [ Log In Again ]               [ Try Again ↺ ]
```

---

## tvOS  (Apple TV)

```
┌──────────────────────────────────────────────────────────────────┐
│  ▓▓▓▓▓▓▓▓▓ SAFFRON ░░░░░░░░ WHITE ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ GREEN ▒▒▒▒▒  │
│  (tricolour header bar)                                          │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  TabView                                                         │
│  ┌──────────┐  ┌───────────┐                                     │
│  │  Stats   │  │ Activities│                                     │
│  └──────────┘  └───────────┘                                     │
│                                                                  │
│  STATS TAB                                                       │
│  ┌──────────────────┐  ┌──────────────────┐                      │
│  │  🛣  Total Dist. │  │  🚲 Total Rides   │                      │
│  │   342.0 km       │  │   28             │                      │
│  └──────────────────┘  └──────────────────┘                      │
│  ┌──────────────────┐  ┌──────────────────┐                      │
│  │  ⛰ Total Elev.  │  │  👥 Active Mbrs  │                      │
│  │   1,240 m        │  │   9             │                      │
│  └──────────────────┘  └──────────────────┘                      │
│                                                                  │
│  Top Performers                                                  │
│  🥇 #1  Amit K      ↑ Improving       210.0 km  12 rides        │
│  🥈 #2  Priya S     ↑ Improving       185.0 km  10 rides        │
│  🥉 #3  Raj M       → Stable          162.0 km   9 rides        │
│     #4  …                                                        │
│     …  (up to 10 shown)                                         │
│                                                                  │
│  ACTIVITIES TAB                                                  │
│  🚴  Amit K   Morning Ride         52.3 km  29.1 km/h  ⛰ 120m  │
│  🚴  Priya S  Weekend Warrior      48.0 km  27.4 km/h  ⛰  90m  │
│  …  (full scrollable list)                                       │
│                                                                  │
│  (DEBUG only — if no data: [ Load Test Data ] button)           │
└──────────────────────────────────────────────────────────────────┘
  On launch: auto-loads mock data (DEBUG) or shows auth message (RELEASE)
```

---

## State Machine Summary

```
                    ┌──────────────┐
                    │  App Launch  │
                    └──────┬───────┘
                           │
               ┌───────────▼────────────┐
               │   Saved token exists?  │
               └──┬─────────────────┬───┘
                 YES                NO
                  │                  │
         ┌────────▼──────┐    ┌──────▼──────┐
         │  Biometric    │    │   Login     │
         │  Lock Screen  │    │   Screen    │
         └────────┬──────┘    └──────┬──────┘
          Auth OK │                  │ OAuth complete
                  └─────────┬────────┘
                            │
                    ┌───────▼────────┐
                    │  Fetch Strava  │
                    │  Activities    │
                    └───────┬────────┘
                 ┌──────────┼─────────────┐
               error     loading        success
                 │           │              │
            ┌───▼───┐  ┌────▼────┐  ┌─────▼──────────────────┐
            │ Error │  │Spinner  │  │  Dashboard             │
            │ State │  │         │  │  Hero+Charts           │
            └───────┘  └─────────┘  │  +Recent Rides         │
                                    └──────────┬─────────────┘
                                               │ tap performer row
                                               ▼
                                    ┌──────────────────────────┐
                                    │  RiderProfileView (push) │
                                    │  - vs Club Average bars  │
                                    │  - Percentile rings      │
                                    │  - Per-ride bar chart    │
                                    │  - Where to Improve tips │
                                    │  - Full rides list       │
                                    └──────────────────────────┘
```

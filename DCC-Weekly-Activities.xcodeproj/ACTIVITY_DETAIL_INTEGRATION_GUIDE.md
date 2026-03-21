# 🔗 Activity Detail View Integration Guide

## Overview

This guide shows how to make activities in the list clickable and navigate to a detailed view with comparisons.

---

## Changes Needed

### In your main view that displays activities (likely ContentView.swift or RootView.swift)

You need to wrap `ActivityRow` with a `NavigationLink` to enable navigation to `ActivityDetailView`.

---

## Implementation

### Find where activities are displayed in a List/ForEach

Look for code like this:

```swift
// Current code (example)
List(activities) { activity in
    ActivityRow(activity: activity)
}
```

### Replace with NavigationLink wrapper

```swift
// Updated code with navigation
List(activities) { activity in
    NavigationLink(destination: ActivityDetailView(
        activity: activity,
        allActivities: activities  // Pass all activities for comparisons
    )) {
        ActivityRow(activity: activity)
    }
}
```

---

## Complete Example

Here's a complete example of how the activities section should look:

```swift
import SwiftUI

struct YourMainView: View {
    @State private var activities: [Activity] = []
    @State private var selectedView = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                // View picker
                Picker("View", selection: $selectedView) {
                    Text("Charts").tag(0)
                    Text("Table").tag(1)
                    Text("Activities").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                switch selectedView {
                case 0:
                    // Charts view
                    MemberStatsChartView(stats: memberStats)
                    
                case 1:
                    // Table view
                    MemberStatsTableView(stats: memberStats)
                    
                case 2:
                    // Activities list with navigation
                    List(activities) { activity in
                        NavigationLink(destination: ActivityDetailView(
                            activity: activity,
                            allActivities: activities
                        )) {
                            ActivityRow(activity: activity)
                        }
                    }
                    .listStyle(.plain)
                    
                default:
                    EmptyView()
                }
            }
            .navigationTitle("DCC Weekly Activities")
        }
    }
}
```

---

## What This Enables

With this change, when users tap on any activity in the list, they'll see:

✅ **Activity Details**
- Full activity information with icons
- Duration, distance, speed, elevation in cards

✅ **Personal Comparisons**
- How this activity compares to their own average
- Percentage differences with up/down indicators
- Visual feedback (green for better, red for worse)

✅ **Club Comparisons**
- How this activity compares to club average
- See if they're above/below average
- Percentage differences

✅ **Other Rides This Week**
- List of other rides by the same person
- Quick comparison between their rides
- Easy to see progression

---

## Alternative: If using TabView or Custom Layout

If your activities are in a `TabView` or custom layout:

```swift
TabView {
    // Charts tab
    MemberStatsChartView(stats: stats)
        .tabItem {
            Label("Charts", systemImage: "chart.bar.fill")
        }
    
    // Activities tab with navigation
    NavigationStack {
        List(activities) { activity in
            NavigationLink(destination: ActivityDetailView(
                activity: activity,
                allActivities: activities
            )) {
                ActivityRow(activity: activity)
            }
        }
        .navigationTitle("Activities")
    }
    .tabItem {
        Label("Activities", systemImage: "list.bullet")
    }
}
```

---

## Testing

After implementing:

1. ✅ Tap any activity in the list
2. ✅ Should navigate to detail view
3. ✅ Should show all statistics and comparisons
4. ✅ Back button should return to list
5. ✅ Should see other rides by the same member

---

## Notes

- The `allActivities` parameter is crucial — it's what enables comparisons
- Make sure your main view is wrapped in a `NavigationStack` or `NavigationView`
- The navigation happens automatically when user taps a row
- iOS will provide the back button automatically

---

## Preview

The detail view will look like this:

```
┌─────────────────────────────────┐
│  < Back      Activity Details   │
├─────────────────────────────────┤
│                                 │
│  🚴 Morning Hill Climb          │
│     John Doe                    │
│     Feb 21, 2026                │
│                                 │
│  ┌──────────┐  ┌──────────┐   │
│  │  45.5 km │  │  1h 30m  │   │
│  │  Distance│  │ Duration │   │
│  └──────────┘  └──────────┘   │
│                                 │
│  Compared to Your Average       │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━   │
│  Distance    ↑ 15.2%  +5.8 km  │
│  Speed       ↑ 8.5%   +2.3 km/h│
│  Elevation   ↓ 12.0%  -90 m    │
│                                 │
│  Compared to Club Average       │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━   │
│  Distance    ↑ 22.0%  +8.2 km  │
│  Speed       → 0.5%   +0.1 km/h│
│  Elevation   ↑ 45.0%  +200 m   │
│                                 │
│  Your Other Rides This Week     │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━   │
│  Evening Ride - Feb 20          │
│                    32.0 km      │
│  Recovery Spin - Feb 19         │
│                    20.5 km      │
│                                 │
└─────────────────────────────────┘
```

---

## Files Updated

- ✅ `MemberStatsChartView.swift` — Fixed bar chart annotations
- ✅ `MemberStatsChartView.swift` — Fixed pie chart percentages
- ✅ `StravaAPI.swift` — Fixed average speed calculation
- ✅ `ActivityDetailView.swift` — Already complete and ready
- ⏸️ Your main view — **Needs NavigationLink integration** (see above)

---

**Next Step**: Find where your activities are displayed in a List and add the NavigationLink wrapper as shown above!

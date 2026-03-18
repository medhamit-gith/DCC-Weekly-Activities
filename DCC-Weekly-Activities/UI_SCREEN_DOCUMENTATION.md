# UI Screen Documentation - Insights & What-If Analysis
## DCC Weekly Activities App
**Last Updated:** March 2, 2026  
**Version:** 2.0 (What-If Engine Integration)

---

## 📱 Overview

The **Insights Screen** provides riders with personalized performance analysis, visual comparisons, and actionable coaching tips powered by the What-If Engine. This screen helps riders understand their performance gaps and project the impact of training changes.

### Key Features
- 🎯 **Smart Gap Analysis** - Identifies performance gaps across 5 key metrics
- 🔮 **What-If Scenarios** - Projects impact of training changes with specific numbers
- 📊 **Visual Comparisons** - Charts showing distance, speed, elevation, and multi-dimensional radar view
- 💡 **Coaching Tips** - Personalized, data-driven recommendations with gap badges
- 🎉 **Celebration Moments** - Animated confetti and stats on rider selection

---

## 🏗️ Architecture Components

### Data Models

#### 1. **Activity** (`Models.swift`)
Represents a single ride/activity from Strava.

```swift
struct Activity {
    let memberName: String          // "Alice K."
    let activityName: String        // "Morning Ride"
    let distance: Double            // km
    let date: Date
    let averageSpeed: Double        // km/h
    let elevationGain: Double       // meters
    let movingTime: Int             // seconds
    let type: String                // "Ride", "VirtualRide", etc.
}
```

#### 2. **MemberStats** (`MemberStats.swift`)
Aggregated weekly statistics per member (lightweight model for overview screens).

```swift
struct MemberStats {
    let memberName: String
    let totalRides: Int
    let totalKM: Double
    let avgSpeed: Double
    let totalElevation: Double
    let rides: [Activity]           // Individual activities
    let previousWeekKM: Double
    let previousWeekRides: Int
}
```

#### 3. **RiderStats** (`RiderStats.swift`) 🆕
Enhanced analytics model with 30+ computed properties for deep insights and what-if scenarios.

**Core Metrics:**
- `totalDistanceKm`, `averageDistanceKm`, `longestRideKm`, `shortestRideKm`
- `averageSpeedKmh`, `maxSpeedKmh`, `speedConsistency`
- `totalElevationM`, `averageElevationPerRide`, `climbingFocus`
- `totalMovingTimeHours`, `averageRideDurationMinutes`
- `rideCount`, `sportTypeBreakdown`

**Performance Scores (0-1 normalized):**
- `normalizedDistance`, `normalizedSpeed`, `normalizedElevation`
- `normalizedConsistency`, `normalizedEfficiency`
- `averageEfficiencyScore` - Speed/elevation ratio

**What-If Helpers:**
- `projectedDistanceWith(extraRides: Int) -> Double`
- `distanceGapTo(leader: RiderStats) -> Double`
- `ridesNeededToMatch(leader: RiderStats) -> Int`
- `speedGapTo(leader: RiderStats) -> Double`
- `elevationGapTo(leader: RiderStats) -> Double`

#### 4. **GapAnalysis** (`WhatIfEngine.swift`) 🆕
Comparative analysis result between selected rider and leader.

```swift
struct GapAnalysis {
    let distanceGap: Double          // km behind leader
    let speedGap: Double             // km/h slower than leader
    let elevationGap: Double         // meters behind leader
    let rideCountGap: Int            // fewer rides than leader
    let ridesNeededToClose: Int      // at current average distance
    let weakestMetric: PerformanceMetric
    let strongestMetric: PerformanceMetric
    let clubRank: Int                // 1-indexed position
}
```

#### 5. **WhatIfResult** (`WhatIfEngine.swift`) 🆕
Projection result for hypothetical scenarios.

```swift
struct WhatIfResult {
    let scenario: String             // "If you ride 2 more times this week"
    let projectedDistance: Double    // New total km
    let distanceGain: Double         // Delta from current
    let newRank: Int?                // Projected rank (optional)
}
```

#### 6. **CoachingTip** (`WhatIfEngine.swift`) 🆕
Enhanced tip with embedded what-if projection.

```swift
struct CoachingTip {
    let icon: String                 // Emoji: "📏", "⚡", "⛰", "🗓", "🎯", "💪"
    let type: TipType                // .distance, .speed, .elevation, etc.
    let headline: String             // "So close! Just 2 more rides"
    let detail: String               // Full explanation with numbers
    let gapBadge: String?            // "-23.5km", "-340m", "-2 rides"
    let whatIf: WhatIfResult?        // Optional scenario projection
}
```

---

## 🎯 What-If Engine Logic

### Core Functions (`WhatIfEngine.swift`)

#### 1. **Gap Analysis**
```swift
static func analyzeGaps(
    rider: RiderStats,
    leader: RiderStats,
    allRiders: [RiderStats]
) -> GapAnalysis
```

**Algorithm:**
1. Calculate raw gaps: `leader.value - rider.value` for each metric
2. Compute rides needed: `ceil(distanceGap / rider.averageDistanceKm)`
3. Identify weakest metric using normalized scores (lowest = weakest)
4. Identify strongest metric using normalized scores (highest = strongest)
5. Calculate club rank based on total distance sorted descending

**Example Output:**
```
distanceGap: 34.5 km
speedGap: 2.3 km/h
elevationGap: 420 m
rideCountGap: 2 rides
ridesNeededToClose: 2
weakestMetric: .distance
strongestMetric: .elevation
clubRank: 4
```

#### 2. **What-If Scenarios**

##### **Extra Rides Projection**
```swift
static func whatIfExtraRides(
    _ count: Int,
    rider: RiderStats
) -> WhatIfResult
```

**Formula:**
```
projectedDistance = currentDistance + (count × averageDistanceKm)
distanceGain = count × averageDistanceKm
```

**Example:**
- Current: 100 km (4 rides at 25 km average)
- Scenario: 2 extra rides
- Projection: 150 km (+50 km gain)

##### **Faster Pace Projection**
```swift
static func whatIfFasterPace(
    extraKmh: Double,
    rider: RiderStats
) -> WhatIfResult
```

**Formula:**
```
currentTime = totalMovingTimeHours
newSpeed = averageSpeedKmh + extraKmh
projectedDistance = newSpeed × currentTime
distanceGain = projectedDistance - currentDistance
```

**Example:**
- Current: 100 km (5 hours at 20 km/h)
- Scenario: +2 km/h faster
- Projection: 110 km (+10 km gain from same time at 22 km/h)

##### **Longer Rides Projection**
```swift
static func whatIfLongerRides(
    extraKmPerRide: Double,
    rider: RiderStats
) -> WhatIfResult
```

**Formula:**
```
bonusDistance = rideCount × extraKmPerRide
projectedDistance = currentDistance + bonusDistance
```

**Example:**
- Current: 100 km (4 rides)
- Scenario: +10 km per ride
- Projection: 140 km (+40 km gain)

#### 3. **Coaching Tip Generation**
```swift
static func generateTips(
    gap: GapAnalysis,
    rider: RiderStats,
    leader: RiderStats
) -> [CoachingTip]
```

**Algorithm Decision Tree:**

```
1. Check weakest metric from gap analysis
   ↓
2. DISTANCE (weakest)
   ├─ If ridesNeededToClose ≤ 2:
   │  └─ "So close! Just N more ride(s)"
   │     → whatIf: extra rides scenario
   └─ Else:
      └─ "Ride more to close the gap"
         → whatIf: +1 ride scenario
   
3. SPEED (weakest)
   └─ "Push your average pace"
      → whatIf: faster pace scenario (min of gap or 2 km/h)
   
4. ELEVATION (weakest)
   └─ "Seek out hillier routes"
      → whatIf: nil (route selection, not projectable)
   
5. CONSISTENCY (weakest)
   └─ "More frequent rides wins"
      → whatIf: extra rides scenario (gap count)
   
6. EFFICIENCY (weakest)
   └─ "Maximise your time on the bike"
      → whatIf: nil (training methodology)

7. Always add positive reinforcement:
   └─ "Your strength: [strongestMetric]"
      → No what-if, just encouragement

8. Return first 2 tips
```

**Example Generated Tips:**

**Tip 1: Distance Gap (close)**
```
icon: "📏"
type: .distance
headline: "So close! Just 2 more rides"
detail: "You're 34.5km behind Alice K. One 40km ride would do it."
gapBadge: "-35km"
whatIf: {
    scenario: "If you ride 2 more times this week"
    projectedDistance: 168.0
    distanceGain: 50.0
    newRank: 2  // Computed by ViewModel
}
```

**Tip 2: Strength Reinforcement**
```
icon: "💪"
type: .strength
headline: "Your strength: Elevation"
detail: "You rank highly on elevation in the club. Build your training plan around this strength."
gapBadge: nil
whatIf: nil
```

---

## 🎨 UI Components

### 1. **InsightsView** (Main Container)
**File:** `InsightsView.swift`

**Layout Structure:**
```
NavigationStack
└─ ZStack
   ├─ Color.appBackground (full screen)
   └─ ScrollView
      └─ VStack(spacing: .lg)
         ├─ RiderChipSelector
         ├─ ConfettiBurstView (triggered)
         ├─ CelebrationCardView
         ├─ DistanceBarChart
         ├─ SpeedElevationScatter
         ├─ RadarChartView
         └─ CoachingTipsSection
```

**States:**
- Empty (0 riders): "No Data Yet"
- Insufficient (1 rider): "Need More Riders"
- Active (2+ riders): Full insights

**Interactions:**
- Rider chip tap → Trigger confetti + update all charts
- "View Full Analysis" button → Navigate to `RiderAnalysisView`

---

### 2. **CoachingTipCard** 🆕 UPDATED
**File:** `CoachingTipCard.swift`

**Visual Design:**
```
┌─────────────────────────────────────────┐
│ ▌ 📏 Close the Distance Gap    [-35km] │
│ ▌                                       │
│ ▌ You're 34.5km behind Alice K.        │
│ ▌ One 40km ride would do it.           │
│ ▌                                       │
│ ▌ ┌─ WHAT IF? ─────────────────────┐   │
│ ▌ │ ✨ If you ride 2 more times    │   │
│ ▌ │    this week          [+50km] │   │
│ ▌ └────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

**Layout:**
- Left: 4pt accent vertical bar
- Icon: 28pt emoji
- Content: VStack with headline, detail, what-if section
- Right: Gap badge (if present)

**What-If Section (NEW):**
- Background: Accent color at 5% opacity
- Border: Accent color at 20% opacity, 1pt
- Icon: "wand.and.stars" in accent color
- Scenario text: 13pt medium weight
- Gain badge: Accent capsule with "+Xkm" text

**Animation:**
- Card fades in + slides up 20pt
- Stagger delay: `index × 0.1` seconds
- Spring animation: `response: 0.4, dampingFraction: 0.7`

---

### 3. **CoachingTipsSection**
**File:** `CoachingTipCard.swift`

**Layout:**
```
┌────────────────────────────────────┐
│ 💡 Smart Coaching Tips       [?]   │  ← Header with help button
│                                    │
│ ┌─────────────────────────────┐   │
│ │ Tip Card 1                  │   │  ← CoachingTipCard #1
│ └─────────────────────────────┘   │
│                                    │
│ ┌─────────────────────────────┐   │
│ │ Tip Card 2                  │   │  ← CoachingTipCard #2
│ └─────────────────────────────┘   │
└────────────────────────────────────┘
```

**Behavior:**
- Shows exactly 2 tips max
- Tips regenerate on rider selection change
- Help button opens tooltip explaining tip types

---

## 🔄 User Flow with What-If Engine

### Scenario 1: Mid-Pack Rider Selects Themselves

**Step 1: Rider Selection**
```
User taps "Charlie M." chip
↓
System calculates:
- Charlie: 118 km, rank #4
- Leader (Alice): 152 km, rank #1
```

**Step 2: Gap Analysis**
```swift
let analysis = WhatIfEngine.analyzeGaps(
    rider: charlieStats,
    leader: aliceStats,
    allRiders: allRiderStats
)

// Returns:
GapAnalysis(
    distanceGap: 34.0,
    speedGap: 1.5,
    elevationGap: 120,
    rideCountGap: 1,
    ridesNeededToClose: 2,
    weakestMetric: .distance,
    strongestMetric: .elevation,
    clubRank: 4
)
```

**Step 3: Tip Generation**
```swift
let tips = WhatIfEngine.generateTips(
    gap: analysis,
    rider: charlieStats,
    leader: aliceStats
)

// Returns 2 tips:
// 1. Distance gap tip with what-if projection
// 2. Strength reinforcement (elevation)
```

**Step 4: What-If Calculation (for Tip #1)**
```swift
let whatIf = WhatIfEngine.whatIfExtraRides(
    2,  // ridesNeededToClose
    rider: charlieStats
)

// Returns:
WhatIfResult(
    scenario: "If you ride 2 more times this week",
    projectedDistance: 168.0,  // 118 + (2 × 25)
    distanceGain: 50.0,
    newRank: 2  // Would move from #4 → #2
)
```

**Step 5: Display to User**

Card shows:
```
┌──────────────────────────────────────────┐
│ ▌ 📏 So close! Just 2 more rides [-34km]│
│ ▌                                        │
│ ▌ You're 34.0km behind Alice K.         │
│ ▌ One 40km ride would do it.            │
│ ▌                                        │
│ ▌ ┌─ WHAT IF? ──────────────────────┐   │
│ ▌ │ ✨ If you ride 2 more times     │   │
│ ▌ │    this week          [+50km] │   │
│ ▌ │                                 │   │
│ ▌ │ New projected total: 168 km     │   │
│ ▌ │ Estimated new rank: #2 🥈       │   │
│ ▌ └─────────────────────────────────┘   │
└──────────────────────────────────────────┘
```

---

### Scenario 2: Leader Selects Themselves

**Step 1: Rider Selection**
```
User taps "Alice K." chip (current leader)
```

**Step 2: Leader Check**
```swift
func generateTips(for rider: MemberStats) -> [CoachingTip] {
    guard let leader = leader, leader.id != rider.id else {
        // User IS the leader
        return [
            CoachingTip(
                icon: "👑",
                type: .strength,
                headline: "Maintain Your Lead",
                detail: "You're at the top! Keep up...",
                gapBadge: nil,
                whatIf: nil
            )
        ]
    }
    // ... normal gap analysis
}
```

**Display:**
```
┌──────────────────────────────────────┐
│ ▌ 👑 Maintain Your Lead              │
│ ▌                                    │
│ ▌ You're at the top! Keep up the    │
│ ▌ great work to stay ahead.         │
│ ▌                                    │
│ ▌ (No what-if: already winning!)    │
└──────────────────────────────────────┘
```

---

## 📊 Integration Points

### Data Flow Diagram

```
┌─────────────────────────────────────────────────────┐
│ Strava API → Activities JSON                        │
└───────────────────────┬─────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ Models.swift: Parse to [Activity] structs           │
└───────────────────────┬─────────────────────────────┘
                        ↓
         ┌──────────────┴──────────────┐
         ↓                             ↓
┌─────────────────────┐   ┌─────────────────────────┐
│ MemberStats.swift   │   │ RiderStats.swift (NEW)  │
│ (aggregated weekly) │   │ (deep analytics)        │
└─────────┬───────────┘   └────────┬────────────────┘
          ↓                        ↓
┌─────────────────────────────────────────────────────┐
│ InsightsViewModel: Normalize & build radar data     │
└───────────────────────┬─────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ WhatIfEngine: Gap analysis + projections            │
└───────────────────────┬─────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ CoachingTipCard: Display with what-if visualizations│
└─────────────────────────────────────────────────────┘
```

---

## 🎨 Visual Design Specifications

### Colors
```swift
// Accent (primary interaction)
Color.accent                  // Saffron orange (#FF9500)
Color.accentSecondary         // Lighter variant

// Surfaces
Color.appBackground           // Dark gray (#121212)
Color.surface                 // Card background (#1C1C1E)
Color.surfaceElevated         // Elevated card (#2C2C2E)

// Text
Color.textPrimary             // White (#FFFFFF)
Color.textSecondary           // Gray (#8E8E93)

// Status
Color.error                   // Red for gap badges
```

### Spacing
```swift
Spacing.xs    // 4pt
Spacing.sm    // 8pt
Spacing.md    // 16pt
Spacing.lg    // 24pt
Spacing.xl    // 32pt
```

### Typography
```swift
.cardTitle          // 17pt, semibold
.bodyDefault        // 15pt, regular
.sectionTitle       // 20pt, bold
.caption            // 12pt, regular
```

### Corner Radius
```swift
CornerRadius.sm     // 4pt
CornerRadius.md     // 8pt
CornerRadius.lg     // 12pt
CornerRadius.xl     // 16pt
```

---

## 🧪 Testing Scenarios

### Test Case 1: Distance Gap (Close)
**Setup:**
- Rider: Bob (118 km, 5 rides, 23.6 km avg)
- Leader: Alice (152 km)
- Gap: 34 km

**Expected:**
```
Tip: "So close! Just 2 more rides"
What-If: "If you ride 2 more times this week"
Projection: +47.2 km (2 × 23.6)
```

### Test Case 2: Distance Gap (Far)
**Setup:**
- Rider: David (45 km, 2 rides, 22.5 km avg)
- Leader: Alice (152 km)
- Gap: 107 km

**Expected:**
```
Tip: "Ride more to close the gap"
What-If: "If you ride 1 more time this week"
Projection: +22.5 km
Note: Would need 5 rides total to match leader
```

### Test Case 3: Speed Gap
**Setup:**
- Rider: Charlie (20 km/h avg, 10 hours riding)
- Leader: Alice (22 km/h avg)
- Gap: 2 km/h

**Expected:**
```
Tip: "Push your average pace"
What-If: "Riding 2.0 km/h faster"
Projection: +20 km (from same 10 hours at 22 km/h vs 20 km/h)
```

### Test Case 4: Leader Selected
**Setup:**
- Rider: Alice (152 km, rank #1)
- Leader: Alice (same person)

**Expected:**
```
Tip: "Maintain Your Lead"
What-If: nil
No gap badges shown
```

### Test Case 5: Edge Case - Zero Rides
**Setup:**
- Rider: Eve (0 km, 0 rides)
- Leader: Alice (152 km)

**Expected:**
```
averageDistanceKm: 0
ridesNeededToMatch: 0 (division by zero prevented)
Tip: Generic encouragement "Keep Pushing!"
What-If: nil (cannot project from zero baseline)
```

---

## 🐛 Known Edge Cases & Handling

### 1. Division by Zero
**Scenario:** Rider has 0 rides or 0 moving time

**Protection:**
```swift
extension Double {
    var safeValue: Double {
        guard !self.isNaN && !self.isInfinite else { return 0 }
        return self
    }
}
```

All computed properties in `RiderStats` use `.safeValue` chaining.

### 2. Negative Gaps
**Scenario:** Selected rider is ahead of "leader" in some metric

**Protection:**
```swift
func distanceGapTo(leader: RiderStats) -> Double {
    max(0, leader.totalDistanceKm - totalDistanceKm).safeValue
}
```

Gaps are clamped to 0 minimum.

### 3. Empty Club
**Scenario:** 0 or 1 riders in club

**Handling:**
```swift
if stats.isEmpty {
    EmptyStateView(title: "No Data Yet")
} else if stats.count == 1 {
    EmptyStateView(title: "Need More Riders")
}
```

Comparisons disabled until 2+ riders exist.

### 4. Identical Stats (Tie)
**Scenario:** Two riders have exact same total distance

**Handling:**
```swift
.sorted { $0.totalDistanceKm > $1.totalDistanceKm }
```

Swift's sort is stable, preserving original order for ties.

---

## 📈 Future Enhancement Ideas

### Phase 2: Advanced What-If
- **Multi-metric optimization:** "What combination of changes gets you to #1?"
- **Time-based projections:** "If you maintain this pace for 30 days..."
- **Probability scoring:** "70% chance to reach #2 if you ride 3× this week"

### Phase 3: Historical Trends
- **Week-over-week comparisons:** Line charts showing progress
- **Personal records:** Badge when rider sets new PR
- **Momentum tracking:** "You're trending up +15% vs last month"

### Phase 4: Social Features
- **Share what-if scenarios:** "Challenge accepted! 🚴"
- **Group challenges:** "Club goal: 1000 km this week"
- **Achievements:** Unlock badges for milestones

### Phase 5: AI Coaching
- **Integration with Foundation Models:** Natural language coaching
- **Personalized training plans:** "Based on your climbing strength..."
- **Predictive insights:** "You usually ride Saturday mornings — don't forget!"

---

## 📝 Documentation for Product Owner

### Key Talking Points

#### For Stakeholders:
✅ **Zero changes to existing features** - Pure additive enhancement  
✅ **100% Swift/SwiftUI** - No external dependencies, native performance  
✅ **Data-driven insights** - Every recommendation backed by numbers  
✅ **Gamification** - Motivates riders with clear, achievable goals  

#### For Users:
✅ **Clear guidance** - No more guessing what to improve  
✅ **Actionable scenarios** - See exactly what X more rides would do  
✅ **Personal celebration** - Every rider gets their "moment" with confetti  
✅ **Positive reinforcement** - Always highlights strengths, not just gaps  

#### For Developers:
✅ **Clean architecture** - WhatIfEngine is pure logic, zero UI coupling  
✅ **Testable** - All functions are static, deterministic, unit-testable  
✅ **Extensible** - Easy to add new metrics or scenario types  
✅ **Type-safe** - Strongly-typed enums prevent invalid states  

---

## 🎯 Success Metrics to Track

### Engagement
- % of users who tap into Insights screen
- Avg time spent on Insights vs other tabs
- Rider selection interactions per session

### Behavioral Impact
- Do riders with "close gap" tips actually ride more next week?
- Correlation between viewing what-if scenarios and actual distance increase
- Retention of users who regularly check Insights

### Technical
- Screen load time (target: <500ms)
- Animation frame rate (target: 60fps)
- Crash rate in Insights flow (target: 0%)

---

## 🔐 Privacy & Data Handling

### Data Usage
- **All data stays on-device** - No backend analytics
- **Uses existing Strava data** - No additional permissions needed
- **No personal data stored** - Computations happen in-memory

### User Transparency
- What-if projections clearly labeled as "estimates"
- Gap comparisons only shown to authenticated club members
- No public leaderboards outside club context

---

## 📞 Support & Troubleshooting

### Common User Questions

**Q: "Why does my what-if projection seem low?"**  
A: Projections use your *current* average ride distance. If you've had shorter rides recently, the estimate will be conservative. This ensures realistic expectations.

**Q: "My rank didn't change after riding more. Why?"**  
A: Other riders may have also ridden more. The what-if shows *projected* rank if nobody else rides — actual rank depends on club activity.

**Q: "I'm the leader but still see gap badges?"**  
A: This is a bug. Leaders should only see "Maintain Your Lead" tip with no gap badges. Please report with screenshot.

**Q: "What-if section shows 'nil' / not appearing?"**  
A: Some tips don't have projections (e.g., "Seek hillier routes") because the improvement isn't quantifiable. This is expected behavior.

---

## 🚀 Deployment Checklist

### Pre-Release
- [ ] Verify all what-if formulas match design spec
- [ ] Test with 0, 1, 2, 10, 50 riders
- [ ] Test with riders having 0 rides (edge case)
- [ ] Verify no division-by-zero crashes
- [ ] Test confetti on low-end devices (performance)
- [ ] Test all tip types generate correctly
- [ ] Verify gap badges show correct values
- [ ] Test rapid rider switching (animation performance)

### Release Notes (User-Facing)
```
🆕 Smart What-If Scenarios
Now see exactly how many rides, or how much faster pace, 
would move you up the leaderboard! Each coaching tip shows 
a projection: "If you ride 2 more times this week: +50km"

🔮 Enhanced Coaching Tips
Tips now include specific numbers from your data and 
show you the exact gap to close (e.g., "-23.5km behind Alice").

📊 Performance Insights
New radar chart shows your strengths across 5 dimensions.
Build your training around what you do best!
```

---

## 📚 Related Documentation

- **Architecture Overview:** `ARCHITECTURE.md`
- **Build Fix Instructions:** `BUILD_FIX_INSTRUCTIONS.md`
- **Feature Summary:** `INSIGHTS_FEATURE_SUMMARY.md`
- **Code Files:**
  - `WhatIfEngine.swift` - Core analytics logic
  - `RiderStats.swift` - Enhanced data model
  - `CoachingTipCard.swift` - UI component
  - `InsightsView.swift` - Main screen
  - `InsightsViewModel.swift` - Presentation logic

---

**Document maintained by:** Engineering Team  
**Review frequency:** After each major feature release  
**Last reviewed:** March 2, 2026  
**Next review:** After user testing phase


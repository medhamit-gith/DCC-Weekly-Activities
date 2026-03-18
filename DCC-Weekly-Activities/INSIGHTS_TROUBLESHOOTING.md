# Insights Feature - Troubleshooting Guide

## 🔍 Common Issues & Solutions

### Build Errors

#### "Cannot find 'InsightsView' in scope"
**Cause:** File not added to target
**Fix:** 
1. Select `InsightsView.swift` in Project Navigator
2. Check "Target Membership" in File Inspector
3. Ensure your app target is checked

#### "Value of type 'MemberStats' has no member '...'"
**Cause:** Property name mismatch
**Fix:** 
- Double-check `MemberStats.swift` has: `totalKM`, `avgSpeed`, `totalElevation`, `totalRides`, `memberName`
- All property names must match exactly (case-sensitive)

#### "Extra argument 'stats' in call"
**Cause:** Wrong InsightsView initializer
**Fix:**
```swift
// Correct:
InsightsView(stats: stats, activities: activities)

// Not:
InsightsView(stats)
```

#### Charts module import error
**Fix:** Ensure you have `import Charts` at top of:
- `DistanceBarChart.swift`
- `SpeedElevationScatter.swift`

---

### Runtime Issues

#### Confetti doesn't appear
**Symptoms:** No particles on rider selection
**Diagnosis:**
1. Check console for errors
2. Verify `confettiTrigger` state is toggling
3. Ensure `TimelineView` is rendering

**Fix:**
```swift
// In InsightsView, verify this onChange:
.onChange(of: viewModel.selectedRiderName) { _, newValue in
    if newValue != nil {
        confettiTrigger.toggle() // This MUST toggle
    }
}
```

#### Charts are empty
**Symptoms:** Blank chart area, no bars/dots/polygons
**Diagnosis:**
1. Print `stats.count` in console
2. Check if `animateChart` state is true
3. Verify data isn't all zeros

**Fix:**
```swift
// Add debug prints:
.onAppear {
    print("📊 Stats count: \(stats.count)")
    print("📊 First rider: \(stats.first?.memberName ?? "none")")
    print("📊 First totalKM: \(stats.first?.totalKM ?? 0)")
}
```

#### Radar chart not drawing
**Symptoms:** Blank polygon area
**Diagnosis:**
1. Check if `animationProgress` reaches 1.0
2. Verify normalized values aren't NaN
3. Check canvas size is non-zero

**Fix:**
```swift
// In RadarChartView, add guards:
private func getRiderValues() -> [Double] {
    let values = [
        viewModel.normalizedDistance(for: rider),
        viewModel.normalizedSpeed(for: rider),
        // ...
    ]
    print("🕸 Rider values: \(values)")
    return values.map { $0.isNaN ? 0 : $0 } // Guard against NaN
}
```

#### Coaching tips show "nil"
**Symptoms:** Tips display "nil" or crash
**Diagnosis:**
1. Check if leader exists
2. Verify gap calculations don't divide by zero
3. Ensure string interpolation is correct

**Fix:**
```swift
// In InsightsViewModel.generateCoachingTips:
guard let leader = leader else {
    return [CoachingTip(/* fallback */)]
}
```

---

### Animation Issues

#### Animations feel janky
**Symptoms:** Stuttering, frame drops
**Causes:**
- Too many animations at once
- Heavy computation during animation
- Debug build (release is faster)

**Fix:**
```swift
// Stagger heavy animations:
DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    withAnimation(.easeOut(duration: 0.6)) {
        // Heavy work here
    }
}
```

#### Confetti lags on older devices
**Symptoms:** Particle animation stutters
**Fix:** Reduce particle count for older devices:
```swift
// In ConfettiBurstView.createBurst:
let particleCount = ProcessInfo.processInfo.processorCount > 4 ? 60 : 30
particles = (0..<particleCount).map { /* ... */ }
```

#### Celebration card doesn't slide up
**Symptoms:** Card appears instantly, no animation
**Diagnosis:**
1. Check `isVisible` state toggles
2. Verify `.onAppear` fires
3. Ensure animation isn't disabled system-wide

**Fix:**
```swift
// Force animation in CelebrationCardView:
.onAppear {
    DispatchQueue.main.async { // Ensure next run loop
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            isVisible = true
        }
    }
}
```

---

### Data Issues

#### All riders show rank #1
**Cause:** Stats not sorted correctly
**Fix:** Verify `InsightsViewModel.sortedStats`:
```swift
var sortedStats: [MemberStats] {
    stats.sorted { $0.totalKM > $1.totalKM } // Descending order
}
```

#### Coaching tips make no sense
**Cause:** Incorrect gap calculations
**Debug:**
```swift
func generateCoachingTips(for rider: MemberStats) -> [CoachingTip] {
    guard let leader = leader else { return [] }
    
    let distanceGap = leader.totalKM - rider.totalKM
    print("📏 Distance gap for \(rider.memberName): \(distanceGap)")
    // Should be positive if they're behind
    
    // ...
}
```

#### Normalized values are all 1.0 or 0.0
**Cause:** Max value is zero or calculation error
**Fix:**
```swift
func normalizedDistance(for rider: MemberStats) -> Double {
    let max = stats.map(\.totalKM).max() ?? 1
    guard max > 0 else { return 0 }
    return rider.totalKM / max
}
```

#### Scatter plot dots are all in corner
**Cause:** Axis range too narrow or values are identical
**Fix:** Add padding to axis domain:
```swift
.chartXScale(domain: .automatic(includesZero: false))
.chartYScale(domain: .automatic(includesZero: false))
```

---

### UI Layout Issues

#### Content cuts off at bottom
**Cause:** Missing bottom padding in ScrollView
**Fix:**
```swift
ScrollView {
    VStack(spacing: Spacing.lg) {
        // ...
    }
    .padding(.vertical, Spacing.md)
    .padding(.bottom, Spacing.xl) // ← Add extra bottom padding
}
```

#### Rider chips overflow screen
**Cause:** HStack not scrolling
**Fix:** Verify ScrollView:
```swift
ScrollView(.horizontal, showsIndicators: false) { // ← Must be horizontal
    HStack(spacing: Spacing.sm) {
        // Chips
    }
}
```

#### Charts overlap on small screens
**Cause:** Fixed heights too large
**Fix:** Use dynamic heights:
```swift
.frame(height: min(300, geometry.size.height * 0.4))
```

#### Text labels truncated
**Cause:** Fixed frame widths
**Fix:**
```swift
Text(rider.memberName)
    .lineLimit(1)
    .minimumScaleFactor(0.8) // ← Allows shrinking
    .fixedSize(horizontal: false, vertical: true)
```

---

### Performance Issues

#### Slow initial load
**Diagnosis:** Measure with Instruments
**Common causes:**
1. Computing normalized values for many riders
2. Sorting large arrays multiple times
3. Rendering all charts at once

**Fix:** Lazy loading:
```swift
LazyVStack {
    DistanceBarChart(/* ... */)
    SpeedElevationScatter(/* ... */)
    RadarChartView(/* ... */)
}
```

#### Memory warning on device
**Diagnosis:** Check Memory graph in Xcode
**Fix:** Clear particles after animation:
```swift
// In ConfettiBurstView:
DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
    particles.removeAll() // ← Crucial
}
```

#### High CPU during scrolling
**Cause:** Animating while scrolling
**Fix:** Pause animations during scroll:
```swift
@State private var isScrolling = false

ScrollViewReader { proxy in
    ScrollView {
        // Content
    }
    .onScrollPhaseChange { oldPhase, newPhase in
        isScrolling = (newPhase == .interacting)
    }
}
```

---

### Integration Issues

#### "Analysis" tab doesn't appear
**Diagnosis:**
1. Check `DashboardTab` enum has `.analysis` case
2. Verify switch statement handles `.analysis`
3. Ensure tab icon is valid SF Symbol

**Fix:**
```swift
enum DashboardTab: String, CaseIterable {
    case overview = "Overview"
    case leaderboard = "Leaderboard"
    case insights = "Insights"
    case analysis = "Analysis" // ← Must be here
}
```

#### Tab bar icon missing
**Cause:** Invalid SF Symbol name
**Fix:**
```swift
var icon: String {
    case .analysis: return "chart.bar.xaxis.ascending" // ← Valid symbol
}
```

#### Stats not updating in Insights
**Cause:** Not passing updated data
**Fix:**
```swift
// In ProfessionalDashboardView:
case .analysis:
    InsightsView(stats: stats, activities: activities)
        .id(stats.count) // ← Force refresh when stats change
```

---

## 🐛 Debug Helpers

### Add these to InsightsView during development:

```swift
#if DEBUG
.onAppear {
    print("📊 Insights loaded")
    print("   Stats count: \(stats.count)")
    print("   Activities count: \(activities.count)")
    print("   Selected rider: \(viewModel.selectedRiderName ?? "none")")
}
.onChange(of: stats) { old, new in
    print("📊 Stats updated: \(old.count) → \(new.count)")
}
.onChange(of: viewModel.selectedRiderName) { old, new in
    print("👤 Rider changed: \(old ?? "nil") → \(new ?? "nil")")
}
#endif
```

### Add to Charts for debugging:

```swift
.onAppear {
    #if DEBUG
    print("📈 Chart data:")
    for (i, rider) in stats.enumerated() {
        print("   \(i+1). \(rider.memberName): \(rider.totalKM)km")
    }
    #endif
}
```

### Add to ConfettiBurstView:

```swift
private func createBurst() {
    #if DEBUG
    print("🎉 Confetti burst: \(particles.count) particles")
    #endif
    
    // ... particle creation
}
```

---

## ✅ Verification Checklist

Before reporting an issue, verify:

- [ ] All 9 files created and added to target
- [ ] `import Charts` in chart files
- [ ] `RootView.swift` has `.analysis` case
- [ ] Build succeeds with no warnings
- [ ] Stats array has 2+ riders
- [ ] All riders have non-zero totalKM
- [ ] Device has sufficient iOS version (17+)
- [ ] Dark mode is active
- [ ] No other compilation errors in project

---

## 🆘 Still Stuck?

### Gather this info before asking for help:

1. **Xcode version:** [e.g., 15.2]
2. **iOS deployment target:** [e.g., 17.0]
3. **Simulator/device:** [e.g., iPhone 15 Pro]
4. **Stats count:** [e.g., 5 riders]
5. **Console errors:** [paste full error]
6. **Steps to reproduce:** [numbered list]
7. **Expected vs actual:** [what should happen vs what does]

### Quick self-diagnostics:

```swift
// Add to InsightsView.mainContent:
VStack {
    Text("Debug Info")
    Text("Stats: \(stats.count)")
    Text("Selected: \(viewModel.selectedRiderName ?? "nil")")
    Text("Sorted: \(viewModel.sortedStats.count)")
    if let rider = viewModel.selectedRider {
        Text("Rank: \(viewModel.rank(for: rider))")
        Text("Distance: \(rider.totalKM)")
    }
}
.font(.caption)
.foregroundStyle(.red)
```

---

## 🔧 Advanced Fixes

### Reset all animations on tab switch:

```swift
// In InsightsView:
@State private var resetID = UUID()

var body: some View {
    NavigationStack {
        // ... content
    }
    .id(resetID)
    .onAppear {
        resetID = UUID() // Forces full view refresh
    }
}
```

### Fix confetti not centering:

```swift
// In InsightsView confetti positioning:
GeometryReader { geometry in
    ConfettiBurstView(trigger: confettiTrigger)
        .position(x: geometry.size.width / 2, y: 0)
}
.frame(height: 1)
```

### Fix radar chart rotation:

```swift
// In RadarChartView drawPolygon:
let angle = (Double(index) / Double(values.count)) * 2 * .pi - .pi / 2
// The -π/2 rotates so first axis points up
```

---

## 📚 Reference

### Key State Variables:

| File | Variable | Type | Purpose |
|------|----------|------|---------|
| InsightsView | `viewModel` | `InsightsViewModel` | Central logic |
| InsightsView | `confettiTrigger` | `Bool` | Toggle for burst |
| InsightsViewModel | `selectedRiderName` | `String?` | Current selection |
| CelebrationCardView | `isVisible` | `Bool` | Animation state |
| DistanceBarChart | `animateChart` | `Bool` | Trigger animation |
| RadarChartView | `animationProgress` | `Double` | 0-1 draw progress |

### Critical Functions:

| Function | Returns | Purpose |
|----------|---------|---------|
| `rank(for:)` | `Int` | Calculate rider rank |
| `normalizedDistance(for:)` | `Double` | 0-1 normalized value |
| `generateCoachingTips(for:)` | `[CoachingTip]` | Smart tips array |
| `topAchievement(for:)` | `String` | Best metric string |

---

**Most issues are solved by:**
1. Clean build (Cmd+Shift+K)
2. Restart Xcode
3. Check property names match exactly
4. Verify stats array has valid data
5. Read console error messages carefully

Good luck! 🚀

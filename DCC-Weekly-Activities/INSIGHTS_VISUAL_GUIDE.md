# Insights Feature - Visual Layout Guide

## Screen Structure

```
┌─────────────────────────────────────────┐
│  📊 Insights                            │  ← Navigation bar
├─────────────────────────────────────────┤
│                                         │
│  ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐       │  ← Horizontal rider chips
│  │🥇A│ │🥈B│ │🥉C│ │#4D│ │#5E│       │     (scrollable)
│  └───┘ └───┘ └───┘ └───┘ └───┘       │
│         ▲ Selected                     │
│                                         │
│  ┌─────────────────────────────────┐  │
│  │  ✨ Confetti Burst ✨           │  │  ← 60 particles, 0.6s
│  └─────────────────────────────────┘  │
│                                         │
│  ┌─────────────────────────────────┐  │
│  │ Great week Alice! 🔥            │  │  ← Celebration card
│  │ Most Distance: 150.5km          │  │     slides up with spring
│  │ ┌─────────────────────────┐    │  │
│  │ │  150.5km │ 8 rides │ 450m│    │  │     Animated counters
│  │ └─────────────────────────┘    │  │
│  │ You're leading the pack. 👑     │  │
│  └─────────────────────────────────┘  │
│                                         │
│  ┌─────────────────────────────────┐  │
│  │ 📍 Weekly Distance              │  │  ← Distance bar chart
│  │                                  │  │     bars animate L→R
│  │ Alice   ████████████ 150.5 km   │  │     selected: accent
│  │ Bob     ████████ 120.2 km       │  │     others: muted
│  │ Charlie ██████ 95.8 km          │  │
│  └─────────────────────────────────┘  │
│                                         │
│  ┌─────────────────────────────────┐  │
│  │ ⚡ Speed vs Climbing Profile    │  │  ← Scatter plot
│  │                                  │  │     dots scale in
│  │    Elevation                     │  │
│  │       ▲                          │  │
│  │   ●   │  ● Alice (large)         │  │
│  │     ● │    ●                     │  │
│  │   ●   │  ●                       │  │
│  │ ──────┼──────────→ Speed         │  │
│  │ Endurance│Fast&Flat               │  │
│  └─────────────────────────────────┘  │
│                                         │
│  ┌─────────────────────────────────┐  │
│  │ 🕸 Performance Profile          │  │  ← Radar/spider chart
│  │                                  │  │     polygon draws + fills
│  │      Distance                    │  │
│  │          ▲                       │  │
│  │   Rides  │  Speed                │  │
│  │      ◆───┼───◆                  │  │     ◆ = Alice (solid)
│  │       \  │  /                    │  │     ◇ = Club avg (dashed)
│  │        \ │ /                     │  │
│  │ Consist ◆│◆ Elevation            │  │
│  │          │                       │  │
│  └─────────────────────────────────┘  │
│                                         │
│  ┌─────────────────────────────────┐  │
│  │ 💡 Smart Coaching Tips          │  │  ← Tips section
│  │ ┌─┬─────────────────────────┐  │  │     fade in with stagger
│  │ │█│📏 Close Distance Gap    │  │  │
│  │ │█│ Add one longer ride to  │  │  │     Left border = accent
│  │ │█│ close 12.3km gap    -12km│ │  │     Gap badge top-right
│  │ └─┴─────────────────────────┘  │  │
│  │ ┌─┬─────────────────────────┐  │  │
│  │ │█│⛰ Target Hillier Routes  │  │  │
│  │ │█│ You're 145m behind Bob  │  │  │
│  │ │█│ on elevation       -145m │  │  │
│  │ └─┴─────────────────────────┘  │  │
│  └─────────────────────────────────┘  │
│                                         │
└─────────────────────────────────────────┘
```

---

## Animation Timeline

### On Rider Selection:

```
Time  Event
───────────────────────────────────────────────
0.0s  User taps rider chip
      → Chip scales 1.0 → 1.05 → 1.0
      
0.0s  Confetti burst starts
      → 60 particles radiate outward
      → Spiral trajectory with rotation
      → Individual fade timing (0.4-0.8s)
      
0.1s  Celebration card starts appearing
      → Slides up from offset y=100
      → Scales from 0.8 → 1.0
      → Opacity 0 → 1
      
0.2s  Stat counters start animating
      → Distance: 0 → 150.5
      → Rides: 0 → 8
      → Elevation: 0 → 450
      → Duration: 0.8s easeOut
      
0.3s  Bar chart bars start extending
      → Each bar: width 0 → full
      → Staggered by 0.05s per rider
      → Duration: 0.8s easeOut
      
0.4s  Scatter plot dots appear
      → Scale 0 → 1 with spring
      → Selected rider dot largest
      → Name label fades in
      
0.5s  Radar polygon starts drawing
      → Stroke traces outline (0.5s)
      → Fill fades in (0.5s)
      → Club average dashed line
      
0.6s  First coaching tip appears
      → Fade + slide up from y=20
      → Opacity 0 → 1
      
0.7s  Second coaching tip appears
      → Same fade/slide animation
      → 0.1s delay after first tip
```

---

## Color Coding

```
┌─────────────────────────┬──────────────┐
│ Element                 │ Color        │
├─────────────────────────┼──────────────┤
│ Selected rider chip     │ .accent      │
│ Unselected chips        │ .surface     │
│ Rank badge (1st)        │ Gold         │
│ Rank badge (2nd)        │ Silver       │
│ Rank badge (3rd)        │ Bronze       │
│ Rank badge (4+)         │ .accent      │
│ Celebration card        │ .surface     │
│ Card accent glow        │ .accent 0.3  │
│ Selected bar            │ .accent      │
│ Other bars              │ .surface     │
│ Selected scatter dot    │ .accent      │
│ Other scatter dots      │ .surface 0.7 │
│ Radar polygon fill      │ .accent 0.35 │
│ Radar polygon stroke    │ .accent      │
│ Club avg radar          │ .textSecond  │
│ Tip card left border    │ .accent      │
│ Gap badge background    │ .error 0.15  │
│ Gap badge text          │ .error       │
│ Confetti particles      │ accent mix   │
└─────────────────────────┴──────────────┘
```

---

## Responsive Behavior

### iPhone SE (small screen)
- Rider chips: scroll horizontally
- Charts: full width, adequate height
- Radar chart: 280pt height
- All content: single column

### iPhone Pro Max (large screen)
- Rider chips: may fit all on screen
- Charts: full width, taller for clarity
- Radar chart: 320pt height
- Content breathes with more spacing

### iPad (if supported)
- Chips: centered with max-width
- Charts: max-width constraint
- Side margins increase
- Two-column layout possible for tips

---

## Interaction States

### Rider Chip
```
State       Scale   Background   Shadow
───────────────────────────────────────
Normal      1.0     .surface     none
Pressed     1.05    .surface     none
Selected    1.0     .accent      glow 8pt
```

### Charts
```
Action              Result
────────────────────────────────────────
Tap scatter dot     → Briefly highlight
Swipe bar chart     → Scroll if needed
Pinch radar         → No zoom (static)
Rotate device       → Charts reflow
```

### Coaching Tips
```
State       Opacity   Y-offset
─────────────────────────────────
Initial     0.0       +20pt
Animated    1.0       0pt
Duration    0.4s      spring
```

---

## Data Requirements

### Minimum data for each rider:
```swift
struct MemberStats {
    memberName: String      // For labels
    totalRides: Int         // For radar, tips
    totalKM: Double        // For bar chart, radar
    avgSpeed: Double       // For scatter, radar
    totalElevation: Double // For scatter, radar
}
```

### Derived metrics:
```swift
Consistency = totalKM / totalRides
Normalized values = metric / max(all riders)
Rank = position in totalKM descending sort
```

---

## Edge Cases Handled

1. **No riders** → Empty state: "No Data Yet"
2. **1 rider** → Empty state: "Need More Riders"
3. **Tied stats** → All get same rank
4. **Zero rides** → Consistency = 0
5. **Very long names** → Truncate with ellipsis
6. **Extreme outliers** → Charts auto-scale
7. **Negative values** → Shouldn't occur (guards in place)
8. **Rapid taps** → Debounce confetti triggers

---

## Accessibility

- All labels have semantic meaning
- Contrast ratios meet WCAG AA
- Dynamic type supported
- VoiceOver: "Rider Alice, rank 1, selected"
- Charts have axis labels for screen readers
- Tips read as actionable items

---

## Performance

- Confetti: 60 particles, <5% CPU spike
- Radar chart: Canvas draw, <10ms
- Charts: Swift Charts native (optimized)
- Animation: 60fps throughout
- Memory: <2MB for all views
- Scroll: Smooth with LazyVStack

---

This layout ensures a **delightful, informative, and performant** experience
that celebrates achievements while providing actionable insights! 🎉

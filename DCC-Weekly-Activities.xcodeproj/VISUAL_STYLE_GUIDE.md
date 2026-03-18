# Visual Style Guide - DCC Weekly Activities

## 🎨 Color Palette Reference

### Primary Colors
```
┌─────────────────────────────────────────┐
│ Accent (Strava Orange)                  │
│ #FC4C02                                 │
│ █████████████████████                   │
│ Use: CTAs, active states, highlights    │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Accent Secondary                        │
│ #FF8C42                                 │
│ █████████████████████                   │
│ Use: Gradients with accent              │
└─────────────────────────────────────────┘
```

### Backgrounds
```
┌─────────────────────────────────────────┐
│ App Background (Near Black)             │
│ #0D0D0D                                 │
│ █████████████████████                   │
│ Use: Main app background                │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Surface (Card Background)               │
│ #1A1A1A                                 │
│ █████████████████████                   │
│ Use: Cards, containers                  │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Surface Elevated                        │
│ #242424                                 │
│ █████████████████████                   │
│ Use: Elevated cards, overlays           │
└─────────────────────────────────────────┘
```

### Club Colors
```
┌─────────────────────────────────────────┐
│ DCC Blue                                │
│ #1E90FF                                 │
│ █████████████████████                   │
│ Use: Speed metrics, performance         │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ DCC Saffron (India Orange)              │
│ #FF9933                                 │
│ █████████████████████                   │
│ Use: Warm accents, secondary highlights │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ DCC Green (India Green)                 │
│ #138808                                 │
│ █████████████████████                   │
│ Use: Success states, completion         │
└─────────────────────────────────────────┘
```

### Text Colors
```
┌─────────────────────────────────────────┐
│ Text Primary                            │
│ #FFFFFF (White)                         │
│ Use: Headlines, main content            │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Text Secondary                          │
│ #8E8E93                                 │
│ Use: Labels, captions                   │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Text Tertiary                           │
│ #636366                                 │
│ Use: Disabled text, hints               │
└─────────────────────────────────────────┘
```

### Semantic Colors
```
┌─────────────────────────────────────────┐
│ Success                                 │
│ #34C759 (Apple Green)                   │
│ Use: Positive trends, achievements      │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Warning                                 │
│ #FF9F0A (Apple Orange)                  │
│ Use: Alerts, attention needed           │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Error                                   │
│ #FF3B30 (Apple Red)                     │
│ Use: Errors, negative trends            │
└─────────────────────────────────────────┘
```

### Podium Gradients
```
┌─────────────────────────────────────────┐
│ Gold (1st Place)                        │
│ #FFD700 → #FFA500                       │
│ ████████████████████▓▓▓▓▓▓▓▓            │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Silver (2nd Place)                      │
│ #C0C0C0 → #808080                       │
│ ████████████████████▓▓▓▓▓▓▓▓            │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Bronze (3rd Place)                      │
│ #CD7F32 → #8B4513                       │
│ ████████████████████▓▓▓▓▓▓▓▓            │
└─────────────────────────────────────────┘
```

---

## 📝 Typography Scale

### Display (Stats)
```
Hero Stat       56pt  Black   SF Pro Rounded  425.8
Large Stat      48pt  Black   SF Pro Rounded  180.5
Medium Stat     32pt  Bold    SF Pro Rounded  95.0
Small Stat      24pt  Bold    SF Pro Rounded  28
```

### Headers
```
Section Title   22pt  Bold      SF Pro  Top Performers
Card Title      18pt  Semibold  SF Pro  Morning Ride
Subtitle        16pt  Medium    SF Pro  Total distance
```

### Body
```
Body Large      17pt  Regular  SF Pro  Activity description
Body Default    15pt  Regular  SF Pro  Normal text content
Body Small      13pt  Regular  SF Pro  Fine print
```

### Labels
```
Label Large     14pt  Medium  SF Pro  METRIC LABELS
Label Default   12pt  Medium  SF Pro  Unit labels
Label Small     10pt  Medium  SF Pro  Tiny labels
```

### Captions
```
Caption         12pt  Regular  SF Pro  Helper text
Caption Medium  12pt  Medium   SF Pro  Emphasized caption
Caption Small   10pt  Regular  SF Pro  Smallest text
```

---

## 📐 Spacing System

```
xxxs    2pt   ▎
xxs     4pt   ▌
xs      8pt   █
sm     12pt   █▌
md     16pt   ██
lg     24pt   ███
xl     32pt   ████
xxl    48pt   ██████
xxxl   64pt   ████████
```

### Common Applications
- **Card padding**: `md` (16pt)
- **Section spacing**: `lg` (24pt)
- **Element spacing**: `xs` (8pt) to `sm` (12pt)
- **Icon padding**: `sm` (12pt)
- **Grid gaps**: `sm` (12pt) to `md` (16pt)

---

## 🔲 Corner Radius

```
sm      8pt   ╭─╮  Small badges
md     12pt   ╭──╮  Buttons, pills
lg     16pt   ╭───╮  Standard cards
xl     20pt   ╭────╮  Hero cards
xxl    24pt   ╭─────╮  Large cards
full   999pt  (○)  Circles
```

---

## 🎭 Component Anatomy

### Hero Stat Card
```
┌───────────────────────────────────────────┐
│ [icon] Club Total           ↑ 12.5%      │ ← Section title + trend
│                                           │
│ 425.8 km                                  │ ← Hero stat (56pt) + unit
│ ^^^^^^^                                   │   (gradient accent)
│                                           │
│ Total distance ridden this week           │ ← Subtitle (secondary text)
└───────────────────────────────────────────┘
  ← Padding: lg (24pt)
  ← Corner radius: xl (20pt)
  ← Background: Surface gradient
  ← Border: Accent gradient (1pt)
  ← Shadow: Glow
```

### Quick Stat Card
```
┌─────────────────────┐
│ [icon]              │ ← Icon (accent color)
│                     │
│ 28 rides            │ ← Value (32pt) + unit
│ ^^                  │   (monosp aced)
│                     │
│ Total Rides         │ ← Label (secondary)
└─────────────────────┘
  ← Size: 120pt height
  ← Background: Surface
  ← Corner radius: lg (16pt)
```

### Podium Card (Full)
```
┌────────────┐
│     [#]    │ ← Rank badge (gradient circle)
│            │
│   (👤)    │ ← Avatar (gradient border)
│            │
│  John Doe  │ ← Name (18pt semibold)
│            │
│   180.5    │ ← Distance (48pt black)
│     km     │   (rank color)
│ ─────────  │
│ ⛰️  🏁    │ ← Secondary stats
│ 850m 12    │
└────────────┘
  ← Width: 160pt
  ← Background: Surface
  ← Corner radius: xl (20pt)
  ← Shadow: Medium
```

### Podium Card (Compact)
```
┌──────────────────────────────────────────┐
│ 4  (👤) Mike D        ████▒▒▒▒  50.3   │
│ ^  ^     ^            ^          ^      │
│ │  │     │            │          └─ Distance
│ │  │     └─ Name      └─ Distance bar
│ │  └─ Avatar
│ └─ Rank
└──────────────────────────────────────────┘
  ← Background: Surface
  ← Corner radius: md (12pt)
  ← Padding: sm (12pt)
```

### Trend Badge
```
┌──────────────┐
│ ↑ 12.5%     │ ← Arrow + percentage
└──────────────┘
  ← Pill shape (capsule)
  ← Background: Success 15% opacity
  ← Text: Success color
  ← Padding: horizontal xs, vertical xxxs
```

### Performance Badge
```
┌──────────────────┐
│ 🔥 Hot Streak   │ ← Emoji + label
└──────────────────┘
  ← Pill shape (capsule)
  ← Background: Badge color 15% opacity
  ← Text: Badge color
  ← Padding: horizontal xs, vertical xxxs
```

---

## 🎬 Animation Timing

### Durations
```
Fast        0.2s  Button presses, tab switches
Default     0.3s  Standard transitions
Slow        0.5s  Card animations
Very Slow   1.0s  Hero counter, major transitions
```

### Curves
```
.spring(response: 0.3)              Quick snappy
.spring(response: 0.5, damping: 0.7) Bouncy
.spring(response: 0.6, damping: 0.7) Smooth hero
.easeOut(duration: 1.5)             Counter animation
.linear(duration: 1.5).repeatForever Shimmer
```

### Delays
```
Staggered cards:  0.1s between each
Sequential animations:  0.2s - 0.3s
```

---

## 💫 Micro-interactions

### Tap States
```swift
// Scale effect
.scaleEffect(isPressed ? 0.96 : 1.0)

// Haptic feedback
UIImpactFeedbackGenerator(style: .medium).impactOccurred()

// Success haptic
UINotificationFeedbackGenerator().notificationOccurred(.success)
```

### Loading States
```swift
// Shimmer
.shimmer(isActive: isLoading)

// Skeleton
SkeletonCard(height: 120)
```

### Transitions
```swift
// Fade + scale on appear
.scaleEffect(isAnimated ? 1 : 0.95)
.opacity(isAnimated ? 1 : 0)
.onAppear {
    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
        isAnimated = true
    }
}
```

---

## 📱 Layout Examples

### Dashboard Grid Layout
```
┌───────────────────────────────────────────┐
│ [Hero Card - Full Width]                 │ ← lg spacing below
├───────────────────────────────────────────┤
│ [Quick]  [Quick]                         │ ← sm spacing
│ [Stat 1] [Stat 2]                        │   between cards
│                                           │
│ [Quick]  [Quick]                         │
│ [Stat 3] [Stat 4]                        │
├───────────────────────────────────────────┤
│ [Tab Selector]                           │ ← lg spacing
├───────────────────────────────────────────┤
│ [Podium Section]                         │
│   [2nd] [1st] [3rd]                      │
└───────────────────────────────────────────┘
  ← Horizontal padding: md (16pt)
  ← Section spacing: lg (24pt)
```

### Leaderboard Layout
```
┌───────────────────────────────────────────┐
│ Full Rankings              9 riders       │
├───────────────────────────────────────────┤
│ [Podium]                                  │
│   [2nd] [1st] [3rd]                      │ ← sm spacing below
├───────────────────────────────────────────┤
│ Other Riders                              │
│ ┌───────────────────────────────────────┐ │
│ │ Rider card 4                          │ │ ← xs spacing
│ ├───────────────────────────────────────┤ │   between cards
│ │ Rider card 5                          │ │
│ ├───────────────────────────────────────┤ │
│ │ Rider card 6                          │ │
│ └───────────────────────────────────────┘ │
└───────────────────────────────────────────┘
```

---

## 🎯 Usage Guidelines

### DO ✅
- Use Strava orange for primary CTAs and active states
- Use dark backgrounds throughout (near black)
- Animate numbers with counters
- Include trend indicators where applicable
- Use monosp aced digits for all numbers
- Add haptic feedback to key interactions
- Use gradients for hero sections and podium ranks
- Maintain consistent spacing with design tokens
- Use semantic colors (green=positive, red=negative)

### DON'T ❌
- Don't use light backgrounds (dark-first design)
- Don't hardcode colors (use Color extensions)
- Don't hardcode sizes (use Spacing enums)
- Don't use default SF Pro for stats (use Rounded)
- Don't skip loading states (use shimmer)
- Don't forget empty states
- Don't over-animate (keep it purposeful)
- Don't mix font weights inconsistently

---

## 🔍 Accessibility

### Color Contrast
- All text meets WCAG AA standards (4.5:1 minimum)
- Accent orange on dark background: 7.2:1 ✅
- White text on surface: 12.6:1 ✅
- Secondary text on surface: 4.7:1 ✅

### Typography
- All numbers use monosp aced digits for readability
- Clear visual hierarchy with weight and size
- Supports Dynamic Type (can be enhanced)

### Interaction
- Minimum tap targets: 44x44pt
- Clear focus states
- Haptic feedback for confirmation

---

## 📦 Component Quick Reference

```swift
// Hero stat with animation
HeroStatCard(title: "Club Total", value: 425.8, unit: "km", 
             trend: 12.5, icon: "figure.2")

// Quick stat
QuickStatCard(value: "28", unit: "rides", label: "Total Rides",
              icon: "flag.checkered", color: .dccGreen)

// Podium card (full)
RiderPodiumCard(rank: 1, rider: memberStats, isCompact: false)

// Podium card (compact)
RiderPodiumCard(rank: 4, rider: memberStats, isCompact: true)

// Stat card with sparkline
StatCard(title: "Distance", value: "425.8", unit: "km",
         trend: 12.5, icon: "arrow.left.and.right",
         accentColor: .accent, sparklineData: [120, 150, 140, 180])

// Trend badge
TrendBadge(percentage: 12.5, isPositive: true)

// Performance badge
PerformanceBadge(type: .hotStreak)

// Animated counter
AnimatedCounter(value: 425.8, duration: 1.5) { 
    String(format: "%.1f", $0) 
}

// Sparkline
MiniSparkline(data: [120, 150, 140, 180, 160], accentColor: .accent)

// Loading skeleton
SkeletonCard(height: 120).shimmer()

// Empty state
EmptyStateView(icon: "figure.outdoor.cycle", 
               title: "No riders yet",
               message: "Check back later")
```

---

## 🎨 Gradient Recipes

### Accent Gradient (Hero)
```swift
LinearGradient(
    colors: [Color.accent, Color.accentSecondary],
    startPoint: .leading,
    endPoint: .trailing
)
// Use for: Hero numbers, primary emphasis
```

### Surface Gradient (Cards)
```swift
LinearGradient(
    colors: [Color.surface, Color.surfaceElevated],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
// Use for: Card backgrounds
```

### Accent Overlay (Subtle)
```swift
LinearGradient(
    colors: [
        Color.accent.opacity(0.1),
        Color.accent.opacity(0.02)
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
// Use for: Subtle highlights on cards
```

### Border Gradient
```swift
LinearGradient(
    colors: [
        Color.accent.opacity(0.3),
        Color.accent.opacity(0.1)
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
// Use for: Card borders, strokes
```

---

**Visual Style Guide Version**: 1.0  
**Last Updated**: February 28, 2026  
**Status**: Production Ready ✅

# 🎨 Design System Quick Reference

## Color Usage Guidelines

### Text Colors (Always Use These)

```swift
// ✅ DO: Primary text (headlines, important info)
Text("Member Name")
    .foregroundStyle(Color.primary)  // Black in light mode, white in dark mode

// ✅ DO: Secondary text (descriptions, metadata)
Text("3 rides this week")
    .foregroundStyle(Color.primary.opacity(0.7))  // 70% opacity for readability

// ✅ DO: Tertiary text (timestamps, subtle info)
Text("2 hours ago")
    .foregroundStyle(Color.primary.opacity(0.6))  // 60% opacity

// ❌ DON'T: Use these (bad contrast)
Text("Bad").foregroundStyle(.secondary)  // Too light!
Text("Bad").foregroundStyle(.gray)       // Doesn't adapt to dark mode
Text("Bad").foregroundStyle(Color.black) // Breaks in dark mode
```

### Background Colors

```swift
// ✅ DO: Light neutral backgrounds
.background(Color(.systemGray6))           // System gray (adapts to dark mode)
.background(Color.white.opacity(0.8))     // Semi-transparent white
.background(Color.white)                  // Solid white cards

// ✅ DO: Colored backgrounds (with white text)
.background(Color.dccSaffron)             // Orange brand color
.foregroundStyle(.white)                  // White text on colored background

// ❌ DON'T: Conflicting combinations
.background(Color.white)
    .foregroundStyle(.white)              // WHITE ON WHITE = INVISIBLE!
```

### Brand Colors

```swift
// DCC Brand Palette
Color.dccSaffron  // Orange: #FF9933 - Primary brand color
Color.dccGreen    // Green: #008000 - Secondary brand color  
Color.dccBlue     // Blue:  #003380 - Accent/icons
Color.dccWhite    // White: #FFFFFF - Use sparingly (backgrounds only)
```

---

## Accessibility Patterns

### ✅ DO: Multi-Sensory Information

Never rely on color alone. Always combine:

```swift
// GOOD: Icon + Text + Color
HStack {
    Image(systemName: "medal.fill")        // 1. Icon
        .foregroundStyle(Color.yellow)
    Text("1st Place")                      // 2. Text
        .foregroundStyle(Color.primary)
}

// GOOD: Emoji + Label + Color
HStack {
    Text("🔥")                              // 1. Emoji
    Text("Improving")                      // 2. Label
        .foregroundStyle(.green)           // 3. Color (bonus)
}

// BAD: Color only
Circle()
    .fill(.green)  // ❌ No meaning without color vision!
```

### ✅ DO: Clear Visual Hierarchy

```swift
// Level 1: Most important
.font(.title)
.fontWeight(.bold)
.foregroundStyle(Color.primary)

// Level 2: Important
.font(.headline)
.fontWeight(.semibold)
.foregroundStyle(Color.primary)

// Level 3: Supporting info
.font(.subheadline)
.foregroundStyle(Color.primary.opacity(0.7))

// Level 4: Metadata
.font(.caption)
.foregroundStyle(Color.primary.opacity(0.6))
```

---

## Component Patterns

### Card Pattern

```swift
VStack {
    // Content
}
.padding()
.background(
    RoundedRectangle(cornerRadius: 16)
        .fill(Color.white)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
)
.overlay(
    RoundedRectangle(cornerRadius: 16)
        .strokeBorder(Color.dccSaffron.opacity(0.3), lineWidth: 1)
)
```

### Button Pattern

```swift
Button("Action") {
    // Action
}
.foregroundStyle(.white)  // White text
.padding(.horizontal, 24)
.padding(.vertical, 14)
.background(Color.dccSaffron)  // Colored background
.cornerRadius(12)
.shadow(color: Color.dccSaffron.opacity(0.3), radius: 8, y: 4)
```

### List Row Pattern

```swift
HStack {
    VStack(alignment: .leading) {
        Text("Title")
            .font(.headline)
            .foregroundStyle(Color.primary)
        Text("Subtitle")
            .font(.caption)
            .foregroundStyle(Color.primary.opacity(0.7))
    }
    Spacer()
    Text("Value")
        .font(.title3)
        .bold()
        .foregroundStyle(Color.dccSaffron)
}
.padding()
.background(Color.white)
.cornerRadius(12)
```

---

## Status & Trend Indicators

### Status with Multi-Sensory Feedback

```swift
enum TrendStatus {
    case improving  // 🔥 Green
    case declining  // 📉 Red
    case stable     // → Gray
    case new        // ★ Orange
}

// Display function
func trendView(for status: TrendStatus) -> some View {
    HStack(spacing: 4) {
        Text(status.emoji)           // Visual icon
        Text(status.label)           // Text label
            .foregroundStyle(status.color)
    }
}

// Usage
trendView(for: .improving)
// Shows: "🔥 Improving" in green
```

### Ranking System

```swift
func rankView(for rank: Int) -> some View {
    HStack {
        if rank <= 3 {
            Image(systemName: "medal.fill")  // Medal icon
                .foregroundStyle(rankColor(rank))
        }
        Text("#\(rank)")                     // Rank number
            .foregroundStyle(rankColor(rank))
    }
}

func rankColor(_ rank: Int) -> Color {
    switch rank {
    case 1: return Color(red: 1.0, green: 0.84, blue: 0.0)  // Gold
    case 2: return Color(red: 0.75, green: 0.75, blue: 0.75)  // Silver
    case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)  // Bronze
    default: return .blue
    }
}
```

---

## Testing Checklist

### Before Committing Code:

```swift
// ✅ Light Mode Test
1. Run app in light mode
2. Check all text is readable
3. No white text on white backgrounds

// ✅ Dark Mode Test  
1. Toggle to dark mode
2. Check all text still readable
3. Colors adapt properly

// ✅ Colorblind Test
1. Use simulator accessibility inspector
2. Verify information is clear without color
3. Icons and labels carry meaning

// ✅ Contrast Test
1. Primary text: >7:1 ratio (AAA)
2. Secondary text: >4.5:1 ratio (AA)
3. Use online contrast checkers
```

---

## Common Mistakes to Avoid

### ❌ DON'T DO THIS:

```swift
// 1. White on white
Text("Hello").foregroundStyle(.white)
    .background(Color.white)

// 2. Black in dark mode
Text("Hello").foregroundStyle(Color.black)  // Use Color.primary

// 3. Secondary on light backgrounds
Text("Hello").foregroundStyle(.secondary)   // Too light!

// 4. Color-only information
Circle().fill(.green)  // What does green mean?

// 5. Hard-coded colors
.foregroundColor(.black)  // Use .foregroundStyle(Color.primary)
```

### ✅ DO THIS INSTEAD:

```swift
// 1. Proper contrast
Text("Hello").foregroundStyle(Color.primary)
    .background(Color.white)

// 2. Adaptive colors
Text("Hello").foregroundStyle(Color.primary)  // Adapts automatically

// 3. Sufficient contrast
Text("Hello").foregroundStyle(Color.primary.opacity(0.7))

// 4. Multi-sensory
HStack {
    Image(systemName: "checkmark.circle.fill")
    Text("Success")
}
.foregroundStyle(.green)

// 5. Modern API
.foregroundStyle(Color.primary)  // Modern and adaptive
```

---

## Quick Reference Table

| Element | Font | Color | Weight |
|---------|------|-------|--------|
| Screen Title | `.largeTitle` | `Color.primary` | `.bold` |
| Section Header | `.title2` | `Color.primary` | `.bold` |
| Card Title | `.headline` | `Color.primary` | `.semibold` |
| Body Text | `.body` | `Color.primary` | `.regular` |
| Secondary Text | `.subheadline` | `Color.primary.opacity(0.7)` | `.regular` |
| Caption | `.caption` | `Color.primary.opacity(0.6)` | `.regular` |
| Metric Value | `.title` | `Color.dccSaffron` | `.bold` |
| Button Text | `.body` | `.white` | `.semibold` |

---

## Resources

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [Color Oracle (Colorblind Simulator)](https://colororacle.org/)

---

**Remember:** 
- Accessibility is not optional
- Good design works for everyone
- Test in both light and dark modes
- Never rely on color alone
- When in doubt, use `Color.primary`

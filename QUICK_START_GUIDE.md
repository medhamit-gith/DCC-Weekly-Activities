# 🚀 Quick Start: Accessible UI Development

## 30-Second Rule Check

Before committing any UI code, verify these 3 things:

```swift
// 1. ✅ Text has explicit, high-contrast color
Text("Hello").foregroundStyle(Color.primary)  // NOT .secondary!

// 2. ✅ Information shown 3 ways (icon + text + color)
HStack {
    Image(systemName: "checkmark.circle.fill")  // Icon
    Text("Success")                              // Text
}.foregroundStyle(.green)                       // Color

// 3. ✅ White backgrounds only (no gradients)
VStack { /* content */ }
    .background(Color.white)  // Simple and readable
```

✅ **Pass all 3?** → Safe to commit  
❌ **Fail any?** → Fix before committing

---

## 🎨 Color Cheat Sheet

### Text Colors (Copy-Paste These)

```swift
// For primary text (names, headlines)
.foregroundStyle(Color.primary)

// For secondary text (descriptions, metadata)  
.foregroundStyle(Color.primary.opacity(0.7))

// For timestamps, subtle info
.foregroundStyle(Color.primary.opacity(0.6))

// For white text on colored backgrounds
.foregroundStyle(.white)  // Only with dark background!
```

### Background Colors

```swift
// For screens
.background(Color(.systemGray6))

// For cards
.background(Color.white)

// For buttons (with white text)
.background(Color.dccSaffron)
```

---

## 🚫 Never Do This

```swift
// ❌ 1. White on white
Text("Hello").foregroundStyle(.white)
    .background(Color.white)  // INVISIBLE!

// ❌ 2. .secondary on light backgrounds
Text("Hello").foregroundStyle(.secondary)  // TOO LIGHT!

// ❌ 3. Hard-coded black (breaks dark mode)
Text("Hello").foregroundStyle(Color.black)  // Use Color.primary

// ❌ 4. Color-only information
Circle().fill(.green)  // What does green mean?

// ❌ 5. Complex gradients
LinearGradient(...)  // Use solid colors
```

---

## ✅ Always Do This

```swift
// ✅ 1. Explicit, adaptive colors
Text("Hello").foregroundStyle(Color.primary)
    .background(Color.white)

// ✅ 2. High contrast on light
Text("Hello").foregroundStyle(Color.primary.opacity(0.7))

// ✅ 3. Adaptive for dark mode
Text("Hello").foregroundStyle(Color.primary)  // Auto-adapts

// ✅ 4. Multi-sensory indicators
HStack {
    Image(systemName: "checkmark")  // Icon
    Text("Complete")                 // Text
}.foregroundStyle(.green)           // Color

// ✅ 5. Simple, solid backgrounds
Color(.systemGray6)  // Clean and readable
```

---

## 🎯 Status Indicator Template

Copy-paste this pattern for any status display:

```swift
// Trend indicator (colorblind-friendly)
func trendView(emoji: String, label: String, color: Color) -> some View {
    HStack(spacing: 4) {
        Text(emoji)           // 1. Visual icon
        Text(label)           // 2. Text label
            .foregroundStyle(color)  // 3. Color (bonus)
    }
}

// Usage examples:
trendView(emoji: "🔥", label: "Improving", color: .green)
trendView(emoji: "📉", label: "Declining", color: .red)
trendView(emoji: "→", label: "Stable", color: .gray)
trendView(emoji: "★", label: "New", color: .orange)
```

---

## 🏆 Ranking Template

Copy-paste for any leaderboard/ranking:

```swift
func rankView(rank: Int, name: String) -> some View {
    HStack(spacing: 8) {
        // Medal for top 3
        if rank <= 3 {
            Image(systemName: "medal.fill")
                .foregroundStyle(rankColor(rank))
        }
        
        // Rank number
        Text("#\(rank)")
            .foregroundStyle(rankColor(rank))
        
        // Name
        Text(name)
            .foregroundStyle(Color.primary)
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

## 📦 Card Component Template

```swift
struct ContentCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 12) {
            content
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
    }
}

// Usage:
ContentCard {
    Text("Title")
        .foregroundStyle(Color.primary)
    Text("Subtitle")
        .foregroundStyle(Color.primary.opacity(0.7))
}
```

---

## 🔘 Button Template

```swift
struct AccessibleButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isProminent: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(isProminent ? .white : Color.primary)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
        .background(
            isProminent ? Color.dccSaffron : Color.white
        )
        .cornerRadius(12)
        .shadow(
            color: (isProminent ? Color.dccSaffron : Color.black)
                .opacity(0.2), 
            radius: 8, 
            y: 4
        )
    }
}

// Usage:
AccessibleButton(
    title: "Save",
    icon: "checkmark",
    action: { save() },
    isProminent: true
)
```

---

## 🧪 Quick Test Script

Run this before committing:

```swift
// 1. Visual check
// - Open app in simulator
// - Toggle Appearance: Light ↔ Dark
// - Verify all text readable

// 2. Accessibility check
// - Enable VoiceOver
// - Navigate through your screen
// - Verify all elements labeled

// 3. Color blindness check
// - Open Accessibility Inspector
// - Select "Color Blindness" simulation
// - Verify information still clear

// Takes 2 minutes, prevents embarrassment! 😅
```

---

## 📏 Contrast Ratio Quick Check

Use this in your browser while coding:
https://webaim.org/resources/contrastchecker/

Target ratios:
- Primary text: **>7:1** (AAA)
- Body text: **>4.5:1** (AA)
- Large text: **>3:1** (AA)

---

## 🎨 DCC Color Palette

```swift
// Brand colors (already defined)
Color.dccSaffron  // #FF9933 - Orange brand
Color.dccGreen    // #008000 - Green brand
Color.dccBlue     // #003380 - Blue accent

// System colors (use these)
Color.primary     // Auto-adapts to theme
Color.white       // Cards/backgrounds
Color(.systemGray6)  // Screen backgrounds

// Medal colors
let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
let silver = Color(red: 0.75, green: 0.75, blue: 0.75)
let bronze = Color(red: 0.8, green: 0.5, blue: 0.2)
```

---

## 💡 Pro Tips

### Tip 1: When in doubt, use `Color.primary`
```swift
Text("Anything")
    .foregroundStyle(Color.primary)  // Always safe
```

### Tip 2: Never go below 0.6 opacity
```swift
// ✅ Good contrast
.foregroundStyle(Color.primary.opacity(0.7))

// ❌ Too light
.foregroundStyle(Color.primary.opacity(0.4))
```

### Tip 3: White text needs dark backgrounds
```swift
// ✅ Good
.foregroundStyle(.white)
.background(Color.dccSaffron)  // Dark enough

// ❌ Bad
.foregroundStyle(.white)
.background(Color.white)  // Invisible!
```

### Tip 4: Test dark mode immediately
```swift
#Preview {
    YourView()
        .preferredColorScheme(.dark)  // Add this
}
```

### Tip 5: Add labels to icons
```swift
// ✅ Good
HStack {
    Image(systemName: "checkmark")
    Text("Complete")
}

// ❌ Bad (icon alone)
Image(systemName: "checkmark")
```

---

## 🚨 Common Mistakes & Fixes

| Mistake | Fix |
|---------|-----|
| `.foregroundStyle(.secondary)` | `.foregroundStyle(Color.primary.opacity(0.7))` |
| `.foregroundColor(.black)` | `.foregroundStyle(Color.primary)` |
| Tricolor gradient | `Color(.systemGray6)` |
| Icon without label | `HStack { icon; Text("Label") }` |
| Color-only status | Icon + Text + Color |

---

## 📚 Full Documentation

For complete details, see:
- **DESIGN_SYSTEM_GUIDE.md** - Comprehensive guidelines
- **UI_DEVELOPMENT_CHECKLIST.md** - Full checklist
- **ACCESSIBILITY_FIXES_SUMMARY.md** - Technical details

---

## ⚡ TL;DR

**3 Rules to Rule Them All:**

1. **Text:** Always `Color.primary` or `opacity(0.7)`
2. **Info:** Icon + Text + Color (never color alone)
3. **Backgrounds:** Solid white or gray (no gradients)

Follow these 3 rules → 95% of accessibility issues prevented.

---

**Happy coding! 🎨♿✨**

**Questions?** Check DESIGN_SYSTEM_GUIDE.md or ask the team.

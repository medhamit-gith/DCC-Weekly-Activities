# ✅ UI Development Checklist

Use this checklist every time you create or modify UI components to ensure accessibility and readability.

---

## 📝 Pre-Development Checklist

Before writing any UI code, ask yourself:

- [ ] What information needs to be conveyed?
- [ ] Who will use this feature? (consider all abilities)
- [ ] What's the most important information? (visual hierarchy)
- [ ] How will this look in dark mode?
- [ ] How will this work without color vision?

---

## 🎨 Color & Contrast Checklist

### Text Colors
- [ ] Primary text uses `Color.primary` or explicit high-contrast color
- [ ] Secondary text uses `Color.primary.opacity(0.7)` minimum
- [ ] No use of `.secondary` on light backgrounds
- [ ] No use of `.gray` (use opacity instead)
- [ ] No hard-coded `Color.black` (breaks dark mode)
- [ ] White text only on dark/colored backgrounds (>7:1 contrast)

### Background Colors
- [ ] No tricolor or complex gradients behind text
- [ ] Solid backgrounds for readability (`Color.white`, `Color(.systemGray6)`)
- [ ] Colored backgrounds only when text is white
- [ ] Cards have white/light backgrounds with shadows for elevation
- [ ] Backgrounds adapt to dark mode

### Contrast Ratios
- [ ] Primary text: >7:1 ratio (WCAG AAA)
- [ ] Secondary text: >4.5:1 ratio (WCAG AA)
- [ ] Interactive elements: >3:1 ratio (WCAG AA)
- [ ] Use [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)

---

## ♿ Accessibility Checklist

### Color Blindness
- [ ] Never use color alone to convey information
- [ ] Every colored indicator has an icon
- [ ] Every colored indicator has a text label
- [ ] Status shown with: Emoji + Text + Color (triple encoding)
- [ ] Rankings shown with: Icon + Number + Position

### Screen Readers
- [ ] All images have accessibility labels
- [ ] All buttons have clear labels (not just icons)
- [ ] Interactive elements have hints when needed
- [ ] Proper semantic structure (headings, labels)

### Low Vision
- [ ] Text scales with Dynamic Type
- [ ] Minimum font size: 14pt (`.caption`)
- [ ] Important text: 17pt+ (`.body`, `.headline`)
- [ ] Sufficient spacing between elements
- [ ] Clear tap targets (44x44pt minimum)

### Keyboard Navigation (macOS/iPadOS)
- [ ] All interactive elements focusable
- [ ] Focus indicators visible
- [ ] Logical tab order

---

## 📱 Platform-Specific Checklist

### iOS/iPadOS
- [ ] Safe areas respected
- [ ] Works in portrait and landscape
- [ ] Pull-to-refresh implemented where appropriate
- [ ] Haptic feedback on important actions
- [ ] Toolbar items accessible
- [ ] Navigation clear and consistent

### tvOS
- [ ] Focus engine works properly
- [ ] Focusable elements have clear focus states
- [ ] Remote gestures supported (swipe, select)
- [ ] Text large enough from 10 feet (36pt+)
- [ ] Simple navigation (max 2 levels deep)

### macOS
- [ ] Window resizing handled
- [ ] Keyboard shortcuts implemented
- [ ] Context menus where appropriate
- [ ] Menu bar integration

---

## 🎭 Visual Design Checklist

### Typography
- [ ] Clear hierarchy: Title > Headline > Body > Caption
- [ ] Consistent font weights
- [ ] Line height appropriate (1.2-1.5x font size)
- [ ] No more than 3 font sizes per screen
- [ ] Important text is bold

### Layout
- [ ] Generous padding (minimum 16pt)
- [ ] Consistent spacing between elements
- [ ] Aligned elements (left, right, center consistently)
- [ ] Balanced white space
- [ ] No cramped or cluttered areas

### Visual Hierarchy
- [ ] Most important element is largest/boldest
- [ ] Supporting info is smaller/lighter
- [ ] Clear grouping of related items
- [ ] Visual flow guides user naturally

### Feedback & States
- [ ] Loading states implemented
- [ ] Empty states implemented
- [ ] Error states implemented
- [ ] Success states implemented
- [ ] Button press states (scale, opacity)
- [ ] Disabled states clear but visible

---

## 🧪 Testing Checklist

### Manual Testing
- [ ] Test in light mode
- [ ] Test in dark mode
- [ ] Test with large text enabled
- [ ] Test with bold text enabled
- [ ] Test with reduce transparency enabled
- [ ] Test with reduce motion enabled

### Accessibility Testing
- [ ] Run with Accessibility Inspector
- [ ] Test with VoiceOver enabled
- [ ] Simulate color blindness (protanopia, deuteranopia, tritanopia)
- [ ] Verify keyboard navigation
- [ ] Check contrast ratios

### Cross-Device Testing
- [ ] iPhone SE (smallest screen)
- [ ] iPhone Pro Max (largest screen)
- [ ] iPad (tablet layout)
- [ ] Apple TV (10-foot UI)

### Edge Cases
- [ ] Very long names/text (truncation)
- [ ] Very short text (still readable)
- [ ] Empty data (empty state)
- [ ] Maximum data (scrolling works)
- [ ] Slow network (loading state)
- [ ] No network (error state)

---

## 🎨 Component-Specific Checklists

### Creating a Card Component
- [ ] White/light background
- [ ] Rounded corners (12-16pt)
- [ ] Subtle shadow for elevation
- [ ] Optional colored border (thin, 1-2pt)
- [ ] Padding (16-20pt)
- [ ] Text uses `Color.primary` variants

### Creating a Button
- [ ] Clear label (not just icon)
- [ ] Minimum 44x44pt tap target
- [ ] Hover state (macOS)
- [ ] Press state (scale to 0.95)
- [ ] Disabled state (opacity 0.5)
- [ ] Sufficient padding (12-16pt)
- [ ] Colored background → white text
- [ ] White background → colored text

### Creating a List Row
- [ ] Consistent height
- [ ] Title in primary color
- [ ] Subtitle in secondary opacity
- [ ] Value/metric stands out (bold, colored)
- [ ] Icons on left
- [ ] Chevron on right (if navigable)
- [ ] Dividers or spacing between rows

### Creating a Status Indicator
- [ ] Emoji or icon
- [ ] Text label
- [ ] Color (enhancement, not requirement)
- [ ] Clear meaning without color
- [ ] Example: 🔥 "Improving" (green)

### Creating a Chart
- [ ] Legend included
- [ ] Axis labels readable
- [ ] Data labels on hover/tap
- [ ] Works in colorblind mode
- [ ] Alternative text/list view available
- [ ] Empty state handled

---

## 📋 Code Review Checklist

When reviewing UI code, check for:

- [ ] No `.foregroundStyle(.secondary)` on light backgrounds
- [ ] No `.foregroundColor(.black)` (use `.foregroundStyle(Color.primary)`)
- [ ] No color-only information
- [ ] All text has explicit colors
- [ ] Proper contrast ratios
- [ ] Dark mode considered
- [ ] Accessibility labels present
- [ ] No magic numbers (use constants)
- [ ] Consistent spacing/padding
- [ ] Reusable components extracted

---

## 🚀 Deployment Checklist

Before releasing:

- [ ] All checklist items above completed
- [ ] Tested on real devices
- [ ] Screenshots reviewed (App Store)
- [ ] Dark mode screenshots taken
- [ ] Accessibility audit passed
- [ ] No console warnings
- [ ] Performance tested (smooth scrolling)
- [ ] Memory leaks checked

---

## 📚 Quick Reference

### Safe Text Colors
```swift
✅ Color.primary                    // Always safe
✅ Color.primary.opacity(0.7)       // Secondary text
✅ Color.primary.opacity(0.6)       // Tertiary text
✅ .white (on dark backgrounds)     // High contrast
```

### Safe Background Colors
```swift
✅ Color.white                      // Cards
✅ Color(.systemGray6)              // Screens
✅ Color.dccSaffron (with .white text)  // Buttons
```

### Multi-Sensory Pattern
```swift
✅ HStack {
    Image(systemName: "icon")    // Visual
    Text("Label")                // Verbal
}.foregroundStyle(color)         // Color (bonus)
```

### Card Pattern
```swift
✅ VStack { content }
    .padding()
    .background(
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    )
```

---

## 🆘 Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| White text invisible | Check background color, use `Color.primary` |
| Text too light | Use `Color.primary.opacity(0.7)` minimum |
| Dark mode broken | Replace `Color.black` with `Color.primary` |
| Colorblind unfriendly | Add icon + text label to color indicators |
| Low contrast | Check ratio, increase opacity or use darker color |
| Button not obvious | Add background, shadow, and proper padding |
| Text hierarchy unclear | Use font weights and sizes consistently |

---

## 📖 Resources

- [Apple HIG - Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Apple HIG - Color](https://developer.apple.com/design/human-interface-guidelines/color)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [Accessible Colors](https://accessible-colors.com/)
- [Color Oracle (Simulator)](https://colororacle.org/)

---

## 💡 Remember

> "Good design is accessible design. If it doesn't work for everyone, it's not finished."

- Accessibility is not optional
- Test with real accessibility features enabled
- When in doubt, use `Color.primary`
- Color enhances, but never carries information alone
- A11y features help everyone (captions benefit ESL learners, voice control helps multitaskers)

---

**Print this checklist and keep it visible while coding! 🚀**

# 🎮 tvOS Simulator Quick Reference Card

## 🚀 Launch Steps
1. Select **"DCC Weekly Activities TV"** scheme (top toolbar)
2. Choose **Apple TV 4K** device
3. Press **▶️ Play** or **Cmd + R**

## ⌨️ Keyboard Controls
| Action | Key |
|--------|-----|
| Navigate | Arrow Keys ← ↑ → ↓ |
| Select | Return/Enter |
| Back/Menu | Escape |
| Home Screen | Cmd + Shift + H |
| Virtual Remote | Cmd + Shift + R |
| Stop App | Cmd + . (period) |

## 🧪 Testing Workflow
1. App launches → Login screen appears
2. Navigate to **"Load Test Data"** button (green)
3. Press **Return** to load mock data
4. Explore **Stats** tab (shows leaderboard)
5. Switch to **Activities** tab (shows individual rides)

## 🎨 What You Should See
- **Background**: Indian flag tricolor (🧡⚪💚)
- **Summary Cards**: Total distance, rides, elevation, members
- **Leaderboard**: 8 members ranked by distance
- **Top 3 Colors**: 🥇 Gold, 🥈 Silver, 🥉 Bronze
- **Mock Data**: 15 activities, ~540 total km

## 🐛 Debug Mode Features
- **Green "Load Test Data" button** (only in Debug builds)
- **Console logging** for activity totals
- **No authentication required** for testing

## 📊 Test Data Stats
- **Total Distance**: ~540 km
- **Total Activities**: 15
- **Top Performer**: Amit K (~146 km)
- **Members**: 8 active riders

## 🔧 Common Actions
| Want to... | Do this... |
|------------|------------|
| Restart app | Cmd + R |
| View console | Cmd + Shift + Y |
| Toggle test data | Navigate to green button, press Return |
| Switch tabs | Navigate to bottom tabs, use arrows |
| Scroll list | Arrow keys Up/Down |
| Go to home | Cmd + Shift + H |

## ✅ Quick Test Checklist
- [ ] App launches successfully
- [ ] Can navigate with arrow keys
- [ ] Test data loads in ~1 second
- [ ] 4 summary cards display
- [ ] Leaderboard shows 8 members
- [ ] Can switch to Activities tab
- [ ] All 15 activities visible
- [ ] Scrolling is smooth
- [ ] Colors look correct

## 💡 Pro Tips
- White **focus ring** shows selected item
- Must **navigate to items** (can't just click anywhere)
- **Debug-only** features won't appear in Release builds
- Use **arrow keys** for fastest navigation
- Simulator remembers last launched app

## 🆘 Troubleshooting
| Problem | Solution |
|---------|----------|
| No arrow navigation | Click simulator window to focus it |
| Simulator won't launch | Download tvOS platform in Xcode Settings |
| Test button missing | Check Build Configuration is "Debug" |
| App crashes | Check Console (Cmd+Shift+Y) for errors |

---

**🎬 Ready to test? Just press Cmd + R and start navigating!**

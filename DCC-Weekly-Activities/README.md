# DCC Weekly Activities

<p align="center">
  <img src="app_icon_placeholder.png" alt="DCC Weekly Activities Icon" width="120"/>
</p>

<p align="center">
  <strong>Track your cycling club's weekly achievements</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#usage">Usage</a> •
  <a href="#development">Development</a> •
  <a href="#app-store">App Store</a>
</p>

---

## 📱 About

**DCC Weekly Activities** is a native iOS app designed for members of the Desi Cycling Club to view, track, and celebrate their weekly cycling achievements. The app integrates with Strava to fetch club activity data and presents it in beautiful, easy-to-understand visualizations.

### Platforms

- **iOS** 17.0+
- **iPadOS** 17.0+
- **tvOS** 17.0+ (read-only display)

---

## ✨ Features

### 📊 Comprehensive Statistics
- Weekly club activity summaries
- Total distance, rides, elevation gain, and average speed
- Member-by-member breakdowns
- Performance trend indicators (↑ improving, → stable, ↓ declining, ★ new)

### 🏆 Leaderboards & Rankings
- Top 10 performers of the week
- Expandable view to see all members
- Sort by distance, rides, speed, or elevation
- Color-coded trends for each member

### 📈 Beautiful Visualizations
- **Bar Charts**: Compare members' performance
- **Pie Charts**: Distance distribution among top performers
- **Tables**: Detailed sortable statistics
- **Lists**: Chronological activity view with details

### 🔒 Security & Privacy
- Biometric authentication (Face ID / Touch ID)
- Secure token storage in iOS Keychain
- Local-only data storage (no cloud sync)
- Privacy-first design

### 🎨 Design
- Indian flag-inspired theme (saffron, white, green)
- Dark mode support
- Smooth animations and transitions
- Optimized for all screen sizes
- Accessibility support (VoiceOver, Dynamic Type)

---

## 🚀 Installation

### Prerequisites

1. **Xcode** 15.0 or later
2. **iOS Deployment Target**: 17.0+
3. **Apple Developer Account** (for device testing and App Store submission)
4. **Strava Application** registered at [developers.strava.com](https://developers.strava.com)

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/DCC-Weekly-Activities.git
   cd DCC-Weekly-Activities
   ```

2. **Configure Strava API**
   
   Create a `Secrets.xcconfig` file (or use environment variables):
   ```
   STRAVA_CLIENT_ID = your_client_id_here
   STRAVA_CLIENT_SECRET = your_client_secret_here
   STRAVA_CLUB_ID = your_club_id_here
   ```

   Add to `.gitignore`:
   ```
   Secrets.xcconfig
   ```

3. **Update AppConfiguration.swift**
   
   Replace placeholder values in `AppConfiguration.swift`:
   ```swift
   enum Strava {
       static let clientID = "YOUR_CLIENT_ID"
       static let clubID = "YOUR_CLUB_ID"
       // ...
   }
   ```

4. **Configure URL Scheme**
   
   In Xcode, go to:
   - Target → Info → URL Types
   - Add URL Scheme: `dcc-activities`
   
   Or add to Info.plist:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>dcc-activities</string>
           </array>
       </dict>
   </array>
   ```

5. **Build and Run**
   ```bash
   open DCC-Weekly-Activities.xcodeproj
   ```
   
   Select your target device and press `⌘R` to build and run.

---

## 📖 Usage

### First Launch

1. **Connect with Strava**
   - Tap "Connect with Strava" button
   - Authorize the app to access your club activities
   - Enable biometric authentication when prompted (optional)

2. **View Statistics**
   - The app automatically fetches the last week's club activities
   - Switch between Charts, Table, and Activities views
   - Select different metrics (Distance, Rides, Speed, Elevation)

3. **Refresh Data**
   - Pull down to refresh
   - Or tap the refresh button in the navigation bar

### Navigation

- **Charts Tab**: Visual representations of member statistics
- **Table Tab**: Detailed sortable data table
- **Activities Tab**: List of all club activities

### Settings

- **Logout**: Tap the logout button to disconnect Strava
- **Biometric Auth**: Automatically prompts on app launch if configured

---

## 🛠 Development

### Project Structure

```
DCC-Weekly-Activities/
├── Models/
│   ├── ClubActivity.swift          # Activity data model
│   └── MemberStats.swift            # Member statistics model
├── Views/
│   ├── ContentView.swift            # Main app view
│   ├── MemberStatsChartView.swift   # Charts visualization
│   ├── MemberStatsTableView.swift   # Table view
│   └── TVViews.swift                # Apple TV views
├── Services/
│   ├── StravaAPI.swift              # Strava API integration
│   ├── BiometricAuth.swift          # Biometric authentication
│   └── DataCache.swift              # Offline data caching
├── Utilities/
│   ├── AppConfiguration.swift       # App configuration
│   ├── ErrorHandling.swift          # Error management
│   ├── Analytics.swift              # Analytics (optional)
│   └── HapticManager.swift          # Haptic feedback
└── Resources/
    ├── Assets.xcassets              # Images and colors
    └── Localizable.strings          # Translations
```

### Key Technologies

- **SwiftUI**: Modern declarative UI framework
- **Swift Charts**: Native data visualization
- **Swift Concurrency**: Async/await for network calls
- **Keychain Services**: Secure credential storage
- **LocalAuthentication**: Biometric authentication

### Building for Different Configurations

**Debug Build** (with mock data):
```bash
xcodebuild -scheme DCC-Weekly-Activities -configuration Debug
```

**Release Build** (production):
```bash
xcodebuild -scheme DCC-Weekly-Activities -configuration Release
```

### Running Tests

```bash
xcodebuild test -scheme DCC-Weekly-Activities -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

Or use Swift Testing in Xcode:
```bash
⌘U
```

---

## 🧪 Testing

### Unit Tests

Run unit tests to verify core functionality:
- Member statistics calculations
- Data aggregation logic
- API response parsing
- Error handling

### UI Tests

Test user flows:
- Login with Strava
- Fetch and display activities
- Switch between view modes
- Handle network errors

### Manual Testing Checklist

- [ ] Fresh install and login flow
- [ ] Biometric authentication
- [ ] Data fetching and refresh
- [ ] Offline mode (cached data)
- [ ] Network error handling
- [ ] Different device sizes
- [ ] Dark mode
- [ ] Accessibility (VoiceOver)
- [ ] Performance (large datasets)

---

## 📦 Dependencies

This project uses only native Apple frameworks:
- SwiftUI
- Charts
- Foundation
- Security (Keychain)
- LocalAuthentication

**No third-party dependencies** = faster builds, smaller app size, better security!

---

## 🎨 Design Resources

### Color Palette

```swift
// Indian Flag Theme
Saffron: #FF9933 (rgb: 1.0, 0.6, 0.2)
White:   #FFFFFF (rgb: 1.0, 1.0, 1.0)
Green:   #008000 (rgb: 0.0, 0.5, 0.0)
Blue:    #003380 (rgb: 0.0, 0.2, 0.5) // Ashoka Chakra
```

### SF Symbols Used

- `bicycle` - App icon
- `chart.bar.fill` - Charts view
- `tablecells` - Table view
- `list.bullet` - Activities list
- `road.lanes` - Distance metric
- `mountain.2.fill` - Elevation metric
- `speedometer` - Speed metric

---

## 📱 App Store

### Preparing for Submission

Follow these guides in order:

1. **[APP_STORE_CHECKLIST.md](APP_STORE_CHECKLIST.md)** - Complete submission checklist
2. **[PRODUCTION_IMPROVEMENTS.md](PRODUCTION_IMPROVEMENTS.md)** - Code improvements
3. **[APP_STORE_LISTING.md](APP_STORE_LISTING.md)** - Marketing materials
4. **[PrivacyPolicy.md](PrivacyPolicy.md)** - Privacy policy (required)

### Pre-Submission Checklist

- [ ] All API credentials configured
- [ ] Privacy policy hosted publicly
- [ ] App icons for all sizes
- [ ] Screenshots for all device types
- [ ] TestFlight beta testing completed
- [ ] No debug code in release build
- [ ] All tests passing
- [ ] Strava API compliance verified

### Submission Timeline

1. **Week 1**: Metadata, assets, privacy policy
2. **Week 2**: Code improvements, testing
3. **Week 3**: TestFlight beta
4. **Week 4**: Final fixes, submission
5. **Week 5+**: App Review (typically 1-7 days)

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow Swift API Design Guidelines
- Use SwiftLint for consistent formatting
- Write clear commit messages
- Add comments for complex logic
- Include tests for new features

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Strava** for their excellent API
- **Desi Cycling Club** members for inspiration
- **Apple** for SwiftUI and Swift Charts
- All beta testers and contributors

---

## 📞 Support

### For Users

- **Email**: support@desicyclingclub.com
- **Website**: [www.desicyclingclub.com](https://www.desicyclingclub.com)
- **Strava Club**: [Join us on Strava](https://www.strava.com/clubs/YOUR_CLUB_ID)

### For Developers

- **Issues**: [GitHub Issues](https://github.com/yourusername/DCC-Weekly-Activities/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/DCC-Weekly-Activities/discussions)
- **Pull Requests**: Always welcome!

---

## 🗺 Roadmap

### Version 1.0 (Current)
- ✅ Strava OAuth integration
- ✅ Weekly activity statistics
- ✅ Multiple visualization types
- ✅ Biometric authentication
- ✅ iOS, iPadOS, tvOS support

### Version 1.1 (Planned)
- [ ] Historical data (view past weeks)
- [ ] Activity details view
- [ ] Personal goals and achievements
- [ ] Push notifications for new activities
- [ ] Widget support (Home Screen)

### Version 1.2 (Future)
- [ ] Social sharing
- [ ] Export statistics as PDF
- [ ] Advanced filtering options
- [ ] Comparison with previous periods
- [ ] watchOS app

### Version 2.0 (Vision)
- [ ] Multiple club support
- [ ] Custom challenges
- [ ] Integration with other cycling platforms
- [ ] AI-powered insights
- [ ] Community features

---

## 📊 Project Stats

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Minimum iOS**: 17.0
- **Lines of Code**: ~2,500
- **Files**: 25+
- **Zero Third-Party Dependencies**: ✅

---

## 🏃‍♂️ Quick Start Commands

```bash
# Clone and open
git clone https://github.com/yourusername/DCC-Weekly-Activities.git
cd DCC-Weekly-Activities
open DCC-Weekly-Activities.xcodeproj

# Run tests
xcodebuild test -scheme DCC-Weekly-Activities

# Build release
xcodebuild -scheme DCC-Weekly-Activities -configuration Release

# Archive for distribution
xcodebuild archive -scheme DCC-Weekly-Activities -archivePath build/DCC.xcarchive
```

---

## ⚠️ Important Notes

1. **Strava API Rate Limits**: 
   - 100 requests per 15 minutes
   - 1,000 requests per day
   - App implements rate limiting

2. **Privacy**:
   - No user data is stored on external servers
   - All data cached locally on device
   - Biometric data never leaves device

3. **Strava Compliance**:
   - Must display "Powered by Strava"
   - Cannot modify activity data
   - Must follow Strava's brand guidelines

---

<p align="center">
  Made with ❤️ by the Desi Cycling Club
</p>

<p align="center">
  🚴‍♂️ Ride Safe • Track Progress • Celebrate Together 🚴‍♀️
</p>

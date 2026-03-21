# Next Steps: Enhancing Dashboard Views with All Strava Parameters

## Current Status ✅

The core navigation change is **COMPLETE**:
- ✅ Mode selection screen removed from post-login flow
- ✅ Summary cards on main screen are now tappable
- ✅ Tapping a card shows metric-specific mode selection sheet
- ✅ Sheet displays metric name, user's first name, and 3 mode options
- ✅ Navigation to each dashboard mode works correctly
- ✅ No breaking changes to auth, API, or data models

## What's Missing: Enhanced Dashboard Views

The requirements specify that each dashboard mode should display **ALL available Strava parameters**, not just distance, rides, speed, and elevation. Here's what needs to be added:

---

## Required Data Fields

### Currently Available (already in use):
- ✅ Distance
- ✅ Moving time
- ✅ Average speed
- ✅ Elevation gain
- ✅ Activity type
- ✅ Date/time
- ✅ Member name

### Need to Verify Availability:
These fields exist in Strava's data model but may not be available via the `/clubs/{id}/activities` endpoint:

- ❓ **Elapsed time** - Total time including stops
- ❓ **Max speed** - Peak speed during activity
- ❓ **Average watts** - Power output (requires power meter)
- ❓ **Average heart rate** - Requires heart rate monitor
- ❓ **Suffer score** - Strava's proprietary fitness metric
- ❓ **Kudos count** - Social engagement metric
- ❓ **Calories** - Estimated energy expenditure

### Action Required:
1. Check the actual JSON response from Strava's club activities endpoint
2. Update `StravaActivityResponse` struct to include available fields
3. Update `Activity` model to store these fields
4. Update `MemberStats` to aggregate these fields

---

## Option 1: Just My Stats - Required Enhancements

### Current Implementation:
Shows 4 stat cards: Distance, Rides, Avg Speed, Elevation

### Required Additions:

1. **Complete Stats Grid** (8-12 cards depending on data availability):
   ```swift
   - Total Distance ✅
   - Total Rides ✅
   - Moving Time (needs formatting)
   - Elapsed Time (need to add)
   - Avg Speed ✅
   - Max Speed (need to add)
   - Elevation Gain ✅
   - Avg Watts (if available)
   - Avg Heart Rate (if available)
   - Suffer Score (if available)
   - Total Kudos (if available)
   - Est. Calories (if available)
   ```

2. **Progress Bars/Rings for Each Stat**:
   ```swift
   For each metric:
   - Calculate club average
   - Show user's value
   - Display as progress bar or ring showing % of average
   - Color code: green (above avg), yellow (at avg), red (below avg)
   ```

3. **Highlighted Tapped Metric**:
   - The metric from the tapped card should be prominently displayed at top
   - Larger card, special styling, or "Featured Metric" section

### Implementation Example:
```swift
struct EnhancedStatCard: View {
    let title: String
    let userValue: Double
    let clubAverage: Double
    let unit: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer()
            }
            
            // User's value
            Text(formatValue(userValue))
                .font(.title2)
                .fontWeight(.bold)
            
            // Progress bar vs club average
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                    
                    // User's progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: geo.size.width * progressPercentage)
                }
            }
            .frame(height: 8)
            
            // Comparison text
            Text(comparisonText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    var progressPercentage: CGFloat {
        min(CGFloat(userValue / clubAverage), 1.0)
    }
    
    var progressColor: Color {
        switch userValue / clubAverage {
        case 0..<0.8: return .red
        case 0.8..<1.0: return .orange
        case 1.0..<1.2: return .green
        default: return .blue
        }
    }
    
    var comparisonText: String {
        let diff = userValue - clubAverage
        let percent = abs((diff / clubAverage) * 100)
        if diff > 0 {
            return String(format: "%.0f%% above club avg", percent)
        } else {
            return String(format: "%.0f%% below club avg", percent)
        }
    }
}
```

---

## Option 2: Me vs Top 3 - Required Enhancements

### Current Implementation:
Shows distance comparison only

### Required Additions:

1. **Multi-Metric Comparison Charts**:
   For EVERY available parameter, show a grouped bar chart:
   ```swift
   - Distance ✅
   - Elevation
   - Moving Time
   - Avg Speed
   - Max Speed (if available)
   - Avg Watts (if available)
   - Avg Heart Rate (if available)
   - Number of Rides
   - Suffer Score (if available)
   ```

2. **Visual Differentiation for Current User**:
   ```swift
   - Different color (already using dccSaffron ✅)
   - Bold label ✅
   - Maybe add star/crown icon
   - Highlighted background row
   ```

3. **Plain-English Summaries**:
   Below each chart, add text like:
   ```swift
   "You rode 12km less than the top rider but climbed 200m more than average"
   "Your average speed of 28 km/h beat 2 of the top 3 riders"
   "You completed 5 rides this week, matching the club leaders"
   ```

### Implementation Example:
```swift
struct MetricComparisonSection: View {
    let metric: MetricType
    let currentUser: MemberStats
    let top3: [MemberStats]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(metric.title)
                .font(.headline)
            
            // Grouped bar chart
            Chart {
                ForEach([currentUser] + top3) { stat in
                    BarMark(
                        x: .value("Member", stat.shortName),
                        y: .value(metric.title, metric.getValue(from: stat))
                    )
                    .foregroundStyle(stat.id == currentUser.id ? 
                        Color.dccSaffron : Color.dccBlue.opacity(0.7))
                }
            }
            .frame(height: 200)
            
            // Plain English summary
            Text(generateSummary())
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
    
    func generateSummary() -> String {
        let userValue = metric.getValue(from: currentUser)
        let topValue = metric.getValue(from: top3[0])
        let diff = userValue - topValue
        
        if diff >= 0 {
            return "You're leading in \(metric.title) with \(format(userValue))!"
        } else {
            let betterThan = top3.filter { metric.getValue(from: $0) < userValue }.count
            return "You're \(format(abs(diff))) behind the leader, but ahead of \(betterThan) top rider(s)"
        }
    }
}
```

---

## Option 3: Worst Performer - Required Enhancements

### Current Implementation:
Shows basic comparison with club average for distance and rides

### Required Additions:

1. **Weighted Scoring System**:
   ```swift
   struct PerformanceScore {
       static func calculate(stats: MemberStats, clubStats: ClubStats) -> Double {
           let distanceScore = (stats.totalKM / clubStats.avgDistance) * 0.40  // 40%
           let ridesScore = (Double(stats.totalRides) / clubStats.avgRides) * 0.20  // 20%
           let elevationScore = (stats.totalElevation / clubStats.avgElevation) * 0.15  // 15%
           let speedScore = (stats.avgSpeed / clubStats.avgSpeed) * 0.10  // 10%
           let timeScore = (Double(stats.totalMovingTime) / clubStats.avgTime) * 0.10  // 10%
           let sufferScore = (stats.avgSufferScore / clubStats.avgSufferScore) * 0.05  // 5%
           
           return distanceScore + ridesScore + elevationScore + speedScore + timeScore + sufferScore
       }
   }
   ```

2. **Detailed Parameter Comparison**:
   For each parameter, show:
   - Worst performer's value
   - Club average
   - Top 3 average
   - Visual indicator (🔴/🟡/🟢)
   - Percentage below/above average

3. **Rule-Based Verdict Generator**:
   ```swift
   func generateVerdict(performer: MemberStats, club: ClubStats, top3: [MemberStats]) -> String {
       var verdict = ""
       
       // Start with name and total distance
       let distancePercent = ((club.avgDistance - performer.totalKM) / club.avgDistance) * 100
       verdict += "\(performer.firstName) had the shortest total distance this week at "
       verdict += "\(String(format: "%.1f", performer.totalKM))km — "
       verdict += "\(String(format: "%.0f%%", distancePercent)) below the club average of "
       verdict += "\(String(format: "%.1f", club.avgDistance))km"
       
       // Compare to top rider
       let topRider = top3[0]
       let topPercent = ((topRider.totalKM - performer.totalKM) / topRider.totalKM) * 100
       verdict += " and \(String(format: "%.0f%%", topPercent)) behind the top rider. "
       
       // Ride count analysis
       if performer.totalRides <= 1 {
           verdict += "He completed only \(performer.totalRides) ride(s) this week"
           if performer.totalRides == 1 {
               verdict += ", suggesting either a single effort or missed sessions"
           }
           verdict += ". "
       }
       
       // Elevation analysis
       if performer.totalElevation < club.avgElevation * 0.5 {
           verdict += "With \(String(format: "%.0f", performer.totalElevation))m of elevation, "
           verdict += "this suggests predominantly flat routes. "
       }
       
       // Speed analysis
       if performer.avgSpeed == club.lowestSpeed {
           verdict += "His average speed of \(String(format: "%.1f", performer.avgSpeed)) km/h "
           verdict += "was the lowest in the club this week. "
       }
       
       // Effort/suffer score
       if let sufferScore = performer.avgSufferScore, sufferScore < club.avgSufferScore * 0.7 {
           verdict += "Low suffer score indicates less intense efforts. "
       }
       
       // Recommendations
       verdict += "\n\nRecommendation: "
       if performer.totalRides <= 2 {
           verdict += "Focus on consistency first — aim for at least 3 rides next week. "
       }
       if performer.totalKM < club.avgDistance * 0.6 {
           verdict += "Gradually increase distance by 10-20% per week. "
       }
       
       return verdict
   }
   ```

---

## Data Model Updates Required

### 1. Update StravaActivityResponse
```swift
struct StravaActivityResponse: Codable {
    // Existing fields...
    let name: String
    let distance: Double?
    let moving_time: Int?
    let total_elevation_gain: Double?
    let average_speed: Double?
    let start_date: String?
    let type: String?
    let sport_type: String?
    let athlete: Athlete
    
    // ADD THESE:
    let elapsed_time: Int?              // Total time including stops
    let max_speed: Double?              // Peak speed
    let average_watts: Double?          // Power (if available)
    let average_heartrate: Double?      // HR (if available)
    let suffer_score: Int?              // Strava's proprietary metric
    let kudos_count: Int?               // Social metric
    let kilojoules: Double?             // Energy expenditure
    let total_photo_count: Int?         // Photos attached
}
```

### 2. Update Activity Model
```swift
struct Activity: Identifiable, Codable {
    let id = UUID()
    let memberName: String
    let activityName: String
    let distance: Double
    let date: Date
    let averageSpeed: Double
    let elevationGain: Double
    let movingTime: Int
    let type: String
    
    // ADD THESE:
    let elapsedTime: Int?
    let maxSpeed: Double?
    let averageWatts: Double?
    let averageHeartrate: Double?
    let sufferScore: Int?
    let kudosCount: Int?
    let kilojoules: Double?
}
```

### 3. Update MemberStats
```swift
struct MemberStats: Identifiable {
    let id = UUID()
    let memberName: String
    let rides: [Activity]
    
    // Existing computed properties...
    var totalKM: Double { ... }
    var totalRides: Int { ... }
    var avgSpeed: Double { ... }
    var totalElevation: Double { ... }
    var totalMovingTime: Int { ... }
    
    // ADD THESE:
    var totalElapsedTime: Int {
        rides.compactMap { $0.elapsedTime }.reduce(0, +)
    }
    
    var maxSpeed: Double {
        rides.compactMap { $0.maxSpeed }.max() ?? 0
    }
    
    var avgWatts: Double {
        let watts = rides.compactMap { $0.averageWatts }
        return watts.isEmpty ? 0 : watts.reduce(0, +) / Double(watts.count)
    }
    
    var avgHeartrate: Double {
        let hr = rides.compactMap { $0.averageHeartrate }
        return hr.isEmpty ? 0 : hr.reduce(0, +) / Double(hr.count)
    }
    
    var totalSufferScore: Int {
        rides.compactMap { $0.sufferScore }.reduce(0, +)
    }
    
    var avgSufferScore: Double {
        let scores = rides.compactMap { $0.sufferScore }.map { Double($0) }
        return scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
    }
}
```

---

## Implementation Priority

### Phase 1: Data Layer (REQUIRED FIRST)
1. Test actual Strava API response to see which fields are available
2. Update `StravaActivityResponse` with available fields
3. Update `Activity` model
4. Update `MemberStats` computed properties
5. Update `toActivity()` conversion method

### Phase 2: Just My Stats View
1. Add club average calculation helper
2. Create enhanced stat cards with progress bars
3. Add all available metrics
4. Implement metric highlighting based on tapped card

### Phase 3: Me vs Top 3 View
1. Add multi-metric comparison charts
2. Implement plain-English summary generator
3. Add visual differentiation for current user
4. Handle missing data gracefully

### Phase 4: Worst Performer View
1. Implement weighted scoring algorithm
2. Add detailed parameter comparison table
3. Create rule-based verdict generator
4. Add recommendations engine

---

## Testing Strategy

1. **With Full Data**: Test with activities that have power, HR, suffer score
2. **With Partial Data**: Test with basic activities (distance, time only)
3. **With No Data**: Test empty states
4. **Edge Cases**: 
   - Only one member active
   - Current user is top performer
   - Current user is worst performer
   - Tied scores

---

## Graceful Degradation

For parameters that aren't available:
```swift
// Example: Heart Rate section
if athleteHasHeartrateData {
    HeartRateComparisonChart(...)
} else {
    UnavailableMetricCard(
        title: "Heart Rate",
        icon: "heart.fill",
        message: "Heart rate data not available for this activity",
        tip: "Connect a heart rate monitor to track this metric"
    )
}
```

---

## Summary

✅ **Navigation flow is complete** - Users can now tap summary cards to explore metrics  
⚠️ **Data layer needs verification** - Check what's actually available from Strava API  
⚠️ **Dashboard views need enhancement** - Add ALL parameters per requirements  
⚠️ **Comparison logic needs implementation** - Plain-English summaries and verdicts  

The foundation is solid. The next step is to verify data availability and then systematically enhance each dashboard view with comprehensive parameter analysis.

//
//  DateRangeProvider.swift
//  DCC-Weekly-Activities
//
//  Single source of truth for ISO week date range calculation.
//  Ensures all screens and API calls use consistent Monday-Sunday boundaries.
//
//  VERSION HISTORY:
//  2026-02-28: [CURRENT-WEEK] Added getCurrentWeek() to replace getLastCompletedWeek()
//              as the primary date range function. App now shows THIS WEEK's data
//              (Monday to today) instead of last week's data. getLastCompletedWeek()
//              is now deprecated and only used for historical comparisons.
//  2026-02-28: [HOTFIX] Fixed timezone mismatch causing activity filter to reject all data.
//              Changed Calendar from .current to UTC to match Strava's start_date format.
//              UI display formatter converts to local timezone for user-facing labels.
//  2026-02-28: [UI-DATES] Enhanced formatDateRange to show "today" for in-progress
//              weeks instead of future Sunday dates. Added getExtendedWeekRange()
//              for 2-week fallback support.
//

import Foundation

struct DateRangeProvider {
    
    /// Returns the current ISO calendar week (Monday 00:00:00 to today/Sunday 23:59:59)
    /// using UTC timezone to match Strava's API date format.
    ///
    /// Logic:
    /// - Returns THIS WEEK's data (current week Monday through today)
    /// - If today is Monday-Saturday, returns Monday 00:00:00 to today 23:59:59
    /// - If today is Sunday, returns complete Monday-Sunday week
    /// - Uses UTC timezone to match Strava's start_date format
    ///
    /// - Returns: DateInterval representing Monday 00:00:00 to today/Sunday 23:59:59 UTC
    static func getCurrentWeek() -> DateInterval {
        // CRITICAL: Use UTC timezone to match Strava's API date format
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        let now = Date()
        
        // Get current weekday
        let currentWeekday = calendar.component(.weekday, from: now)
        
        // Convert Gregorian weekday to ISO weekday
        // Gregorian: Sun=1, Mon=2, Tue=3, Wed=4, Thu=5, Fri=6, Sat=7
        // ISO:       Mon=1, Tue=2, Wed=3, Thu=4, Fri=5, Sat=6, Sun=7
        let isoWeekday = currentWeekday == 1 ? 7 : currentWeekday - 1
        
        // Calculate days to subtract to reach THIS week's Monday
        // If today is Monday (isoWeekday=1), days back = 0
        // If today is Tuesday (isoWeekday=2), days back = 1
        // If today is Sunday (isoWeekday=7), days back = 6
        let daysToThisMonday = isoWeekday - 1
        
        // Get this week's Monday at 00:00:00
        guard let thisMonday = calendar.date(byAdding: .day, value: -daysToThisMonday, to: now),
              let mondayStart = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: thisMonday) else {
            // Fallback: start of today
            let fallbackStart = calendar.startOfDay(for: now)
            let fallbackEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? now
            return DateInterval(start: fallbackStart, end: fallbackEnd)
        }
        
        // End date is today at 23:59:59
        guard let todayEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) else {
            return DateInterval(start: mondayStart, end: now)
        }
        
        return DateInterval(start: mondayStart, end: todayEnd)
    }
    
    /// Returns the most recently completed ISO calendar week (Monday 00:00:00 to Sunday 23:59:59)
    /// using UTC timezone to match Strava's API date format.
    /// **DEPRECATED**: Use getCurrentWeek() for displaying current week data.
    /// Only use this for historical comparisons or "previous week" features.
    ///
    /// Logic:
    /// - If today is Monday, returns LAST week (7 days ago)
    /// - If today is Tuesday-Sunday, returns LAST week (the most recently completed one)
    /// - Always returns a complete Monday-Sunday week, never a partial week
    /// - Uses UTC timezone to match Strava's start_date format
    ///
    /// - Returns: DateInterval representing Monday 00:00:00 to Sunday 23:59:59 UTC
    static func getLastCompletedWeek() -> DateInterval {
        // CRITICAL: Use UTC timezone to match Strava's API date format
        // Strava returns all dates in UTC (start_date field)
        // Comparing UTC dates from Strava against local timezone boundaries
        // causes all activities to fail the filter due to timezone offset
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        let now = Date()
        
        // Get current weekday (1 = Sunday, 2 = Monday, ..., 7 = Saturday in Gregorian)
        // For ISO 8601: Monday = 1, Sunday = 7
        let currentWeekday = calendar.component(.weekday, from: now)
        
        // Convert Gregorian weekday to ISO weekday
        // Gregorian: Sun=1, Mon=2, Tue=3, Wed=4, Thu=5, Fri=6, Sat=7
        // ISO:       Mon=1, Tue=2, Wed=3, Thu=4, Fri=5, Sat=6, Sun=7
        let isoWeekday = currentWeekday == 1 ? 7 : currentWeekday - 1
        
        // Calculate days to subtract to reach last completed week's Monday
        // If today is Monday (isoWeekday=1), go back 7 days to last Monday
        // If today is Tuesday (isoWeekday=2), go back 1 day to this Monday, then 7 more = 8 days total
        // If today is Wednesday-Sunday, go back to this Monday, then back 7 more days
        // Formula: (isoWeekday - 1) gets us to this week's Monday, then +7 for last week's Monday
        let daysToLastMonday = (isoWeekday - 1) + 7
        
        // Get last Monday at 00:00:00
        guard let lastMonday = calendar.date(byAdding: .day, value: -daysToLastMonday, to: now),
              let mondayStart = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: lastMonday) else {
            // Fallback: 7 days ago if calculation fails
            let fallbackStart = calendar.startOfDay(for: now.addingTimeInterval(-7 * 24 * 60 * 60))
            let fallbackEnd = calendar.date(byAdding: .day, value: 7, to: fallbackStart)!
            return DateInterval(start: fallbackStart, end: fallbackEnd)
        }
        
        // Get last Sunday at 23:59:59
        guard let lastSunday = calendar.date(byAdding: .day, value: 6, to: mondayStart),
              let sundayEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: lastSunday) else {
            // Fallback: Monday + 7 days
            let fallbackEnd = calendar.date(byAdding: .day, value: 7, to: mondayStart)!
            return DateInterval(start: mondayStart, end: fallbackEnd)
        }
        
        return DateInterval(start: mondayStart, end: sundayEnd)
    }
    
    /// Returns Unix timestamps for API calls (after, before parameters)
    /// Uses CURRENT WEEK (this week's data, not last week)
    static func getCurrentWeekTimestamps() -> (after: Int, before: Int) {
        let interval = getCurrentWeek()
        return (
            after: Int(interval.start.timeIntervalSince1970),
            before: Int(interval.end.timeIntervalSince1970)
        )
    }
    
    /// Returns Unix timestamps for last completed week (for historical comparisons)
    /// **DEPRECATED**: Use getCurrentWeekTimestamps() for main data display
    static func getLastCompletedWeekTimestamps() -> (after: Int, before: Int) {
        let interval = getLastCompletedWeek()
        return (
            after: Int(interval.start.timeIntervalSince1970),
            before: Int(interval.end.timeIntervalSince1970)
        )
    }
    
    /// Returns a 2-week extended range from today going back 14 days
    /// Range: 14 days ago at 00:00:00 to today at 23:59:59 (UTC)
    /// This provides a rolling 14-day window that always includes today's activities
    static func getExtendedWeekRange() -> DateInterval {
        // CRITICAL: Use UTC timezone to match Strava's API date format
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        let now = Date()
        
        // Get 14 days ago at 00:00:00
        guard let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: now),
              let startDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: fourteenDaysAgo) else {
            // Fallback: use single week if calculation fails
            return getLastCompletedWeek()
        }
        
        // Get today at 23:59:59
        guard let endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) else {
            // Fallback: use 14 days from start
            let fallbackEnd = calendar.date(byAdding: .day, value: 14, to: startDate)!
            return DateInterval(start: startDate, end: fallbackEnd)
        }
        
        return DateInterval(start: startDate, end: endDate)
    }
    
    /// Returns Unix timestamps for extended 2-week range
    static func getExtendedWeekTimestamps() -> (after: Int, before: Int) {
        let interval = getExtendedWeekRange()
        return (
            after: Int(interval.start.timeIntervalSince1970),
            before: Int(interval.end.timeIntervalSince1970)
        )
    }
    
    // MARK: - Week-offset helpers

    /// Returns the ISO week range for a given offset from the current week.
    /// - Parameter offset: 0 = this week, -1 = last week, -2 = two weeks ago, etc.
    /// - Returns: DateInterval from Monday 00:00:00 to Sunday 23:59:59 UTC
    ///   (for offset 0, end is clamped to today 23:59:59 since the week is in progress)
    static func weekRange(offset: Int) -> DateInterval {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        let now = Date()
        let currentWeekday = calendar.component(.weekday, from: now)
        let isoWeekday = currentWeekday == 1 ? 7 : currentWeekday - 1
        let daysToThisMonday = isoWeekday - 1
        let daysToTargetMonday = daysToThisMonday - (offset * 7)

        guard let targetMonday = calendar.date(byAdding: .day, value: -daysToTargetMonday, to: now),
              let mondayStart = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: targetMonday) else {
            return getCurrentWeek()
        }

        let endDate: Date
        if offset == 0 {
            // In-progress week: end is today 23:59:59
            endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? now
        } else {
            // Completed week: end is Sunday 23:59:59
            guard let targetSunday = calendar.date(byAdding: .day, value: 6, to: mondayStart),
                  let sundayEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: targetSunday) else {
                return DateInterval(start: mondayStart, end: mondayStart.addingTimeInterval(7 * 24 * 3600))
            }
            endDate = sundayEnd
        }

        return DateInterval(start: mondayStart, end: endDate)
    }

    /// Returns the ISO week range for the week immediately before the given interval.
    static func previousWeekRange(before interval: DateInterval) -> DateInterval {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        let prevMondayDate = interval.start.addingTimeInterval(-7 * 24 * 3600)
        guard let mondayStart = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: prevMondayDate),
              let prevSunday = calendar.date(byAdding: .day, value: 6, to: mondayStart),
              let sundayEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: prevSunday) else {
            return DateInterval(start: prevMondayDate, end: interval.start)
        }
        return DateInterval(start: mondayStart, end: sundayEnd)
    }

    /// Returns the Unix `after=` timestamp to fetch BOTH the selected week and the
    /// previous week in one Strava API call (since the endpoint only supports `after=`).
    static func afterTimestampForTwoWeeks(selectedWeek: DateInterval) -> Int {
        let prevWeek = previousWeekRange(before: selectedWeek)
        return Int(prevWeek.start.timeIntervalSince1970)
    }

    /// Human-readable label for a week offset.
    static func weekOffsetLabel(_ offset: Int) -> String {
        switch offset {
        case 0:  return "This Week"
        case -1: return "Last Week"
        default: return "\(abs(offset)) Weeks Ago"
        }
    }

    /// Formats date range as "Mon 9 Jun – Sun 15 Jun 2025"
    /// Uses en_US_POSIX locale for consistent day/month abbreviations
    /// If end date is in the future, shows "today" instead
    /// Displays dates in user's local timezone for better UX
    static func formatDateRange(_ interval: DateInterval) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        // Display in user's local timezone (interval is in UTC but we show local time)
        formatter.timeZone = TimeZone.current
        
        let calendar = Calendar.current
        let now = Date()
        let startYear = calendar.component(.year, from: interval.start)
        let endYear = calendar.component(.year, from: interval.end)
        let currentYear = calendar.component(.year, from: Date())
        
        // Format: "Mon 9 Feb"
        formatter.dateFormat = "EEE d MMM"
        let startStr = formatter.string(from: interval.start)
        
        // Check if end date is in the future (in-progress week)
        let endStr: String
        if interval.end > now {
            endStr = "today"
        } else {
            endStr = formatter.string(from: interval.end)
        }
        
        // Add year only if not current year or if range spans two years
        if startYear != endYear && interval.end <= now {
            return "\(startStr) \(startYear) – \(endStr) \(endYear)"
        } else if startYear != currentYear {
            return "\(startStr) – \(endStr) \(startYear)"
        } else {
            return "\(startStr) – \(endStr)"
        }
    }
    
    /// Returns ISO week number for the last completed week
    /// Uses ISO 8601 standard: weeks start on Monday, first week contains Jan 4
    static func weekNumber() -> Int {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        let interval = getLastCompletedWeek()
        return calendar.component(.weekOfYear, from: interval.start)
    }
}

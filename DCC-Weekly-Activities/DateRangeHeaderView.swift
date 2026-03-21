//
//  DateRangeHeaderView.swift
//  DCC-Weekly-Activities
//
//  Reusable header component displaying the Monday-Sunday date range
//  in consistent format across all screens.
//
//  VERSION HISTORY:
//  2026-02-28: [UI-DATES] Now displays "today" for in-progress weeks instead
//              of future dates. Automatically shows 2-week extended ranges when
//              isShowingExtendedRange is active. All formatting handled by
//              DateRangeProvider.formatDateRange() for consistency.
//  2026-02-28: [CURRENT-WEEK] Updated to use getCurrentWeek() instead of
//              getLastCompletedWeek() to show current week data.
//

import SwiftUI

struct DateRangeHeaderView: View {
    let dateRange: DateInterval?
    var showWeekLabel: Bool = true
    
    var body: some View {
        VStack(spacing: 4) {
            if showWeekLabel {
                Text("Week")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Week summary for")
            }
            
            Text(formattedDateRange)
                .font(.headline)
                .fontWeight(.semibold)
                .accessibilityLabel(accessibleDateRange)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var formattedDateRange: String {
        guard let range = dateRange else {
            return "Last Week"
        }
        return DateRangeProvider.formatDateRange(range)
    }
    
    private var accessibleDateRange: String {
        guard let range = dateRange else {
            return "Last week"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        
        let startStr = formatter.string(from: range.start)
        let endStr = formatter.string(from: range.end)
        
        return "Week from \(startStr) to \(endStr)"
    }
}

#Preview {
    let interval = DateRangeProvider.getCurrentWeek()
    
    VStack(spacing: 32) {
        DateRangeHeaderView(dateRange: interval)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        
        DateRangeHeaderView(dateRange: interval, showWeekLabel: false)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        
        DateRangeHeaderView(dateRange: nil)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
    }
    .padding()
}

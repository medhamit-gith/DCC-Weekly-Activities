//
//  AdaptiveDashboardRouter.swift
//  DCC-Weekly-Activities
//
//  Single branching point between iPhone and iPad dashboard layouts.
//
//  - compact horizontal size class  → ProfessionalDashboardView (iPhone, unchanged)
//  - regular horizontal size class  → IPadDashboardView (iPad, Liquid Glass sidebar-adaptable tabs)
//
//  The horizontalSizeClass updates live when the user resizes the app in
//  Split View or Stage Manager, so the UI adapts automatically.
//
//  NOTE: Do not add this file to the tvOS target.
//

import SwiftUI

struct AdaptiveDashboardRouter: View {
    let stats: [MemberStats]
    let dateRange: DateInterval?
    let athleteProfile: AthleteProfile
    let activities: [Activity]
    @Binding var selectedWeekOffset: Int
    let onWeekChanged: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .regular {
            // iPad (regular width): Liquid Glass sidebarAdaptable tabs + NavigationSplitView details
            IPadDashboardView(
                stats: stats,
                dateRange: dateRange,
                athleteProfile: athleteProfile,
                activities: activities,
                selectedWeekOffset: $selectedWeekOffset,
                onWeekChanged: onWeekChanged
            )
        } else {
            // iPhone (compact width): existing custom 5-tab horizontal switcher
            ProfessionalDashboardView(
                stats: stats,
                dateRange: dateRange,
                athleteProfile: athleteProfile,
                activities: activities
            )
        }
    }
}

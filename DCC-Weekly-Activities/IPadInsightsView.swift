//
//  IPadInsightsView.swift
//  DCC-Weekly-Activities
//
//  iPad "Insights" tab — wraps PersonalInsightsView with width constraints
//  for optimal readability on larger iPad displays.
//

import SwiftUI

struct IPadInsightsView: View {
    let athleteProfile: AthleteProfile
    let allStats: [MemberStats]
    let allActivities: [Activity]

    var body: some View {
        ScrollView {
            PersonalInsightsView(
                athleteProfile: athleteProfile,
                allStats: allStats,
                allActivities: allActivities
            )
            .frame(maxWidth: IPadLayout.maxContentWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, IPadLayout.screenMargin)
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground.ignoresSafeArea())
        .containerBackground(Color.appBackground, for: .navigation)
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.large)
    }
}

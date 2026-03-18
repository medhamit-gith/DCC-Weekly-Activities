//
//  IPadDashboardView.swift
//  DCC-Weekly-Activities
//
//  Main iPad dashboard container.
//  Uses TabView with .sidebarAdaptable — Apple's recommended iPad navigation.
//  The system automatically renders a floating Liquid Glass top tab bar that
//  can adapt into a sidebar.
//
//  NOTE: Do not add this file to the tvOS target.
//

import SwiftUI

struct IPadDashboardView: View {
    let stats: [MemberStats]
    let dateRange: DateInterval?
    let athleteProfile: AthleteProfile
    let activities: [Activity]
    @Binding var selectedWeekOffset: Int
    let onWeekChanged: () -> Void

    // MARK: - Tab definition

    enum IPadTab: String, CaseIterable, Hashable {
        case main        = "This Week"
        case leaderboard = "Leaderboard"
        case insights    = "Insights"
        case analysis    = "Analysis"

        var icon: String {
            switch self {
            case .main:        return "bicycle"
            case .leaderboard: return "trophy.fill"
            case .insights:    return "bolt.circle.fill"
            case .analysis:    return "waveform.path.ecg"
            }
        }
    }

    @State private var selectedTab: IPadTab = .main
    @State private var showTokenCopiedToast = false

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {

            Tab("This Week", systemImage: IPadTab.main.icon, value: IPadTab.main) {
                NavigationStack {
                    IPadMainTabView(
                        stats: stats,
                        dateRange: dateRange,
                        athleteProfile: athleteProfile,
                        activities: activities,
                        selectedWeekOffset: $selectedWeekOffset,
                        onWeekChanged: onWeekChanged
                    )
                    .toolbar { profileToolbarItem }
                    .containerBackground(Color.appBackground, for: .navigation)
                }
            }
            .customizationID("tab.thisweek")

            Tab("Leaderboard", systemImage: IPadTab.leaderboard.icon, value: IPadTab.leaderboard) {
                IPadLeaderboardView(
                    stats: stats,
                    activities: activities,
                    dateRange: dateRange,
                    userInitial: userInitial,
                    onCopyToken: copyTokenToClipboard,
                    onLogOut: { StravaAPI.shared.logout() }
                )
            }
            .customizationID("tab.leaderboard")

            Tab("Insights", systemImage: IPadTab.insights.icon, value: IPadTab.insights) {
                NavigationStack {
                    IPadInsightsView(
                        athleteProfile: athleteProfile,
                        allStats: stats,
                        allActivities: activities
                    )
                    .toolbar { profileToolbarItem }
                    .containerBackground(Color.appBackground, for: .navigation)
                }
            }
            .customizationID("tab.insights")

            Tab("Analysis", systemImage: IPadTab.analysis.icon, value: IPadTab.analysis) {
                IPadAnalysisView(
                    stats: stats,
                    activities: activities,
                    userInitial: userInitial,
                    onCopyToken: copyTokenToClipboard,
                    onLogOut: { StravaAPI.shared.logout() }
                )
            }
            .customizationID("tab.analysis")
        }
        .tabViewStyle(.sidebarAdaptable)
        // Reset stale tab customization state (from prior 5-tab layout).
        // Version suffix forces a fresh layout when tab structure changes.
        .tabViewCustomization(.constant(TabViewCustomization()))
        // Show tabs as a tab bar (not sidebar) by default.
        .defaultAdaptableTabBarPlacement(.tabBar)
        .overlay(tokenCopiedToast, alignment: .bottom)
    }

    // MARK: - Profile Toolbar Item

    @ToolbarContentBuilder
    private var profileToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    copyTokenToClipboard()
                } label: {
                    Label("Copy Token for Apple TV", systemImage: "appletv")
                }

                Divider()

                Button(role: .destructive) {
                    StravaAPI.shared.logout()
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.dccSaffron.opacity(0.18))
                        .frame(width: 34, height: 34)
                    Text(userInitial)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.dccSaffron)
                }
            }
        }
    }

    private var userInitial: String {
        String(athleteProfile.firstname.prefix(1)).uppercased()
    }

    // MARK: - Token copy helper

    private func copyTokenToClipboard() {
        if let token = BiometricAuth.shared.loadStravaToken() {
            // Encode a JSON bundle so tvOS can auto-refresh without re-entering the token
            var payload: [String: Any] = ["access_token": token]
            if let rt = StravaAPI.shared.currentRefreshToken { payload["refresh_token"] = rt }
            let exp = StravaAPI.shared.currentTokenExpiresAt
            if exp > 0 { payload["expires_at"] = exp }
            if let data = try? JSONSerialization.data(withJSONObject: payload),
               let json = String(data: data, encoding: .utf8) {
                UIPasteboard.general.string = json
            } else {
                UIPasteboard.general.string = token
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showTokenCopiedToast = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showTokenCopiedToast = false
                }
            }
        }
    }

    // MARK: - Token Copied Toast

    @ViewBuilder
    private var tokenCopiedToast: some View {
        if showTokenCopiedToast {
            Label("Token copied for Apple TV", systemImage: "checkmark.circle.fill")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .glassEffect(
                    .regular.tint(Color.dccGreen.opacity(0.2)),
                    in: .capsule
                )
                .padding(.bottom, Spacing.xxl)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

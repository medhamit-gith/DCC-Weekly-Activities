//
//  RootView.swift
//  DCC-Weekly-Activities
//
//  Root navigation shell – handles auth state and top-level routing.
//
// iOS ONLY — do not add to tvOS target
// tvOS uses TVLoginView.swift instead
//
//  VERSION HISTORY:
//  2026-02-28: [HOTFIX] Fixed post-login crash/freeze caused by main thread violation
//              in .onOpenURL handler. Task now properly isolated to @MainActor.
//

import SwiftUI
import Charts
import LocalAuthentication

struct RootView: View {
    @State private var stravaAPI  = StravaAPI.shared
    @State private var biometric  = BiometricAuth.shared
    @State private var clubAuth   = ClubCodeAuthService.shared
    @State private var cloudData  = CloudDataFetcher.shared
    @State private var showLaunch = true
    /// Flipped to true only after the launch animation fully dismisses.
    /// BiometricGateView waits on this before prompting Face ID, ensuring
    /// the system Face ID sheet is never presented while the app is still
    /// rendering the launch overlay (which silently suppresses the prompt).
    @State private var launchDismissed = false

    var body: some View {
        ZStack {
            Group {
                if !clubAuth.isAuthenticated {
                    // ── Approach A: Club code entry (no Strava OAuth) ──────────
                    ClubCodeLoginView()
                } else if !biometric.isAuthenticated {
                    // ── Device lock verification (unchanged) ───────────────────
                    BiometricGateView(launchDismissed: launchDismissed)
                } else {
                    // ── Fully authenticated — WeeklyDashboardView loads data from Worker ──
                    WeeklyDashboardView()
                }
            }
            .task {
                // ── Restore both tokens from keychain on cold launch ─────────
                // The access token gets the user past the BiometricGate UI check.
                // The refresh token is critical: without it, refreshAccessToken()
                // always fails immediately (refreshToken == nil) and the user is
                // logged out silently every time the 6-hour access token expires.
                let savedAccess = biometric.loadStravaToken()
                if let savedAccess {
                    stravaAPI.accessToken = savedAccess
                    #if targetEnvironment(simulator)
                    if savedAccess.hasPrefix("SIMULATOR_DEMO_TOKEN_") {
                        stravaAPI.restoreDemoMode()
                        AppLogger.success("[Launch] Restored demo token — demo mode active")
                    } else {
                        AppLogger.success("[Launch] Restored accessToken — will prompt Face ID after animation")
                    }
                    #else
                    AppLogger.success("[Launch] Restored accessToken — will prompt Face ID after animation")
                    #endif

                    // Restore refresh token so silent token refresh works after relaunch
                    if let savedRefresh = biometric.loadStravaRefreshToken() {
                        stravaAPI.restoreRefreshToken(savedRefresh)
                        AppLogger.success("[Launch] Restored refreshToken from keychain")
                    } else {
                        AppLogger.warning("[Launch] No refresh token in keychain — silent refresh unavailable until next OAuth")
                    }
                } else {
                    AppLogger.warning("[Launch] No saved token — showing LoginView")
                }
                biometric.checkBiometricAvailability()
            }
            .onOpenURL { url in
                // This fires when the OS routes a dcc-activities:// URL to the app
                // from OUTSIDE (e.g., Strava app redirect after ASWebAuthenticationSession
                // is not present). When ASWebAuthenticationSession handles OAuth it delivers
                // the callback directly to its closure — onOpenURL is a safety-net fallback.
                OAuthLog.step("onOpenURL fired — url: \(url.absoluteString)")
                Task { @MainActor in
                    let success = await stravaAPI.handleRedirect(url: url)
                    // Note: token is already saved to keychain inside handleRedirect → exchangeCodeViaProxy.
                    // No duplicate save needed here.
                    OAuthLog.step("onOpenURL handleRedirect result: \(success ? "success" : "failed/duplicate")")
                }
            }
            // CrashErrorView overlay — surfaces any StravaAPI error as the animated crash screen.
            // Bound to stravaAPI.lastError; cleared automatically on retry success.
            .crashErrorOverlay(error: stravaAPI.lastError) {
                // If there is no access token the error came from a failed OAuth attempt —
                // retry by restarting OAuth, not by trying to refresh a token that doesn't exist.
                if stravaAPI.accessToken == nil {
                    stravaAPI.lastError = nil
                    stravaAPI.beginOAuth()
                    return
                }
                // Token present but stale — attempt a silent refresh.
                // If that also fails, force logout so the user sees the Login screen.
                let refreshed = await UserAuthService.shared.refreshAccessToken()
                if !refreshed && stravaAPI.lastError != nil {
                    stravaAPI.logout()
                }
            }
            
            // Launch animation overlay
            if showLaunch {
                LaunchAnimationView()
                    .transition(.opacity)
                    .zIndex(1000)
            }
        }
        .onAppear {
            // ── Launch diagnostics ──────────────────────────────────────────
            let ctx = LAContext()
            var biometricError: NSError?
            let biometryAvailable = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &biometricError)
            AppLogger.log("[Launch] App appeared — biometry available: \(biometryAvailable), type: \(ctx.biometryType.rawValue)", category: "Launch")
            AppLogger.log("[Launch] accessToken in memory: \(stravaAPI.accessToken != nil ? "yes" : "nil"), isAuthenticated: \(biometric.isAuthenticated)", category: "Launch")

            // Dismiss launch screen after 2.5 seconds, then signal that Face ID can fire.
            // The 0.1s gap after the fade lets the hosting view fully settle before
            // the system Face ID sheet is presented — avoids silent suppression.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showLaunch = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    AppLogger.log("[Launch] Animation dismissed — signalling launchDismissed", category: "Launch")
                    launchDismissed = true
                }
            }
        }
    }
}

// MARK: - Login screen

struct LoginView: View {
    /// Passed from RootView so that BiometricGateView (shown after OAuth) receives
    /// launchDismissed=true and auto-fires Face ID without any user interaction.
    let launchDismissed: Bool

    @State private var biometric = BiometricAuth.shared
    @State private var stravaAPI = StravaAPI.shared

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.dccBlue.opacity(0.15), Color.dccSaffron.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                #if targetEnvironment(simulator)
                // Simulator banner — tap "Demo" for instant mock data,
                // tap "Real Data" to run the full OAuth flow with your Strava account.
                HStack(spacing: 8) {
                    Image(systemName: "desktopcomputer")
                        .font(.caption)
                    Text("Simulator")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Divider()
                        .frame(height: 14)
                        .background(.white.opacity(0.5))
                    Button("Demo Mode") {
                        StravaAPI.shared.beginOAuth()
                    }
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.25))
                    .clipShape(Capsule())
                    Button("Real Data") {
                        StravaAPI.shared.beginRealOAuth()
                    }
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.25))
                    .clipShape(Capsule())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.85))
                .clipShape(Capsule())
                .padding(.bottom, 12)
                #endif

                GlassWelcomeCard(
                    onConnect: { StravaAPI.shared.beginOAuth() },
                    biometricType: biometric.biometricType,
                    isAuthenticating: stravaAPI.isAuthenticating
                )
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Biometric gate

struct BiometricGateView: View {
    /// Passed from RootView — true once the launch animation has fully dismissed.
    /// Face ID is not triggered until this is true, preventing silent suppression
    /// of the system sheet while the launch overlay is still on screen.
    let launchDismissed: Bool

    @State private var biometric    = BiometricAuth.shared
    @State private var stravaAPI    = StravaAPI.shared
    @State private var showError    = false
    @State private var isRefreshing = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.dccBlue.opacity(0.15), Color.dccSaffron.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Image(systemName: biometric.biometricType.icon)
                    .font(.system(size: 72))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.dccSaffron, Color.dccGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Unlock DCC Weekly Activities")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                if isRefreshing {
                    ProgressView("Reconnecting…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if showError {
                    Text("Authentication failed. Please try again.")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }

                Button("Authenticate with \(biometric.biometricType.displayName)") {
                    Task { await authenticate() }
                }
                .buttonStyle(.dccGlass(tintColor: Color.dccSaffron, isProminent: true))
                .disabled(isRefreshing)

                Button("Log Out") {
                    StravaAPI.shared.logout()
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .disabled(isRefreshing)
            }
            .padding(32)
        }
        // Fire Face ID as soon as launchDismissed flips to true.
        // Using .onChange rather than .task so it triggers even if this view
        // was already on screen waiting for the animation to finish.
        .onChange(of: launchDismissed) { _, dismissed in
            guard dismissed else { return }
            BiometricLog.step("launchDismissed=true — auto-triggering Face ID")
            Task { await authenticate() }
        }
        // Fallback: if launchDismissed was already true when the view appeared
        // (e.g. mid-session re-lock after token expiry), fire immediately.
        .task {
            if launchDismissed {
                BiometricLog.step("BiometricGateView appeared post-launch — auto-triggering authenticate()")
                await authenticate()
            } else {
                BiometricLog.step("BiometricGateView appeared — waiting for launchDismissed signal")
            }
        }
    }

    private func authenticate() async {
        BiometricLog.step("authenticate() called — isDemoMode=\(StravaAPI.shared.isDemoMode)")
        showError = false
        let success = await biometric.authenticate()
        BiometricLog.step("authenticate() result: \(success ? "✅ success" : "❌ failed") — isAuthenticated=\(biometric.isAuthenticated)")

        guard success else {
            showError = true
            return
        }

        // Club-code flow does not use Strava OAuth, so only attempt a silent
        // refresh when an OAuth access token is actually present. Otherwise
        // isTokenFresh is always false and we'd log the user out in a loop.
        if stravaAPI.accessToken != nil && !stravaAPI.isTokenFresh {
            BiometricLog.step("Token stale after biometric — attempting silent refresh")
            isRefreshing = true
            let refreshed = await UserAuthService.shared.refreshAccessToken()
            isRefreshing = false
            if refreshed {
                BiometricLog.step("Silent token refresh ✅ — dashboard will load fresh data")
            } else {
                BiometricLog.warn("Silent refresh failed — forcing full re-login")
                // Token is unrecoverable: clear everything so the user sees LoginView
                stravaAPI.logout()
            }
        }
    }
}

// MARK: - Main dashboard (replace with your real tab/navigation view)

struct WeeklyDashboardView: View {
    @State private var stravaAPI = StravaAPI.shared
    @State private var cloudData = CloudDataFetcher.shared
    @State private var clubAuth  = ClubCodeAuthService.shared
    @State private var stats: [MemberStats] = []
    @State private var activities: [Activity] = []
    @State private var athleteProfile: AthleteProfile?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTab = 0
    @State private var dateRange: (start: Date, end: Date)?
    /// 0 = this week, -1 = last week, -2 = two weeks ago, etc. (max 4 weeks back)
    @State private var selectedWeekOffset: Int = 0

    var body: some View {
        Group {
            if isLoading && athleteProfile == nil {
                // Initial loading - fetching athlete profile
                ZStack {
                    Color.appBackground.ignoresSafeArea()
                    
                    VStack(spacing: Spacing.lg) {
                        ProgressView()
                            .tint(Color.accent)
                        
                        Text("Loading your profile…")
                            .font(.bodyDefault)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            } else if let error = errorMessage {
                // Error state
                ZStack {
                    Color.appBackground.ignoresSafeArea()
                    
                    VStack(spacing: Spacing.lg) {
                        EmptyStateView(
                            icon: "exclamationmark.triangle",
                            title: "Error Loading Data",
                            message: error
                        )
                        
                        Button {
                            // Reset athleteProfile so loadInitialData() runs the full
                            // fetch path rather than skipping to loadClubActivities()
                            athleteProfile = nil
                            errorMessage   = nil
                            Task { await loadInitialData() }
                        } label: {
                            Text("Retry")
                                .font(.bodyDefault)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.textPrimary)
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.sm)
                                .background(Color.accent)
                                .cornerRadius(CornerRadius.md)
                        }
                        

                    }
                    .padding(Spacing.xl)
                }
                    } else if let profile = athleteProfile {
                // Show professional dashboard
                dashboardContent(profile: profile)
            } else {
                // Fallback: shouldn't reach here but if we do, show loading
                ZStack {
                    Color.appBackground.ignoresSafeArea()
                    
                    VStack(spacing: Spacing.lg) {
                        ProgressView()
                            .tint(Color.accent)
                        
                        Text("Initializing…")
                            .font(.bodyDefault)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
        }
        .task {
            #if DEBUG
            print("🟢 [Dashboard] WeeklyDashboardView appeared — starting loadInitialData. token=\(stravaAPI.accessToken != nil ? "✅" : "❌") isDemoMode=\(stravaAPI.isDemoMode)")
            #endif
            await loadInitialData()
        }
    }
    
    // MARK: Dashboard Content - Main Tab View
    
    @ViewBuilder
    private func dashboardContent(profile: AthleteProfile) -> some View {
        if isLoading {
            // Loading state with skeleton
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: Spacing.lg) {
                    SkeletonCard(height: 200) // Hero section
                    
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: Spacing.sm),
                            GridItem(.flexible(), spacing: Spacing.sm)
                        ],
                        spacing: Spacing.sm
                    ) {
                        SkeletonCard(height: 120)
                        SkeletonCard(height: 120)
                        SkeletonCard(height: 120)
                        SkeletonCard(height: 120)
                    }
                    
                    SkeletonCard(height: 300) // Podium section
                }
                .padding(Spacing.md)
            }
        } else {
            // Main professional dashboard — routes to iPad or iPhone layout
            AdaptiveDashboardRouter(
                stats: stats,
                dateRange: dateRange.map { DateInterval(start: $0.start, end: $0.end) },
                athleteProfile: profile,
                activities: activities,
                selectedWeekOffset: $selectedWeekOffset,
                onWeekChanged: { Task { await loadClubActivities() } }
            )
        }
    }

    // MARK: Data loading

    private func loadInitialData() async {
        #if DEBUG
        print("[PostLogin] loadInitialData called, athleteProfile exists: \(athleteProfile != nil)")
        #endif

        // Build the viewer's athlete profile from the club-code entry.
        // The Cloudflare worker is the source of truth for club activities, so
        // we no longer need a Strava-authenticated athlete here.
        if athleteProfile == nil {
            athleteProfile = makeLocalProfile()
        }

        await loadClubActivities()
    }

    private func makeLocalProfile() -> AthleteProfile {
        let name = clubAuth.memberName.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = name.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true).map(String.init)
        let first = parts.first ?? (name.isEmpty ? "DCC" : name)
        let last  = parts.count > 1 ? parts[1] : "Member"
        return AthleteProfile(
            id: 0,
            firstname: first,
            lastname: last,
            profile: nil,
            city: nil,
            state: nil,
            country: nil
        )
    }

    private func loadClubActivities() async {
        #if DEBUG
        print("[PostLogin] loadClubActivities started (weekOffset=\(selectedWeekOffset))")
        #endif
        isLoading = true
        errorMessage = nil

        await cloudData.fetchData(weekOffset: selectedWeekOffset)

        if let msg = cloudData.errorMessage {
            #if DEBUG
            print("[PostLogin] ❌ Error in loadClubActivities: \(msg)")
            #endif
            errorMessage = msg
            isLoading = false
            return
        }

        let currentActs  = cloudData.toActivities()
        let previousActs = cloudData.toPreviousWeekActivities()
        #if DEBUG
        print("[PostLogin] Worker returned \(currentActs.count) current + \(previousActs.count) previous activities")
        #endif

        activities = currentActs.sorted { $0.date > $1.date }
        stats = buildMemberStats(from: currentActs, previousWeekActivities: previousActs)

        if selectedWeekOffset == 0 {
            WeeklyCache.save(stats)
        }

        NotificationCenter.default.post(name: NSNotification.Name("DCCDataLoadComplete"), object: nil)

        let interval = DateRangeProvider.weekRange(offset: selectedWeekOffset)
        dateRange = (start: interval.start, end: interval.end)
        #if DEBUG
        print("[PostLogin] Date range: \(interval.start) – \(interval.end)")
        print("[PostLogin] ✅ Processed into \(stats.count) member stats")
        #endif

        isLoading = false
    }
    
    private func loadData() async {
        await loadClubActivities()
    }

    // MARK: - Build Member Stats

    /// Builds per-member stats from current and previous week activities.
    ///
    /// Previous week data priority:
    /// 1. Live API data passed in `previousWeekActivities` (from the two-week fetch)
    /// 2. Weekly disk cache as fallback (for new members not in the API batch)
    private func buildMemberStats(
        from activities: [Activity],
        previousWeekActivities: [Activity] = []
    ) -> [MemberStats] {
        let aggToken = PerformanceLogger.shared.start(label: "Aggregation", category: .viewRender)

        #if DEBUG
        print("[BuildStats] ══════════════════════════════════════════")
        print("[BuildStats] Current: \(activities.count) activities | Previous: \(previousWeekActivities.count) activities")
        #endif

        // Group current week activities by member
        let currentGrouped = Dictionary(grouping: activities, by: \.memberName)
        #if DEBUG
        print("[BuildStats] Current week: \(currentGrouped.count) unique members")
        #endif

        // Group previous week activities by member (live data from API)
        let previousGrouped = Dictionary(grouping: previousWeekActivities, by: \.memberName)
        #if DEBUG
        print("[BuildStats] Previous week (live): \(previousGrouped.count) unique members")
        #endif

        // Cache fallback for members who appear in current week but not in previous API batch
        let cacheLookup = WeeklyCache.previousWeekLookup()
        #if DEBUG
        print("[BuildStats] Previous week (cache): \(cacheLookup.count) members")

        for (name, acts) in currentGrouped {
            let km = acts.reduce(0.0) { $0 + $1.distance }
            print("[BuildStats]   '\(name)': current \(acts.count) rides, \(String(format: "%.1f", km))km")
        }
        #endif

        let stats = currentGrouped.map { name, currentActs -> MemberStats in

            // Priority 1: live previous week data from the API two-week fetch
            if let prevActs = previousGrouped[name], !prevActs.isEmpty {
                let prevKM = prevActs.reduce(0.0) { $0 + $1.distance }
                #if DEBUG
                print("[BuildStats]   '\(name)': prev (live) \(prevActs.count) rides, \(String(format: "%.1f", prevKM))km")
                #endif
                return MemberStats(memberName: name, activities: currentActs, previousWeekActivities: prevActs)
            }

            // Priority 2: disk cache (from a prior session that saved this week's data)
            if let cached = cacheLookup[name] {
                #if DEBUG
                print("[BuildStats]   '\(name)': prev (cache) \(String(format: "%.1f", cached.weekKM))km")
                #endif
                let synth = Activity(
                    memberName: name,
                    activityName: "Previous Week Total",
                    distance: cached.weekKM,
                    date: Date().addingTimeInterval(-7 * 24 * 3600),
                    averageSpeed: cached.avgSpeed,
                    elevationGain: cached.elevation,
                    movingTime: 0,
                    type: "Summary"
                )
                return MemberStats(memberName: name, activities: currentActs, previousWeekActivities: [synth])
            }

            // No previous data — new rider or first week
            #if DEBUG
            print("[BuildStats]   '\(name)': no previous week data")
            #endif
            return MemberStats(memberName: name, activities: currentActs, previousWeekActivities: [])
        }
        .sorted { $0.totalKM > $1.totalKM }

        PerformanceLogger.shared.stop(token: aggToken, detail: "\(stats.count) members")
        #if DEBUG
        print("[BuildStats] ✅ Returning \(stats.count) member stats")
        print("[BuildStats] ══════════════════════════════════════════")
        #endif
        return stats
    }
}

// MARK: - Inline Week Picker

/// Compact inline week selector used in the iPad date header row.
/// Replaces the static "Week N" pill with ← "This Week" / "Last Week" →  navigation.
struct InlineWeekPicker: View {
    @Binding var selectedWeekOffset: Int
    let onWeekChanged: () -> Void

    private let maxWeeksBack = 4
    private var canGoBack: Bool    { selectedWeekOffset > -maxWeeksBack }
    private var canGoForward: Bool { selectedWeekOffset < 0 }

    var body: some View {
        HStack(spacing: 0) {
            // ← Back
            Button {
                guard canGoBack else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    selectedWeekOffset -= 1
                }
                onWeekChanged()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(canGoBack ? Color.accent : Color.textSecondary.opacity(0.35))
                    .frame(width: 32, height: 32)
            }
            .disabled(!canGoBack)

            // Centre label
            HStack(spacing: 5) {
                Image(systemName: selectedWeekOffset == 0 ? "calendar.badge.clock" : "calendar")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.accent)
                Text("Week \(weekNumberLabel)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.accent)
                    .contentTransition(.numericText())
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedWeekOffset)

            // → Forward
            Button {
                guard canGoForward else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    selectedWeekOffset += 1
                }
                onWeekChanged()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(canGoForward ? Color.accent : Color.textSecondary.opacity(0.35))
                    .frame(width: 32, height: 32)
            }
            .disabled(!canGoForward)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .glassEffect(.regular.tint(Color.accent.opacity(0.12)), in: .capsule)
    }

    /// ISO week number for the selected week
    private var weekNumberLabel: String {
        let interval = DateRangeProvider.weekRange(offset: selectedWeekOffset)
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let weekNum = cal.component(.weekOfYear, from: interval.start)
        return "\(weekNum)"
    }
}

// MARK: - Week Picker Banner

/// Floating glass week selector shown at the very top of the dashboard.
/// Users tap ← → to navigate between weeks (up to 4 weeks back).
/// Triggers an API reload whenever the selected week changes.
struct WeekPickerBanner: View {
    @Binding var selectedWeekOffset: Int
    let isLoading: Bool
    let onWeekChanged: () -> Void

    /// Maximum weeks the user can look back (Strava club endpoint has a rolling window)
    private let maxWeeksBack = 4

    @State private var appeared = false

    private var canGoBack: Bool { selectedWeekOffset > -maxWeeksBack }
    private var canGoForward: Bool { selectedWeekOffset < 0 }

    private var weekLabel: String {
        DateRangeProvider.weekOffsetLabel(selectedWeekOffset)
    }

    private var dateRangeLabel: String {
        let interval = DateRangeProvider.weekRange(offset: selectedWeekOffset)
        return DateRangeProvider.formatDateRange(interval)
    }

    var body: some View {
        HStack(spacing: 0) {
            // ← Back button
            Button {
                guard canGoBack && !isLoading else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    selectedWeekOffset -= 1
                }
                onWeekChanged()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(canGoBack && !isLoading ? Color.textPrimary : Color.textSecondary.opacity(0.4))
                    .frame(width: 44, height: 44)
            }
            .disabled(!canGoBack || isLoading)

            // Centre label
            VStack(spacing: 3) {
                HStack(spacing: 6) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(Color.accent)
                    } else {
                        Image(systemName: selectedWeekOffset == 0 ? "calendar.badge.clock" : "calendar")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.accent)
                    }
                    Text(weekLabel)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                        .contentTransition(.numericText())
                }
                Text(dateRangeLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
                    .contentTransition(.numericText())
            }
            .frame(minWidth: 160)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedWeekOffset)

            // → Forward button
            Button {
                guard canGoForward && !isLoading else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    selectedWeekOffset += 1
                }
                onWeekChanged()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(canGoForward && !isLoading ? Color.textPrimary : Color.textSecondary.opacity(0.4))
                    .frame(width: 44, height: 44)
            }
            .disabled(!canGoForward || isLoading)
        }
        .padding(.horizontal, 4)
        .glassEffect(
            .regular.tint(Color.appBackground.opacity(0.85)),
            in: .capsule
        )
        .padding(.top, 8)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.92)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
                appeared = true
            }
        }
    }
}

// MARK: - Professional UI Components

struct SkeletonCard: View {
    let height: CGFloat
    @State private var phase: CGFloat = 0
    
    var body: some View {
        RoundedRectangle(cornerRadius: CornerRadius.lg)
            .fill(Color.surface)
            .frame(height: height)
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
                    .onAppear {
                        withAnimation(
                            .linear(duration: 1.5)
                            .repeatForever(autoreverses: false)
                        ) {
                            phase = 1
                        }
                    }
                }
            )
            .clipped()
    }
}

struct AnimatedCounter: View {
    let value: Double
    let duration: Double
    let format: (Double) -> String
    
    @State private var displayValue: Double = 0
    
    init(
        value: Double,
        duration: Double = 1.0,
        format: @escaping (Double) -> String = { String(format: "%.0f", $0) }
    ) {
        self.value = value
        self.duration = duration
        self.format = format
    }
    
    var body: some View {
        Text(format(displayValue))
            .monospacedDigit()
            .onAppear {
                withAnimation(.easeOut(duration: duration)) {
                    displayValue = value
                }
            }
            .onChange(of: value) { oldValue, newValue in
                withAnimation(.easeOut(duration: duration / 2)) {
                    displayValue = newValue
                }
            }
    }
}

struct TrendBadge: View {
    let percentage: Double
    let isPositive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 10, weight: .medium))
            
            Text(String(format: "%.1f%%", abs(percentage)))
                .font(.labelDefault)
                .fontWeight(.semibold)
        }
        .foregroundStyle(isPositive ? Color.success : Color.error)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill((isPositive ? Color.success : Color.error).opacity(0.15))
        )
    }
}

struct QuickStatCard: View {
    let value: String
    let unit: String
    let label: String
    let icon: String
    let color: Color
    
    @State private var isAnimated = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                
                Spacer()
            }
            
            Spacer()
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.mediumStat)
                    .fontWeight(.black)
                    .monospacedDigit()
                    .foregroundStyle(Color.textPrimary)
                
                Text(unit)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
            }
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.textSecondary)
        }
        .padding(Spacing.md)
        .frame(height: 120)
        .background(Color.surface)
        .cornerRadius(CornerRadius.lg)
        .scaleEffect(isAnimated ? 1 : 0.9)
        .opacity(isAnimated ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                isAnimated = true
            }
        }
    }
}

struct RiderPodiumCard: View {
    let rank: Int
    let rider: MemberStats
    let isCompact: Bool
    
    var podiumGradient: LinearGradient {
        switch rank {
        case 1: return LinearGradient(colors: [Color(hex: "#FFD700"), Color(hex: "#FFA500")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 2: return LinearGradient(colors: [Color(hex: "#C0C0C0"), Color(hex: "#808080")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 3: return LinearGradient(colors: [Color(hex: "#CD7F32"), Color(hex: "#8B4513")], startPoint: .topLeading, endPoint: .bottomTrailing)
        default: return LinearGradient(colors: [.surface], startPoint: .top, endPoint: .bottom)
        }
    }
    
    var rankColor: Color {
        switch rank {
        case 1: return Color(hex: "#FFD700")
        case 2: return Color(hex: "#C0C0C0")
        case 3: return Color(hex: "#CD7F32")
        default: return Color.textSecondary
        }
    }
    
    var body: some View {
        if isCompact {
            compactCard
        } else {
            podiumCard
        }
    }
    
    @ViewBuilder
    private var podiumCard: some View {
        VStack(spacing: Spacing.sm) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(podiumGradient)
                    .frame(width: 56, height: 56)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                Text("\(rank)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            // Avatar placeholder
            ZStack {
                Circle()
                    .fill(Color.surfaceElevated)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle()
                            .stroke(podiumGradient, lineWidth: 3)
                    )
                
                Text(String(rider.memberName.prefix(1)))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
            }
            
            // Name
            Text(rider.memberName)
                .font(.cardTitle)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            // Main stat - Distance
            VStack(spacing: 2) {
                Text(String(format: "%.1f", rider.totalKM))
                    .font(.largeStat)
                    .fontWeight(.black)
                    .monospacedDigit()
                    .foregroundStyle(rankColor)
                
                Text("km")
                    .font(.labelDefault)
                    .foregroundStyle(Color.textSecondary)
            }
            
            Divider()
                .background(Color.textSecondary.opacity(0.2))
            
            // Secondary stats
            HStack(spacing: Spacing.md) {
                VStack(spacing: 2) {
                    Image(systemName: "mountain.2.fill")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    
                    Text(String(format: "%.0f", rider.totalElevation))
                        .font(.system(size: 14, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Color.textPrimary)
                    
                    Text("m")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.textSecondary)
                }
                
                VStack(spacing: 2) {
                    Image(systemName: "flag.checkered")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    
                    Text("\(rider.totalRides)")
                        .font(.system(size: 14, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Color.textPrimary)
                    
                    Text("rides")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .padding(Spacing.md)
        .frame(width: 160)
        .background(Color.surface)
        .cornerRadius(CornerRadius.xl)
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
    }
    
    @ViewBuilder
    private var compactCard: some View {
        HStack(spacing: Spacing.sm) {
            // Rank
            Text("\(rank)")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(rank <= 3 ? rankColor : Color.textSecondary)
                .frame(width: 32)
            
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.surfaceElevated)
                    .frame(width: 40, height: 40)
                
                Text(String(rider.memberName.prefix(1)))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
            }
            
            // Name
            Text(rider.memberName)
                .font(.bodyDefault)
                .fontWeight(.medium)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
            
            Spacer()
            
            // Distance bar indicator
            HStack(spacing: 4) {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.surfaceElevated)
                        .frame(width: 60, height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accent)
                        .frame(width: 60, height: 8)
                }
                
                Text(String(format: "%.1f", rider.totalKM))
                    .font(.system(size: 14, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 50, alignment: .trailing)
            }
        }
        .padding(Spacing.sm)
        .background(Color.surface)
        .cornerRadius(CornerRadius.md)
    }
}

struct BestRideCard: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Activity type icon
            ZStack {
                Circle()
                    .fill(Color.accent.opacity(0.2))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "bicycle")
                    .font(.title2)
                    .foregroundStyle(Color.accent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.activityName)
                    .font(.cardTitle)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                
                Text(activity.memberName)
                    .font(.bodyDefault)
                    .foregroundStyle(Color.textSecondary)
                
                HStack(spacing: Spacing.sm) {
                    Label(String(format: "%.1f km", activity.distance), systemImage: "arrow.left.and.right")
                        .font(.labelDefault)
                        .foregroundStyle(Color.textSecondary)
                    
                    Label(String(format: "%.1f km/h", activity.averageSpeed), systemImage: "speedometer")
                        .font(.labelDefault)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            
            Spacer()
            
            // Trophy
            Image(systemName: "trophy.fill")
                .font(.title)
                .foregroundStyle(Color(hex: "#FFD700"))
        }
        .padding(Spacing.md)
        .background(Color.surface)
        .cornerRadius(CornerRadius.lg)
    }
}

// MARK: - Professional Dashboard View

struct ProfessionalDashboardView: View {
    let stats: [MemberStats]
    let dateRange: DateInterval?
    let athleteProfile: AthleteProfile
    let activities: [Activity]
    
    @State private var showPerformanceDashboard = false
    @State private var showTokenCopiedToast = false
    
    private var userInitial: String {
        String(athleteProfile.firstname.prefix(1)).uppercased()
    }
    
    // CHANGE 2: New DCCTab enum
    enum DCCTab: String, CaseIterable {
        case main = "Main"
        case overview = "Overview"
        case leaderboard = "Leaderboard"
        case insights = "Insights"
        case analysis = "Analysis"
        
        // CHANGE 1: Cycling-themed icons
        var icon: String {
            switch self {
            case .main: return "bicycle"
            case .overview: return "chart.bar.fill"
            case .leaderboard: return "trophy.fill"
            case .insights: return "bolt.circle.fill"
            case .analysis: return "waveform.path.ecg"
            }
        }
        
        // CHANGE 1: Display titles
        var title: String {
            switch self {
            case .main: return "Ride"
            case .overview: return "Overview"
            case .leaderboard: return "Leaders"
            case .insights: return "Insights"
            case .analysis: return "Analysis"
            }
        }
    }
    
    @State private var selectedDCCTab: DCCTab = .main
    @Namespace private var tabIndicator
    @State private var iconBounce = false // CHANGE 3: Icon bounce animation
    
    // Analysis tab state — rider chip selector
    @State private var analysisViewModel = InsightsViewModel()
    
    // CHANGE 5: Tab state persistence with logging
    private func switchTab(to tab: DCCTab) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedDCCTab = tab
        }
        // Haptic is delivered via .sensoryFeedback(.impact, trigger: selectedDCCTab) on the body

        PerformanceLogger.shared.logInstant(
            label: tab.rawValue,
            category: .screenLoad,
            durationMs: 0,
            success: true,
            detail: "Tab switch"
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                // CHANGE 2 & 3: Fixed header/tab bar, scrollable content
                VStack(spacing: 0) {
                    // Fixed: Top navigation bar (header only, no tabs)
                    headerBar
                    
                    // Fixed: Horizontal tab switcher bar
                    tabSwitcherBar
                    
                    // Tab content — uses TabView with page style so each tab
                    // has its own independent scroll position and renders correctly.
                    // The custom tabSwitcherBar above drives selectedDCCTab.
                    TabView(selection: $selectedDCCTab) {
                        ScrollView {
                            mainTabContent
                                .padding(.bottom, 20)
                        }
                        .tag(DCCTab.main)

                        ScrollView {
                            VStack(spacing: Spacing.lg) {
                                overviewContent
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.bottom, 20)
                        }
                        .tag(DCCTab.overview)

                        ScrollView {
                            VStack(spacing: Spacing.lg) {
                                leaderboardContent
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.bottom, 20)
                        }
                        .tag(DCCTab.leaderboard)

                        insightsContent
                            .tag(DCCTab.insights)

                        analysisContent
                            .tag(DCCTab.analysis)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.25), value: selectedDCCTab)
                }
                
                // Performance Dashboard overlay
                if showPerformanceDashboard {
                    PerformanceDashboardView(
                        logger: PerformanceLogger.shared,
                        userName: "\(athleteProfile.firstname) \(athleteProfile.lastname)",
                        isPresented: $showPerformanceDashboard
                    )
                    .zIndex(999)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.97)),
                        removal: .opacity.combined(with: .scale(scale: 0.97))
                    ))
                }

                // Token copied toast
                if showTokenCopiedToast {
                    VStack {
                        Spacer()
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.success)
                            Text("Token copied — paste it into the Apple TV app")
                                .font(.bodyDefault)
                                .foregroundStyle(Color.textPrimary)
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(.ultraThinMaterial)
                        .cornerRadius(CornerRadius.xl)
                        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
                        .padding(.bottom, Spacing.xxl)
                    }
                    .zIndex(1000)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .ignoresSafeArea(edges: .bottom) // CHANGE 3: Ignore bottom safe area
            .navigationBarHidden(true)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: selectedDCCTab)
    }
    
    // Header bar (with animated cyclist home button)
    private var headerBar: some View {
        HStack(spacing: Spacing.md) {
            // Animated cyclist home button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    selectedDCCTab = .main
                }
                // Haptic delivered by .sensoryFeedback on NavigationStack
            } label: {
                AnimatedCyclistView(size: 32, showFlag: true, loop: true)
            }
            .buttonStyle(.plain)
            
            // Center: DCC branding
            HStack(spacing: Spacing.xs) {
                Image(systemName: "figure.outdoor.cycle")
                    .font(.headline)
                    .foregroundStyle(Color.accent)
                
                Text("DCC Weekly")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.textPrimary)
            }
            
            Spacer()
            
            // Right side: avatar button
            profileButton
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.surface.ignoresSafeArea(edges: .top))
    }
    
    // Horizontal tab switcher bar
    private var tabSwitcherBar: some View {
        VStack(spacing: 0) {
            tabButtonsContainer
            
            // CHANGE 4: Bottom border
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(height: 1)
        }
        // CHANGE 3: Icon bounce on tab change
        .onChange(of: selectedDCCTab) { oldValue, newValue in
            iconBounce = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                iconBounce = true
            }
        }
    }
    
    // MARK: - Tab Buttons Container
    
    private var tabButtonsContainer: some View {
        HStack(spacing: 0) {
            ForEach(DCCTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .frame(height: 58)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.3))
    }
    
    private func tabButton(for tab: DCCTab) -> some View {
        Button {
            switchTab(to: tab)
        } label: {
            tabButtonLabel(for: tab)
        }
        .buttonStyle(.plain)
    }
    
    private func tabButtonLabel(for tab: DCCTab) -> some View {
        let isSelected = selectedDCCTab == tab
        let foregroundColor = isSelected ? Color.accent : Color.white.opacity(0.4)
        let backgroundColor = isSelected ? Color.accent.opacity(0.15) : Color.clear
        
        return VStack(spacing: 3) {
            tabIcon(for: tab, isSelected: isSelected)
            
            Text(tab.title)
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(foregroundColor)
        .frame(maxWidth: .infinity)
        .frame(height: 58)
        .contentShape(Rectangle())
        .background(backgroundColor)
    }
    
    private func tabIcon(for tab: DCCTab, isSelected: Bool) -> some View {
        let scale = isSelected && iconBounce ? 1.3 : 1.0
        
        return Image(systemName: tab.icon)
            .font(.system(size: 20, weight: .medium))
            .scaleEffect(scale)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: iconBounce)
    }
    
    // Main tab content (hero + quick stats)
    private var mainTabContent: some View {
        VStack(spacing: Spacing.lg) {
            dateHeader
            heroSection
            quickStatsGrid
            performanceHighlight
            
            // Weekly Activity Report Table
            WeeklyReportTableView(stats: stats)
                .padding(.top, Spacing.sm)
        }
        .padding(.horizontal, Spacing.md)
    }
    
    @ViewBuilder
    private var dateHeader: some View {
        if let range = dateRange {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CURRENT WEEK")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.textSecondary)
                        .tracking(1.2)
                    
                    Text(DateRangeProvider.formatDateRange(range))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                }
                
                Spacer()
                
                Text("Week \(DateRangeProvider.weekNumber())")
                    .font(.labelDefault)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accent)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.accent.opacity(0.15)))
            }
            .padding(Spacing.md)
        }
    }
    
    private var heroSection: some View {
        let totalDistance = stats.reduce(0) { $0 + $1.totalKM }
        
        return VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Label("Club Total", systemImage: "figure.2.and.child.holdinghands")
                    .font(.sectionTitle)
                    .foregroundStyle(Color.textPrimary)
                
                Spacer()
                
                TrendBadge(percentage: 12.5, isPositive: true)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                AnimatedCounter(
                    value: totalDistance,
                    duration: 1.8,
                    format: { String(format: "%.1f", $0) }
                )
                .font(.heroStat)
                .fontWeight(.black)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accent, Color.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                Text("km")
                    .font(.sectionTitle)
                    .foregroundStyle(Color.textSecondary)
            }
            
            Text("Total distance ridden this week")
                .font(.bodyDefault)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .fill(LinearGradient(colors: [Color.surface, Color.surfaceElevated], startPoint: .topLeading, endPoint: .bottomTrailing))
                
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .fill(LinearGradient(colors: [Color.accent.opacity(0.1), Color.accent.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(LinearGradient(colors: [Color.accent.opacity(0.3), Color.accent.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
        .shadow(color: Color.accent.opacity(0.5), radius: 16, x: 0, y: 0)
    }
    
    private var quickStatsGrid: some View {
        let totalRides = stats.reduce(0) { $0 + $1.totalRides }
        let totalElevation = stats.reduce(0) { $0 + $1.totalElevation }
        let avgSpeed = stats.reduce(0.0) { $0 + $1.avgSpeed } / Double(max(stats.count, 1))
        let activeMembers = stats.count
        
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.sm), GridItem(.flexible(), spacing: Spacing.sm)], spacing: Spacing.sm) {
            QuickStatCard(value: "\(totalRides)", unit: "rides", label: "Total Rides", icon: "flag.checkered", color: Color.dccGreen)
            QuickStatCard(value: String(format: "%.0f", totalElevation), unit: "m", label: "Elevation", icon: "mountain.2.fill", color: Color.dccBlue)
            QuickStatCard(value: String(format: "%.1f", avgSpeed), unit: "km/h", label: "Avg Speed", icon: "speedometer", color: Color.accent)
            QuickStatCard(value: "\(activeMembers)", unit: "riders", label: "Active", icon: "person.3.fill", color: Color.dccSaffron)
        }
    }
    
    @ViewBuilder
    private var overviewContent: some View {
        VStack(spacing: Spacing.lg) {
            performanceHighlight
            
            // Weekly Activity Report Table
            WeeklyReportTableView(stats: stats)
                .padding(.top, Spacing.sm)
        }
        .onAppear {
            // CHANGE 5: Track screen load for Overview tab
            let token = PerformanceLogger.shared.start(label: "Overview", category: .screenLoad)
            DispatchQueue.main.async {
                PerformanceLogger.shared.stop(token: token)
            }
        }
    }
    
    @ViewBuilder
    private var leaderboardContent: some View {
        let sortedStats = stats.sorted { $0.totalKM > $1.totalKM }
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Full Rankings")
                    .font(.sectionTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.textPrimary)
                
                Spacer()
                
                Text("\(stats.count) riders")
                    .font(.labelDefault)
                    .foregroundStyle(Color.textSecondary)
            }
            
            if stats.count >= 3 {
                let topThree = Array(sortedStats.prefix(3))
                
                // Podium layout - uses ScrollView for horizontal overflow if needed
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        RiderPodiumCard(rank: 2, rider: topThree[1], isCompact: false)
                            .offset(y: Spacing.md)
                        
                        RiderPodiumCard(rank: 1, rider: topThree[0], isCompact: false)
                        
                        RiderPodiumCard(rank: 3, rider: topThree[2], isCompact: false)
                            .offset(y: Spacing.md)
                    }
                    .padding(.horizontal, 1) // Prevent edge clipping
                }
                .padding(.bottom, Spacing.md)
                
                if sortedStats.count > 3 {
                    Text("Other Riders")
                        .font(.cardTitle)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                        .padding(.top, Spacing.sm)
                    
                    LazyVStack(spacing: Spacing.xs) {
                        ForEach(Array(sortedStats.dropFirst(3).enumerated()), id: \.element.id) { index, rider in
                            RiderPodiumCard(rank: index + 4, rider: rider, isCompact: true)
                        }
                    }
                }
            } else {
                // Fewer than 3 riders — show compact ranked list for all
                LazyVStack(spacing: Spacing.xs) {
                    ForEach(Array(sortedStats.enumerated()), id: \.element.id) { index, rider in
                        RiderPodiumCard(rank: index + 1, rider: rider, isCompact: true)
                    }
                }
            }
        }
        .onAppear {
            // CHANGE 5: Track screen load for Leaderboard tab
            let token = PerformanceLogger.shared.start(label: "Leaderboard", category: .screenLoad)
            DispatchQueue.main.async {
                PerformanceLogger.shared.stop(token: token)
            }
        }
    }
    
    @ViewBuilder
    private var insightsContent: some View {
        // Personal Insights screen - for logged-in user only
        PersonalInsightsView(
            athleteProfile: athleteProfile,
            allStats: stats,
            allActivities: activities
        )
        .padding(.horizontal, -Spacing.md)
        .onAppear {
            // CHANGE 5: Track screen load for Insights tab
            let token = PerformanceLogger.shared.start(label: "Insights", category: .screenLoad)
            DispatchQueue.main.async {
                PerformanceLogger.shared.stop(token: token)
            }
        }
    }
    
    @ViewBuilder
    private var analysisContent: some View {
        if stats.isEmpty {
            EmptyStateView(
                icon: "chart.xyaxis.line",
                title: "No Analysis Available",
                message: "Your performance data will appear here once you log activities"
            )
            .padding(.horizontal, Spacing.md)
        } else {
            VStack(spacing: 0) {
                // Rider chip selector — fixed above scroll, not part of scroll content
                RiderChipSelector(
                    stats: stats,
                    selectedRiderName: $analysisViewModel.selectedRiderName,
                    viewModel: analysisViewModel
                )

                // Full analysis content scrolls independently per rider
                if let selectedRider = analysisViewModel.selectedRider {
                    ScrollView {
                        RiderAnalysisView(
                            rider: selectedRider,
                            allStats: stats,
                            activities: activities
                        )
                        .padding(.horizontal, -Spacing.md)
                        .id(selectedRider.id) // Force recreation on rider change
                    }
                }
            }
            .onAppear {
                // Seed view model and default to logged-in user
                analysisViewModel.stats = stats
                if analysisViewModel.selectedRiderName == nil {
                    analysisViewModel.selectedRiderName = myStats?.memberName ?? stats.first?.memberName
                }
                let token = PerformanceLogger.shared.start(label: "Analysis", category: .screenLoad)
                DispatchQueue.main.async {
                    PerformanceLogger.shared.stop(token: token)
                }
            }
            .onChange(of: stats) { _, newStats in
                analysisViewModel.stats = newStats
            }
        }
    }
    
    // MARK: - Logged-in User Stats Helper
    
    private var myStats: MemberStats? {
        // Normalize names for robust matching (same logic as PersonalInsightsView)
        let firstName = athleteProfile.firstname.lowercased().trimmingCharacters(in: .whitespaces)
        let lastName = athleteProfile.lastname.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Try exact match first (firstname + lastname in memberName)
        if let exactMatch = stats.first(where: { stat in
            let name = stat.memberName.lowercased().trimmingCharacters(in: .whitespaces)
            return name.contains(firstName) && name.contains(lastName)
        }) {
            return exactMatch
        }
        
        // Fallback: Try matching just lastname (more reliable)
        if let lastNameMatch = stats.first(where: { stat in
            let name = stat.memberName.lowercased().trimmingCharacters(in: .whitespaces)
            return name.contains(lastName) && lastName.count >= 3  // Avoid false positives on short names
        }) {
            return lastNameMatch
        }
        
        // Final fallback: Return first stat
        return stats.first
    }
    
    private var podiumSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Top Performers")
                .font(.sectionTitle)
                .fontWeight(.bold)
                .foregroundStyle(Color.textPrimary)
            
            if stats.count >= 3 {
                let topThree = Array(stats.sorted { $0.totalKM > $1.totalKM }.prefix(3))
                
                // Podium layout - uses ScrollView for horizontal overflow if needed
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        RiderPodiumCard(rank: 2, rider: topThree[1], isCompact: false)
                            .offset(y: Spacing.md)
                        
                        RiderPodiumCard(rank: 1, rider: topThree[0], isCompact: false)
                        
                        RiderPodiumCard(rank: 3, rider: topThree[2], isCompact: false)
                            .offset(y: Spacing.md)
                    }
                    .padding(.horizontal, 1) // Prevent edge clipping
                }
            } else {
                EmptyStateView(
                    icon: "figure.outdoor.cycle",
                    title: "No riders yet",
                    message: "Check back after some activities are logged this week"
                )
                .frame(height: 200)
            }
        }
    }
    
    private var performanceHighlight: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Best Ride of the Week")
                .font(.sectionTitle)
                .fontWeight(.bold)
                .foregroundStyle(Color.textPrimary)
            
            if let bestRide = activities.max(by: { $0.distance < $1.distance }) {
                BestRideCard(activity: bestRide)
            } else {
                EmptyStateView(
                    icon: "bicycle",
                    title: "No rides yet",
                    message: "The week's best ride will appear here"
                )
                .frame(height: 150)
            }
        }
    }
    
    private var profileButton: some View {
        Menu {
            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                    showPerformanceDashboard = true
                }
            } label: {
                Label("Performance Stats", systemImage: "chart.bar.fill")
            }
            
            Divider()

            Button {
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
            } label: {
                Label("Copy Token for Apple TV", systemImage: "appletv")
            }

            Divider()
            
            Button(role: .destructive) {
                // Logout for testing different accounts
                StravaAPI.shared.logout()
                
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            } label: {
                Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 38, height: 38)
                
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.35), .white.opacity(0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .frame(width: 38, height: 38)
                
                Circle()
                    .fill(.clear)
                    .frame(width: 38, height: 38)
                    .shadow(color: Color.accent.opacity(0.5), radius: 8)
                
                Text(userInitial)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }
}

// MARK: - Original Full Dashboard (kept for reference/future use - can access via TabView if needed)

struct OriginalWeeklyDashboardView: View {
    @State private var stravaAPI = StravaAPI.shared
    @State private var stats: [MemberStats] = []
    @State private var activities: [Activity] = []
    @State private var athleteProfile: AthleteProfile?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTab = 0
    @State private var dateRange: (start: Date, end: Date)?

    var body: some View {
        TabView(selection: $selectedTab) {

            // ── Charts tab ──────────────────────────────────────────────
            NavigationStack {
                contentView
                    .navigationTitle("Weekly Activities")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { refreshButton }
            }
            .tabItem { Label("Charts", systemImage: "chart.bar.fill") }
            .tag(0)

            // ── Table tab ───────────────────────────────────────────────
            NavigationStack {
                MemberStatsTableView(stats: stats)
                    .navigationTitle("Rankings")
                    .toolbar { refreshButton }
            }
            .tabItem { Label("Table", systemImage: "list.number") }
            .tag(1)

            // ── Activities tab ──────────────────────────────────────────
            NavigationStack {
                activitiesListView
                    .navigationTitle("Activities")
            }
            .tabItem { Label("Activities", systemImage: "figure.run") }
            .tag(2)

        }
        .task { await loadData() }
    }

    // MARK: Content helpers

    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            GlassLoadingView(message: "Fetching club activities…")
        } else if let error = errorMessage {
            GlassErrorView(
                error: error,
                isAuthError: false,
                onRetry:    { Task { await loadData() } },
                onLogInAgain: {
                    StravaAPI.shared.logout()
                }
            )
        } else if let profile = athleteProfile {
            MemberStatsChartView(
                stats: stats, 
                dateRange: dateRange,
                athleteProfile: profile,
                activities: activities
            )
        }
    }

    @ViewBuilder
    private var activitiesListView: some View {
        if activities.isEmpty {
            GlassErrorView(
                error: "No activities found this week",
                isAuthError: false,
                onRetry: { Task { await loadData() } },
                onLogInAgain: {}
            )
        } else {
            List(activities) { activity in
                NavigationLink {
                    ActivityDetailView(activity: activity, allActivities: activities)
                } label: {
                    ActivityRow(activity: activity)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .listStyle(.plain)
        }
    }

    private var refreshButton: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                Task { await loadData() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(isLoading)
        }
    }

    // MARK: Data loading

    private func loadData() async {
        // Only fetch athlete profile on first load
        guard athleteProfile == nil else {
            // Profile already loaded, just fetch activities
            await loadClubActivitiesOriginal()
            return
        }
        
        isLoading    = true
        errorMessage = nil

        do {
            // First, fetch the authenticated athlete's profile
            athleteProfile = try await stravaAPI.fetchAuthenticatedAthlete()
            
            // Then fetch club activities
            await loadClubActivitiesOriginal()
        } catch StravaError.notAuthenticated, StravaError.tokenExpired {
            BiometricAuth.shared.lock()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
    
    private func loadClubActivitiesOriginal() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetched = try await stravaAPI.fetchLastWeeksClubActivities()
            activities  = fetched.sorted { $0.date > $1.date }
            stats       = buildMemberStats(from: fetched)
            
            // Calculate date range AFTER API call using the same logic the API used
            let interval = stravaAPI.isShowingExtendedRange 
                ? DateRangeProvider.getExtendedWeekRange()
                : DateRangeProvider.getCurrentWeek()
            dateRange = (start: interval.start, end: interval.end)
        } catch StravaError.notAuthenticated, StravaError.tokenExpired {
            BiometricAuth.shared.lock()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Build Member Stats (FIXED — No Occurrence Split) - Original View
    
    private func buildMemberStats(from activities: [Activity]) -> [MemberStats] {
        #if DEBUG
        print("[BuildStats-Original] Total activities received: \(activities.count)")
        #endif
        
        // Use ALL activities for current week (no occurrence split)
        let currentGrouped = Dictionary(grouping: activities, by: \.memberName)
        #if DEBUG
        print("[BuildStats-Original] Current week: \(currentGrouped.count) unique members")
        #endif
        
        // Cache lookup for previous week
        let cacheLookup = WeeklyCache.previousWeekLookup()
        
        let stats = currentGrouped.map { name, currentActs -> MemberStats in
            let previousActs: [Activity]
            
            if let cached = cacheLookup[name] {
                // Use cache data
                let syntheticActivity = Activity(
                    memberName: name,
                    activityName: "Previous Week Total",
                    distance: cached.weekKM,
                    date: Date().addingTimeInterval(-7 * 24 * 3600),
                    averageSpeed: cached.avgSpeed,
                    elevationGain: cached.elevation,
                    movingTime: 0,
                    type: "Summary"
                )
                previousActs = [syntheticActivity]
            } else {
                previousActs = []
            }
            
            return MemberStats(
                memberName: name,
                activities: currentActs,
                previousWeekActivities: previousActs
            )
        }
        .sorted { $0.totalKM > $1.totalKM }
        
        WeeklyCache.save(stats)
        #if DEBUG
        print("[BuildStats-Original] ✅ Returning \(stats.count) member stats")
        #endif
        return stats
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let activity: Activity

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()
    
    var body: some View {
        HStack(spacing: 12) {
            // Activity icon
            Image(systemName: activityIcon)
                .font(.title2)
                .foregroundStyle(Color.dccGreen)
                .frame(width: 40, height: 40)
                .background(Color.dccGreen.opacity(0.1))
                .clipShape(Circle())
            
            // Activity details
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.activityName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(activity.memberName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Distance and date
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f km", activity.distance))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.dccSaffron)
                
                Text(Self.dateFormatter.string(from: activity.date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var activityIcon: String {
        switch activity.type.lowercased() {
        case "ride":
            return "bicycle"
        case "run":
            return "figure.outdoor.cycle"
        case "walk":
            return "figure.outdoor.cycle"
        case "swim":
            return "figure.outdoor.cycle"
        default:
            return "figure.outdoor.cycle"
        }
    }
}

// MARK: - Activity Detail View

struct ActivityDetailView: View {
    let activity: Activity
    let allActivities: [Activity]
    
    @State private var historicalActivities: [Activity] = []
    @State private var isLoadingHistory = false
    
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .short
        return f
    }()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header card
                headerCard
                
                // Stats grid
                statsGrid
                
                // Performance trend card (NEW)
                performanceTrendCard
                
                // Member comparison
                memberComparisonCard
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [Color.dccBlue.opacity(0.15), Color.dccSaffron.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle(activity.activityName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadHistoricalData()
        }
    }
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: activityIcon)
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.dccGreen, Color.dccSaffron],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Spacer()
            }
            
            Text(activity.activityName)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                Label(activity.memberName, systemImage: "person.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(Self.dateFormatter.string(from: activity.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .glassEffect(
            .regular.tint(Color.dccGreen.opacity(0.1)),
            in: .rect(cornerRadius: 16)
        )
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            statCard(
                title: "Distance",
                value: String(format: "%.2f km", activity.distance),
                icon: "arrow.left.and.right",
                color: Color.dccSaffron
            )
            
            statCard(
                title: "Avg Speed",
                value: String(format: "%.1f km/h", activity.averageSpeed),
                icon: "speedometer",
                color: Color.dccGreen
            )
            
            statCard(
                title: "Elevation",
                value: String(format: "%.0f m", activity.elevationGain),
                icon: "mountain.2.fill",
                color: Color.dccBlue
            )
            
            statCard(
                title: "Duration",
                value: formatDuration(activity.movingTime),
                icon: "clock.fill",
                color: Color.dccSaffron
            )
        }
    }
    
    // MARK: Performance Trend Card
    
    private var performanceTrendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Performance Trend")
                    .font(.headline)
                
                Spacer()
                
                if isLoadingHistory {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal)
            
            if !historicalActivities.isEmpty {
                let weeklyData = calculateWeeklyPerformance()
                
                if !weeklyData.isEmpty {
                    VStack(spacing: 12) {
                        // Chart
                        Chart(weeklyData) { data in
                            BarMark(
                                x: .value("Week", data.weekLabel),
                                y: .value("Distance", data.totalDistance)
                            )
                            .foregroundStyle(data.isCurrentWeek ? Color.dccSaffron : Color.dccBlue.opacity(0.7))
                            .annotation(position: .top) {
                                Text(String(format: "%.0f", data.totalDistance))
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                        
                        // Performance summary
                        performanceSummary(weeklyData: weeklyData)
                    }
                } else {
                    Text("Not enough data to show trend")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                }
            } else if !isLoadingHistory {
                Text("No historical data available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
        .glassEffect(
            .regular.tint(.white.opacity(0.05)),
            in: .rect(cornerRadius: 16)
        )
    }
    
    private func performanceSummary(weeklyData: [WeeklyPerformance]) -> some View {
        VStack(spacing: 8) {
            if weeklyData.count >= 2 {
                let currentWeek = weeklyData.first(where: { $0.isCurrentWeek })
                let previousWeeks = weeklyData.filter { !$0.isCurrentWeek }
                let avgPrevious = previousWeeks.reduce(0.0) { $0 + $1.totalDistance } / Double(previousWeeks.count)
                
                if let current = currentWeek {
                    let change = current.totalDistance - avgPrevious
                    let percentChange = (change / avgPrevious) * 100
                    
                    HStack {
                        Image(systemName: change >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundStyle(change >= 0 ? Color.green : Color.red)
                        
                        Text(String(format: "%.1f%% %@ vs previous weeks", abs(percentChange), change >= 0 ? "increase" : "decrease"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Week")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.1f km", current.totalDistance))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.dccSaffron)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Avg Previous")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.1f km", avgPrevious))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.dccBlue)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: Helper Structures and Methods
    
    private struct WeeklyPerformance: Identifiable {
        let id = UUID()
        let weekLabel: String
        let totalDistance: Double
        let isCurrentWeek: Bool
    }
    
    private func calculateWeeklyPerformance() -> [WeeklyPerformance] {
        let calendar = Calendar.current
        let memberActivities = historicalActivities.filter { $0.memberName == activity.memberName }
        
        // Group by week
        var weeklyGroups: [Int: [Activity]] = [:]
        let now = Date()
        
        for activity in memberActivities {
            let weeksDiff = calendar.dateComponents([.weekOfYear], from: activity.date, to: now).weekOfYear ?? 0
            weeklyGroups[weeksDiff, default: []].append(activity)
        }
        
        // Create performance data for last 3 weeks
        var results: [WeeklyPerformance] = []
        
        for week in 0..<3 {
            if let activities = weeklyGroups[week] {
                let total = activities.reduce(0.0) { $0 + $1.distance }
                let label = week == 0 ? "This Week" : "\(week)w ago"
                results.append(WeeklyPerformance(
                    weekLabel: label,
                    totalDistance: total,
                    isCurrentWeek: week == 0
                ))
            }
        }
        
        return results.sorted { $0.weekLabel > $1.weekLabel }
    }
    
    private func loadHistoricalData() async {
        isLoadingHistory = true
        defer { isLoadingHistory = false }
        
        do {
            // Fetch last 3 weeks of activities
            historicalActivities = try await StravaAPI.shared.fetchClubActivities(weeksBack: 3)
        } catch {
            #if DEBUG
            print("❌ Failed to load historical activities: \(error)")
            #endif
            historicalActivities = []
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(
            .regular.tint(color.opacity(0.1)),
            in: .rect(cornerRadius: 12)
        )
    }
    
    private var memberComparisonCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Member's Activity This Week")
                .font(.headline)
                .padding(.horizontal)
            
            let memberActivities = allActivities.filter { $0.memberName == activity.memberName }
            
            if memberActivities.count > 1 {
                VStack(spacing: 12) {
                    comparisonRow(
                        title: "Total Activities",
                        value: "\(memberActivities.count)"
                    )
                    
                    comparisonRow(
                        title: "Total Distance",
                        value: String(format: "%.1f km", memberActivities.reduce(0.0) { $0 + $1.distance })
                    )
                    
                    comparisonRow(
                        title: "Avg Speed (All)",
                        value: String(format: "%.1f km/h", memberActivities.reduce(0.0) { $0 + $1.averageSpeed } / Double(memberActivities.count))
                    )
                }
                .padding()
            } else {
                Text("This is the member's only activity this week")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
        .glassEffect(
            .regular.tint(.white.opacity(0.05)),
            in: .rect(cornerRadius: 16)
        )
    }
    
    private func comparisonRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.dccSaffron)
        }
    }
    
    private var activityIcon: String {
        switch activity.type.lowercased() {
        case "ride":
            return "bicycle"
        case "run":
            return "figure.outdoor.cycle"
        case "walk":
            return "figure.outdoor.cycle"
        case "swim":
            return "figure.outdoor.cycle"
        default:
            return "figure.outdoor.cycle"
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
}


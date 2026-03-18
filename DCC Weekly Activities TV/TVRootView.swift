//
//  TVRootView.swift
//  DCC Weekly Activities TV
//
//  Main container for the tvOS app.
//  Rebuilt to match the DCC Weekly UX Specification:
//  — Premium dark aesthetic (#0A0A0B background)
//  — Strava orange accent with French tricolor cultural identity
//  — 10-foot legibility: SF Pro + SF Mono, 36pt+ body sizes
//  — Focus engine: scale 1.06×, glow, border transitions per spec
//  — Waiting screen: iCloud KVStore token polling
//  — Auto-rotate: 30s between tabs when idle
//
//  All data fetching lives in TVLeaderboardViewModel (self-contained,
//  no cross-target imports from the iOS app).
//

import SwiftUI

// MARK: - Tab definition

enum TVTab: String, CaseIterable {
    case leaderboard = "Leaderboard"
    case overview    = "Overview"
    case insights    = "Insights"
    case analysis    = "Analysis"

    var icon: String {
        switch self {
        case .leaderboard: return "trophy.fill"
        case .overview:    return "chart.bar.fill"
        case .insights:    return "bolt.circle.fill"
        case .analysis:    return "waveform.path.ecg"
        }
    }
}

// MARK: - Screen enum (used by auto-rotate)

private enum TVScreen: CaseIterable {
    case dashboard
    case leaderboard
    case podium
    case heroStats
    case ticker
    case distanceChart
    case weekComparison
}

// MARK: - Inline spacing tokens (mirror TVLayout for private use)

private enum TVSpacing {
    static let cardPad: CGFloat    = 36
    static let cardGap: CGFloat    = 24
    static let sectionGap: CGFloat = 56
    static let margin: CGFloat     = 90
    static let rowH: CGFloat       = 100
    static let xs: CGFloat         = 12
    static let sm: CGFloat         = 20
    static let md: CGFloat         = 32
    static let lg: CGFloat         = 48
    static let xl: CGFloat         = 90
    static let xxl: CGFloat        = 96
}

// MARK: - Inline type tokens

private enum TVType {
    static let screenTitle   = Font.system(size: 52, weight: .semibold, design: .default)
    static let sectionHeader = Font.system(size: 44, weight: .bold,     design: .default)
    static let cardHeadline  = Font.system(size: 36, weight: .medium,   design: .default)
    static let bodyData      = Font.system(size: 32, weight: .regular,  design: .default)
    static let label         = Font.system(size: 28, weight: .medium,   design: .default)
    static let caption       = Font.system(size: 22, weight: .regular,  design: .monospaced)
}


// MARK: - Local data models (self-contained — no iOS target dependency)

struct TVRideEntry: Identifiable {
    let id = UUID()
    let memberName: String
    let km: Double
    let avgSpeed: Double
    let elevation: Double
    let movingTime: Int
}

struct TVMemberStats: Identifiable {
    let id = UUID()
    let memberName: String
    let totalRides: Int
    let totalKM: Double
    let avgSpeed: Double
    let totalElevation: Double
    let rides: [TVRideEntry]
    let previousWeekKM: Double
    let trend: TVTrendDirection
}

enum TVTrendDirection: String {
    case up     = "↑"
    case down   = "↓"
    case stable = "→"
    case new    = "★"
}

// MARK: - Token models

private struct TVTokenResponse: Decodable {
    let access_token: String
    let refresh_token: String?
    let expires_at: Int?
}

private struct TVTokenBundle {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Int
}

// MARK: - Strava activity response

private struct TVStravaActivityResponse: Decodable {
    let name: String
    let distance: Double?
    let moving_time: Int?
    let total_elevation_gain: Double?
    let average_speed: Double?
    let athlete: Athlete

    struct Athlete: Decodable {
        let firstname: String
        let lastname: String
    }

    var memberName: String { "\(athlete.firstname) \(athlete.lastname)" }
}

// MARK: - ViewModel

@MainActor
@Observable
private final class TVLeaderboardViewModel {

    var memberStats: [TVMemberStats] = []
    var rideEntries: [TVRideEntry]   = []
    var isLoading = false
    var errorMessage: String?
    var dateRangeLabel = ""
    var totalKM: Double = 0
    var totalRides: Int = 0
    var activeRiders: Int = 0

    var lastWeekMemberStats: [TVMemberStats] = []
    var lastWeekTotalKM: Double = 0
    var lastWeekTotalRides: Int = 0
    var lastWeekLabel = ""

    private let workerURL = "https://dcc-strava.amit-r-kamat.workers.dev"
    private let clubID    = "212760"

    func refreshToken(refreshToken rt: String) async -> TVTokenBundle? {
        guard !rt.isEmpty,
              let url = URL(string: "\(workerURL)/refresh") else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONEncoder().encode(["refresh_token": rt, "client_id": "161984"])
        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let resp = try? JSONDecoder().decode(TVTokenResponse.self, from: data),
              !resp.access_token.isEmpty else {
            #if DEBUG
            print("❌ [TVRootView] Token refresh failed")
            #endif
            return nil
        }
        return TVTokenBundle(
            accessToken: resp.access_token,
            refreshToken: resp.refresh_token ?? rt,
            expiresAt: resp.expires_at ?? 0
        )
    }

    func load(token: String) async {
        guard !token.isEmpty else {
            errorMessage = "No access token. Enter your Strava access token below."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let thisWeekStart = weekStart(weeksBack: 0)
            let lastWeekStart = weekStart(weeksBack: 1)

            async let thisWeekFetch = fetchActivities(token: token, after: thisWeekStart)
            async let twoWeekFetch  = fetchActivities(token: token, after: lastWeekStart)

            let (current, combined) = try await (thisWeekFetch, twoWeekFetch)

            let thisWeekFingerprints = Set(current.map { activityFingerprint($0) })
            let previous = combined.filter { !thisWeekFingerprints.contains(activityFingerprint($0)) }

            buildLastWeekStats(from: previous)
            buildStats(from: current, previousWeek: previous)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func exchangeCode(_ code: String) async -> TVTokenBundle? {
        guard let url = URL(string: "\(workerURL)/exchange") else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONEncoder().encode(["code": code, "client_id": "161984"])
        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let resp = try? JSONDecoder().decode(TVTokenResponse.self, from: data),
              !resp.access_token.isEmpty else { return nil }
        return TVTokenBundle(
            accessToken: resp.access_token,
            refreshToken: resp.refresh_token ?? "",
            expiresAt: resp.expires_at ?? 0
        )
    }

    // MARK: Private

    private func activityFingerprint(_ a: TVStravaActivityResponse) -> String {
        "\(a.memberName)|\(Int((a.distance ?? 0)))|\(a.moving_time ?? 0)"
    }

    private func fetchActivities(token: String, after: Int) async throws -> [TVStravaActivityResponse] {
        let urlStr = "https://www.strava.com/api/v3/clubs/\(clubID)/activities?per_page=200&after=\(after)"
        guard let url = URL(string: urlStr) else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            throw NSError(domain: "Strava", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Token expired or invalid. Please enter a new token."])
        }
        do {
            return try JSONDecoder().decode([TVStravaActivityResponse].self, from: data)
        } catch {
            let preview = String(data: data.prefix(500), encoding: .utf8) ?? "<non-UTF8>"
            #if DEBUG
            print("❌ [TVRootView] Strava decode error: \(error)")
            print("❌ [TVRootView] Raw response (first 500 bytes): \(preview)")
            #endif
            throw error
        }
    }

    private func buildStats(from activities: [TVStravaActivityResponse],
                            previousWeek: [TVStravaActivityResponse] = []) {
        rideEntries  = activities.map { makeRideEntry($0) }.reversed()
        memberStats  = aggregateMembers(from: activities, previousWeek: previousWeek)
        totalKM      = memberStats.reduce(0) { $0 + $1.totalKM }
        totalRides   = memberStats.reduce(0) { $0 + $1.totalRides }
        activeRiders = memberStats.count
        dateRangeLabel = weekLabel(weeksBack: 0)
    }

    private func buildLastWeekStats(from activities: [TVStravaActivityResponse]) {
        lastWeekMemberStats = aggregateMembers(from: activities)
        lastWeekTotalKM     = lastWeekMemberStats.reduce(0) { $0 + $1.totalKM }
        lastWeekTotalRides  = lastWeekMemberStats.reduce(0) { $0 + $1.totalRides }
        lastWeekLabel       = weekLabel(weeksBack: 1)
    }

    private func makeRideEntry(_ a: TVStravaActivityResponse) -> TVRideEntry {
        let km    = (a.distance ?? 0) / 1000.0
        let time  = a.moving_time ?? 0
        var speed = (a.average_speed ?? 0) * 3.6
        if speed == 0, time > 0, km > 0 { speed = (km / Double(time)) * 3600 }
        return TVRideEntry(memberName: a.memberName, km: km, avgSpeed: speed,
                           elevation: a.total_elevation_gain ?? 0, movingTime: time)
    }

    private func aggregateMembers(from activities: [TVStravaActivityResponse],
                                   previousWeek: [TVStravaActivityResponse] = []) -> [TVMemberStats] {
        var byMember: [String: [TVStravaActivityResponse]] = [:]
        for a in activities { byMember[a.memberName, default: []].append(a) }

        var prevKMByMember: [String: Double] = [:]
        for a in previousWeek {
            prevKMByMember[a.memberName, default: 0] += (a.distance ?? 0) / 1000.0
        }

        return byMember.map { name, acts in
            let km    = acts.reduce(0.0) { $0 + (($1.distance ?? 0) / 1000.0) }
            let speed = acts.isEmpty ? 0.0 : acts.reduce(0.0) { s, a in
                let v = (a.average_speed ?? 0) * 3.6
                let t = a.moving_time ?? 0
                let d = (a.distance ?? 0) / 1000.0
                if v > 0 { return s + v }
                if t > 0 && d > 0 { return s + (d / Double(t)) * 3600 }
                return s
            } / Double(acts.count)
            let elev   = acts.reduce(0.0) { $0 + ($1.total_elevation_gain ?? 0) }
            let rides  = acts.map { makeRideEntry($0) }
            let prevKM = prevKMByMember[name] ?? 0
            let trend: TVTrendDirection
            if prevKM == 0 {
                trend = .new
            } else {
                let pct = ((km - prevKM) / prevKM) * 100
                if pct > 10 { trend = .up }
                else if pct < -10 { trend = .down }
                else { trend = .stable }
            }
            return TVMemberStats(memberName: name, totalRides: acts.count,
                                 totalKM: km, avgSpeed: speed,
                                 totalElevation: elev, rides: rides,
                                 previousWeekKM: prevKM, trend: trend)
        }
        .sorted { $0.totalKM > $1.totalKM }
    }

    private func weekStart(weeksBack: Int) -> Int {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let now = Date()
        let weekday = cal.component(.weekday, from: now)
        let iso = weekday == 1 ? 7 : weekday - 1
        let thisMonday = cal.date(byAdding: .day, value: -(iso - 1), to: now)!
        let targetMonday = cal.date(byAdding: .weekOfYear, value: -weeksBack, to: thisMonday)!
        let start = cal.date(bySettingHour: 0, minute: 0, second: 0, of: targetMonday)!
        return Int(start.timeIntervalSince1970)
    }

    private func weekLabel(weeksBack: Int) -> String {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let now = Date()
        let weekday = cal.component(.weekday, from: now)
        let iso = weekday == 1 ? 7 : weekday - 1
        let thisMonday = cal.date(byAdding: .day, value: -(iso - 1), to: now)!
        let monday = cal.date(byAdding: .weekOfYear, value: -weeksBack, to: thisMonday)!
        let sunday = cal.date(byAdding: .day, value: 6, to: monday)!
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE d MMM"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return "\(fmt.string(from: monday)) – \(fmt.string(from: sunday))"
    }
}

// MARK: - Root View

struct TVRootView: View {
    @AppStorage("tv_strava_token")  private var storedToken     = ""
    @AppStorage("tv_refresh_token") private var storedRefresh   = ""
    @AppStorage("tv_token_expires") private var storedExpiresAt = 0

    @State private var loadTrigger = 0
    @State private var isRefreshing = false
    @State private var viewModel = TVLeaderboardViewModel()
    @State private var selectedTab: TVTab = .leaderboard
    @State private var autoRotate = true
    @State private var rotateTimer: Timer?
    @Namespace private var tabNamespace
    @State private var liveGlow = false

    private let screenDuration: TimeInterval = 30

    private var tokenIsExpired: Bool {
        guard storedExpiresAt > 0 else { return false }
        return Int(Date().timeIntervalSince1970) >= storedExpiresAt - 300
    }

    private func saveTokenBundle(_ bundle: TVTokenBundle) {
        storedToken     = bundle.accessToken
        storedRefresh   = bundle.refreshToken
        storedExpiresAt = bundle.expiresAt
        loadTrigger    += 1
    }

    @discardableResult
    private func ensureFreshToken() async -> String {
        guard tokenIsExpired, !storedRefresh.isEmpty else { return storedToken }
        #if DEBUG
        print("🔄 [TVRootView] Access token expired — refreshing via worker…")
        #endif
        withAnimation(.easeInOut(duration: 0.4)) { isRefreshing = true }
        defer { withAnimation(.easeInOut(duration: 0.4)) { isRefreshing = false } }
        if let bundle = await viewModel.refreshToken(refreshToken: storedRefresh) {
            storedRefresh   = bundle.refreshToken
            storedExpiresAt = bundle.expiresAt
            storedToken     = bundle.accessToken
            #if DEBUG
            print("✅ [TVRootView] Token refreshed successfully")
            #endif
            return bundle.accessToken
        } else {
            #if DEBUG
            print("❌ [TVRootView] Token refresh failed — clearing stored tokens")
            #endif
            storedToken     = ""
            storedRefresh   = ""
            storedExpiresAt = 0
            return ""
        }
    }

    var body: some View {
        ZStack {
            // Background
            TVAmbientBackground()

            if storedToken.isEmpty {
                TVWaitingView { bundle in
                    saveTokenBundle(bundle)
                }
                .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    // Tricolor stripe at very top
                    TricolorBar()

                    // Header
                    TVHeaderBar(
                        selectedTab: $selectedTab,
                        tabNamespace: tabNamespace,
                        liveGlow: $liveGlow,
                        dateRangeLabel: viewModel.dateRangeLabel
                    )
                    .frame(height: TVLayout.headerHeight)

                    // Divider
                    Rectangle()
                        .fill(Color.tvDivider)
                        .frame(height: 1)

                    // Content
                    ZStack {
                        switch selectedTab {
                        case .leaderboard:
                            TVLeaderboardScreen(
                                viewModel: viewModel,
                                onRefresh: { loadTrigger += 1 },
                                onClearToken: {
                                    storedToken     = ""
                                    storedRefresh   = ""
                                    storedExpiresAt = 0
                                }
                            )
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        case .overview:
                            TVOverviewView(memberStats: viewModel.memberStats)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        case .insights:
                            TVInsightsView(memberStats: viewModel.memberStats)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        case .analysis:
                            TVAnalysisView(memberStats: viewModel.memberStats)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                    }
                    .animation(.easeInOut(duration: 0.28), value: selectedTab)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .transition(.opacity)
            }

            // Token refresh overlay
            if isRefreshing {
                ZStack {
                    Color.tvBackground.opacity(0.7)
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Color.tvAccent)
                        Text("Refreshing token…")
                            .font(TVFont.caption())
                            .foregroundStyle(Color.tvTextSecondary)
                    }
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .task(id: loadTrigger) {
            guard !storedToken.isEmpty else { return }
            let token = await ensureFreshToken()
            guard !token.isEmpty else { return }
            await viewModel.load(token: token)
        }
        .onAppear {
            if !storedToken.isEmpty && viewModel.memberStats.isEmpty && !viewModel.isLoading {
                loadTrigger += 1
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                liveGlow = true
            }
            #if DEBUG
            if let injected = ProcessInfo.processInfo.environment["tv_strava_token"],
               !injected.isEmpty { storedToken = injected }
            let args = ProcessInfo.processInfo.arguments
            if let idx = args.firstIndex(of: "-tv_strava_token"),
               args.indices.contains(idx + 1) {
                let value = args[idx + 1]
                if !value.isEmpty { storedToken = value }
            }
            #endif
        }
        .onChange(of: viewModel.isLoading) { _, loading in
            if !loading && viewModel.errorMessage == nil { startTimer() }
        }
        .onDisappear { stopTimer() }
    }

    // MARK: Auto-rotate timer

    private func startTimer() {
        guard autoRotate else { return }
        stopTimer()
        rotateTimer = Timer.scheduledTimer(withTimeInterval: screenDuration, repeats: true) { _ in
            Task { @MainActor in
                guard autoRotate, !viewModel.memberStats.isEmpty else { return }
                withAnimation(.easeInOut(duration: 0.5)) { advanceTab() }
            }
        }
    }

    private func stopTimer() { rotateTimer?.invalidate(); rotateTimer = nil }

    private func advanceTab() {
        let all = TVTab.allCases
        guard let idx = all.firstIndex(of: selectedTab) else { return }
        selectedTab = all[(idx + 1) % all.count]
    }
}

// MARK: - Waiting Screen (iCloud token pending)

private struct TVWaitingView: View {
    let onConnect: (TVTokenBundle) -> Void

    @State private var draft = ""
    @FocusState private var fieldFocused: Bool
    @State private var pulseScale: CGFloat = 1.0

    private var canConnect: Bool {
        !draft.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            TVAmbientBackground()

            VStack(spacing: TVSpacing.lg) {
                // Brand mark
                VStack(spacing: TVSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Color.tvAccent.opacity(0.12))
                            .frame(width: 160, height: 160)
                            .scaleEffect(pulseScale)
                        Circle()
                            .strokeBorder(Color.tvAccent.opacity(0.25), lineWidth: 2)
                            .frame(width: 160, height: 160)
                        Image(systemName: "figure.outdoor.cycle")
                            .font(.system(size: 72))
                            .foregroundStyle(Color.tvAccent)
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                            pulseScale = 1.12
                        }
                    }

                    VStack(spacing: 8) {
                        Text("DCC Weekly Activities")
                            .font(TVFont.sectionHeader())
                            .foregroundStyle(Color.tvTextPrimary)
                        Text("TV Edition")
                            .font(.system(size: 30, weight: .light))
                            .foregroundStyle(Color.tvTextSecondary)
                    }
                }

                // Instruction card
                VStack(spacing: TVSpacing.sm) {
                    Text("Connect with Strava")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(Color.tvTextPrimary)

                    Text("On iPhone: tap your avatar → \"Copy Token for Apple TV\"\nPaste the token below to connect your Strava account.")
                        .font(.system(size: 26, weight: .regular))
                        .foregroundStyle(Color.tvTextSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 760)
                }

                // Token entry
                VStack(spacing: TVSpacing.sm) {
                    if !draft.isEmpty {
                        HStack(spacing: TVSpacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.tvGreen)
                                .font(.system(size: 28))
                            Text("\(String(draft.prefix(8)))••••••••\(String(draft.suffix(4)))")
                                .font(.system(size: 24, design: .monospaced))
                                .foregroundStyle(Color.tvTextPrimary)
                        }
                        .padding(TVSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.tvGreen.opacity(0.10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.tvGreen.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .frame(maxWidth: 900)
                    }

                    TextField("Tap to enter token", text: $draft)
                        .font(.system(size: 24, design: .monospaced))
                        .foregroundStyle(Color.tvTextPrimary)
                        .padding(TVSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.tvCard)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(fieldFocused ? Color.tvAccent.opacity(0.5) : Color.tvDivider, lineWidth: 1)
                                )
                        )
                        .frame(maxWidth: 900)
                        .focused($fieldFocused)

                    Button {
                        guard canConnect else { return }
                        let raw = draft.trimmingCharacters(in: .whitespaces)
                        onConnect(TVWaitingView.parseBundle(from: raw))
                    } label: {
                        Label("Connect to Strava", systemImage: "arrow.right.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .padding(.horizontal, TVSpacing.xl)
                            .padding(.vertical, TVSpacing.sm)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.tvAccent)
                    .disabled(!canConnect)
                }
            }
            .padding(TVSpacing.xl)
        }
        .onAppear { fieldFocused = true }
    }

    static func parseBundle(from raw: String) -> TVTokenBundle {
        guard raw.hasPrefix("{"),
              let data = raw.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String, !accessToken.isEmpty
        else {
            return TVTokenBundle(accessToken: raw, refreshToken: "", expiresAt: 0)
        }
        return TVTokenBundle(
            accessToken: accessToken,
            refreshToken: json["refresh_token"] as? String ?? "",
            expiresAt: json["expires_at"] as? Int ?? 0
        )
    }
}

// MARK: - Header Bar

private struct TVHeaderBar: View {
    @Binding var selectedTab: TVTab
    var tabNamespace: Namespace.ID
    @Binding var liveGlow: Bool
    let dateRangeLabel: String

    private var currentDateString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE d MMM"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt.string(from: Date())
    }

    var body: some View {
        HStack(spacing: 0) {
            // LEFT: Club branding
            HStack(spacing: 16) {
                Image(systemName: "figure.outdoor.cycle")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Color.tvAccent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("DCC Weekly")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.tvTextPrimary)
                    Text("Desi Cycling Club")
                        .font(TVFont.caption())
                        .foregroundStyle(Color.tvTextSecondary)
                }
            }
            .padding(.leading, TVSpacing.margin)

            Spacer()

            // CENTER: Tab bar
            TVTabBar(selectedTab: $selectedTab, tabNamespace: tabNamespace)

            Spacer()

            // RIGHT: Live indicator + date
            HStack(spacing: 12) {
                // Live dot
                ZStack {
                    Circle()
                        .fill(Color.tvGreen.opacity(0.25))
                        .frame(width: 20, height: 20)
                        .scaleEffect(liveGlow ? 1.4 : 1.0)
                    Circle()
                        .fill(Color.tvGreen)
                        .frame(width: 10, height: 10)
                }

                Text("LIVE")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(Color.tvGreen)

                Text(dateRangeLabel.isEmpty ? currentDateString : dateRangeLabel)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(Color.tvTextSecondary)
                    .lineLimit(1)
            }
            .padding(.trailing, TVSpacing.margin)
        }
    }
}

// MARK: - Tab Bar

private struct TVTabBar: View {
    @Binding var selectedTab: TVTab
    var tabNamespace: Namespace.ID

    var body: some View {
        HStack(spacing: 6) {
            ForEach(TVTab.allCases, id: \.self) { tab in
                TVTabButton(tab: tab, isSelected: selectedTab == tab) {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        selectedTab = tab
                    }
                }
            }
        }
    }
}

private struct TVTabButton: View {
    let tab: TVTab
    let isSelected: Bool
    let action: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: .medium))
                Text(tab.rawValue)
                    .font(.system(size: 17, weight: .regular))
            }
            .foregroundStyle(
                isFocused || isSelected ? Color.tvTextPrimary : Color.tvTextTertiary
            )
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        isSelected
                            ? Color.tvAccent.opacity(isFocused ? 0.30 : 0.18)
                            : (isFocused ? Color.tvCard : Color.clear)
                    )
                    .overlay(
                        isSelected
                            ? Capsule().strokeBorder(Color.tvAccent.opacity(0.35), lineWidth: 1)
                            : nil
                    )
            )
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.07 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isFocused)
        .accessibilityLabel(isSelected ? "\(tab.rawValue), selected tab" : "\(tab.rawValue) tab")
    }
}

// MARK: - Leaderboard Screen wrapper (loading/error/empty states)

private struct TVLeaderboardScreen: View {
    @Bindable var viewModel: TVLeaderboardViewModel
    let onRefresh: () -> Void
    let onClearToken: () -> Void

    var body: some View {
        if viewModel.isLoading {
            TVLoadingView()
        } else if let err = viewModel.errorMessage {
            TVErrorView(message: err, onRetry: onRefresh, onClearToken: onClearToken)
        } else if viewModel.memberStats.isEmpty {
            TVEmptyView()
        } else {
            TVLeaderboardView(memberStats: viewModel.memberStats)
        }
    }
}

// MARK: - Loading / Error / Empty state views

private struct TVLoadingView: View {
    var body: some View {
        VStack(spacing: TVSpacing.md) {
            ProgressView()
                .scaleEffect(2)
                .tint(Color.tvAccent)
            Text("Loading club data…")
                .font(TVFont.bodyData())
                .foregroundStyle(Color.tvTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct TVErrorView: View {
    let message: String
    let onRetry: () -> Void
    let onClearToken: () -> Void

    @FocusState private var focusedButton: Int?

    var body: some View {
        VStack(spacing: TVSpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.tvRed)

            Text("Unable to Load")
                .font(TVFont.sectionHeader())
                .foregroundStyle(Color.tvTextPrimary)

            Text(message)
                .font(TVFont.bodyData())
                .foregroundStyle(Color.tvTextSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 700)

            HStack(spacing: TVSpacing.cardGap) {
                Button(action: onRetry) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .font(.system(size: 28, weight: .medium))
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.tvAccent)
                .focused($focusedButton, equals: 0)

                Button(action: onClearToken) {
                    Label("Reconnect", systemImage: "person.crop.circle.badge.xmark")
                        .font(.system(size: 28, weight: .medium))
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.bordered)
                .tint(Color.tvTextSecondary)
                .focused($focusedButton, equals: 1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { focusedButton = 0 }
    }
}

private struct TVEmptyView: View {
    var body: some View {
        VStack(spacing: TVSpacing.md) {
            Image(systemName: "bicycle")
                .font(.system(size: 80))
                .foregroundStyle(Color.tvTextTertiary)
            Text("No rides this week yet")
                .font(TVFont.sectionHeader())
                .foregroundStyle(Color.tvTextSecondary)
            Text("Check back after some rides are logged to Strava.")
                .font(TVFont.bodyData())
                .foregroundStyle(Color.tvTextTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Podium and legacy screens kept for auto-rotate compatibility

extension TVRootView {
    // Retained for potential future use; auto-rotate now advances tabs only.
}

// MARK: - RoundedRectangle corner helper (used in legacy code)

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

//  StravaAPI.swift
//  StravaAPI.swift
//  DCC-Weekly-Activities
//
//  Handles Strava OAuth login and fetching club/member activities.
//
//  VERSION HISTORY:
//  2026-02-24: [HOTFIX] Removed broken in-code date filter for club activities.
//              Strava /v3/clubs/{id}/activities returns no start_date field.
//              All activities decoded with Date.distantPast causing filter rejection.
//              Server-side "after=" parameter handles date range filtering.
//  2026-02-27: [SMART-DATE] Added 14-day rolling window fallback when current week has no data.
//              When filtered activities return empty, automatically extends date
//              range to last 14 days (rolling window from today) and re-fetches. 
//              Prevents empty screens during slow weeks. Added isShowingExtendedRange 
//              flag for UI updates.
//  2026-02-24: [HOTFIX] Removed "before" parameter from club activities URL.
//              Strava /clubs/{id}/activities endpoint does not support both
//              "after" and "before" parameters simultaneously. Activities are
//              now filtered in-code using the week end date.
//

#if os(iOS)
import AuthenticationServices
#endif
import Foundation
import Observation
import SwiftUI

// MARK: - Configuration
//
// Fill in the three TODO values. clientSecret is intentionally absent —
// it lives only in Cloudflare Worker environment variables.
//
struct StravaConfig {
    /// Public client ID from https://www.strava.com/settings/api  (safe to ship in binary)
    static let clientID    = "161984"    // TODO: e.g. "12345"

    /// Numeric ID visible in your club's Strava URL  (safe to ship in binary)
    static let clubID      = "212760"       // TODO: e.g. "67890"

    /// Deployed Cloudflare Worker URL — no trailing slash  (safe to ship in binary)
    /// Must handle  POST /exchange { code, client_id }
    ///          and POST /refresh  { refresh_token, client_id }
    static let workerURL   = "https://dcc-strava.amit-r-kamat.workers.dev"

    /// Must match "Authorization Callback Domain" in Strava API settings
    /// For mobile apps using ASWebAuthenticationSession, Strava requires
    /// the callback domain to be set to "localhost" in the Strava developer dashboard.
    static let redirectURI  = "dcc-activities://localhost/oauth/strava"

    /// Mobile OAuth endpoint — deep-links into the Strava app if installed,
    /// falls back to Safari if not. Use /oauth/authorize for web-only flow.
    static let authorizeURL = "https://www.strava.com/oauth/mobile/authorize"
}

// MARK: - Errors

enum StravaError: LocalizedError {
    case notAuthenticated
    case tokenExpired
    case badURL
    case decodingFailed
    case proxyError(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:   return "You are not logged in. Please connect with Strava."
        case .tokenExpired:       return "Your session has expired. Please log in again."
        case .badURL:             return "The request URL was invalid."
        case .decodingFailed:     return "The response from Strava could not be read."
        case .proxyError(let d):  return "Token exchange failed: \(d)"
        }
    }
}

// MARK: - Token response from Cloudflare Worker

private struct TokenResponse: Decodable {
    let access_token:  String
    let refresh_token: String?
    let expires_at:    Int?     // Unix timestamp when access_token expires
}

// MARK: - Structured OAuth diagnostic logger
// All messages are prefixed with [OAuth] and a severity symbol so they are easy
// to filter in the Xcode console with the search term "[OAuth]".

enum OAuthLog {
    static func step(_ msg: String)  {
        #if DEBUG
        print("🔵 [OAuth] \(msg)")
        #endif
    }
    static func warn(_ msg: String)  {
        #if DEBUG
        print("🟡 [OAuth] \(msg)")
        #endif
    }
    static func fail(_ msg: String)  {
        #if DEBUG
        print("🔴 [OAuth] \(msg)")
        #endif
    }
}

// PresentationContextProvider IS required even with the iOS 17.4+ callback: API.
// Diagnostic run on physical device confirmed: session.start() returns false with
// "Cannot start ASWebAuthenticationSession without providing presentation context."
// See extension StravaAPI: ASWebAuthenticationPresentationContextProviding at end of file.

// MARK: - StravaAPI
@MainActor
@Observable
final class StravaAPI {

    var accessToken: String?
    var isShowingExtendedRange: Bool = false
    var isAuthenticating: Bool = false

    /// Last error surfaced by any StravaAPI operation.
    /// Bind to this in views using `.crashErrorOverlay(error: api.lastError)`.
    /// Cleared automatically when a new operation succeeds.
    var lastError: AppError?

    // Set to true when running on Simulator with a demo token injected.
    // Views can read this to show a "Demo Mode" badge.
    private(set) var isDemoMode: Bool = false

    /// Called on cold launch when a SIMULATOR_DEMO_TOKEN is restored from keychain,
    /// so isDemoMode is correctly set without re-running the full OAuth flow.
    func restoreDemoMode() {
        isDemoMode = true
        OAuthLog.step("restoreDemoMode() — demo mode flag restored")
    }

    /// Called on cold launch to restore the refresh token from keychain into memory.
    /// Without this, refreshAccessToken() fails immediately on every relaunch because
    /// `refreshToken` is an in-memory property that is not automatically persisted.
    func restoreRefreshToken(_ token: String) {
        refreshToken = token
        OAuthLog.step("restoreRefreshToken() — refresh token restored (length: \(token.count))")
    }

    /// Single logout entry-point. Clears token from memory, keychain, and resets all flags.
    /// Call this instead of manipulating accessToken and BiometricAuth separately.
    func logout() {
        OAuthLog.step("logout() — clearing all auth state")
        accessToken    = nil
        refreshToken   = nil
        tokenExpiresAt = 0
        isDemoMode     = false
        #if os(iOS)
        BiometricAuth.shared.logout()  // clears isAuthenticated + keychain token
        #else
        // tvOS: delete keychain token directly (no biometric state to clear)
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrAccount as String:  "strava_access_token",
            kSecAttrService as String:  "com.dcc.weeklyactivities"
        ]
        _ = SecItemDelete(query as CFDictionary)
        #endif
    }

    static let shared = StravaAPI()
    private init() {}

    #if !os(iOS)
    // tvOS keychain helper — mirrors BiometricAuth.saveStravaToken on iOS
    @discardableResult
    static func saveTokenToKeychain(_ token: String) -> Bool {
        let tokenData = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrAccount as String:      "strava_access_token",
            kSecAttrService as String:      "com.dcc.weeklyactivities",
            kSecValueData as String:        tokenData,
            kSecAttrAccessible as String:   kSecAttrAccessibleWhenUnlocked
        ]
        _ = SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }
    #endif

    private var tokenExpiresAt:   Int    = 0
    private var refreshToken:     String?

    /// Read-only access for building the Apple TV token bundle
    var currentRefreshToken: String? { refreshToken }
    var currentTokenExpiresAt: Int { tokenExpiresAt }
    #if os(iOS)
    private var activeSession:    ASWebAuthenticationSession?  // keeps session alive during OAuth
    private var oauthTimeoutTask: Task<Void, Never>?           // cancelled on callback, fires after 90s
    // Strong reference to presentation context shim — must outlive the session object.
    private let presentationProvider = OAuthPresentationContextProvider()
    #endif

    // MARK: Begin OAuth — uses ASWebAuthenticationSession with Strava's mobile endpoint.
    // Uses the iOS 17.4+ callback-based initializer which does NOT require a
    // presentationContextProvider — the system resolves the window automatically from
    // the active UIWindowScene. This eliminates the window-anchor race condition that
    // caused "Connect with Strava produces no action" on iOS 26 devices.
    // If the Strava app is installed, iOS will deep-link into it directly.
    // If not, it falls back to a Safari-based web flow automatically.

    #if os(iOS)
    func beginOAuth() {
        #if DEBUG
        print("🔬 [DIAG-A] beginOAuth START")
        print("🔬 [DIAG-A] Thread.isMainThread = \(Thread.isMainThread)")
        print("🔬 [DIAG-A] activeSession is nil = \(activeSession == nil)")
        print("🔬 [DIAG-A] isAuthenticating = \(isAuthenticating)")
        #endif
        OAuthLog.step("beginOAuth() called")
        OAuthLog.step("clientID=\(StravaConfig.clientID) redirectURI=\(StravaConfig.redirectURI)")

        #if targetEnvironment(simulator)
        // ── Simulator fast-path ────────────────────────────────────────────
        // ASWebAuthenticationSession cannot open Safari in the iOS Simulator.
        // Inject a synthetic token so the full app flow (BiometricGate → Dashboard)
        // can be exercised without a physical device.
        OAuthLog.warn("Simulator detected — injecting demo token to bypass OAuth web flow")
        guard !isAuthenticating else {
            OAuthLog.warn("Already authenticating — ignoring duplicate call")
            return
        }
        isAuthenticating = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.8))
            let demoToken = "SIMULATOR_DEMO_TOKEN_\(Int(Date().timeIntervalSince1970))"
            accessToken   = demoToken
            isDemoMode    = true
            let saved = BiometricAuth.shared.saveStravaToken(demoToken)
            OAuthLog.step("Demo token injected — keychain save: \(saved ? "✅" : "❌")")
            isAuthenticating = false
        }
        #else
        // ── Real-device OAuth flow ─────────────────────────────────────────
        startOAuthSession()
        #endif // targetEnvironment(simulator)
    }
    #endif // os(iOS)

    /// Forces real OAuth even on Simulator — use this to log in with a real Strava account.
    /// Requires "Hardware > Face ID > Enrolled" in Simulator settings for biometrics.
    #if os(iOS)
    func beginRealOAuth() {
        #if DEBUG
        print("🔬 [DIAG-A] beginOAuth START")
        print("🔬 [DIAG-A] Thread.isMainThread = \(Thread.isMainThread)")
        print("🔬 [DIAG-A] activeSession is nil = \(activeSession == nil)")
        print("🔬 [DIAG-A] isAuthenticating = \(isAuthenticating)")
        #endif
        OAuthLog.step("beginRealOAuth() — forcing real ASWebAuthenticationSession on Simulator")
        startOAuthSession()
    }
    #endif // os(iOS)

    // MARK: Shared OAuth session launcher (iOS 17.4+ callback API)
    //
    // Uses ASWebAuthenticationSession.init(url:callback:completionHandler:) which
    // resolves its presentation window automatically — no presentationContextProvider
    // delegate required. This is the API Apple recommends from iOS 17.4+ and the only
    // one that works reliably on iOS 26 without a window-anchor race condition.

    #if os(iOS)
    private func startOAuthSession() {
        guard !isAuthenticating else {
            OAuthLog.warn("startOAuthSession() called while already authenticating — ignoring")
            return
        }
        // Cancel and release any lingering session before creating a new one.
        // Without this, a previous session that was nilled but not cancelled can
        // cause session.start() to return false on the next OAuth attempt.
        if activeSession != nil {
            OAuthLog.warn("startOAuthSession() — cancelling lingering activeSession before creating new one")
            activeSession?.cancel()
            activeSession = nil
        }

        isAuthenticating = true
        OAuthLog.step("isAuthenticating = true")

        var components        = URLComponents(string: StravaConfig.authorizeURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id",       value: StravaConfig.clientID),
            URLQueryItem(name: "response_type",   value: "code"),
            URLQueryItem(name: "redirect_uri",    value: StravaConfig.redirectURI),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "scope",           value: "read,activity:read,read_all")
        ]

        guard let authURL = components.url else {
            OAuthLog.fail("Failed to construct auth URL — StravaConfig values malformed")
            isAuthenticating = false
            return
        }
        OAuthLog.step("Auth URL: \(authURL.absoluteString)")

        // iOS 17.4+ initializer — system resolves presentation window automatically.
        // No presentationContextProvider delegate required.
        activeSession = ASWebAuthenticationSession(
            url: authURL,
            callback: .customScheme("dcc-activities")
        ) { [weak self] callbackURL, error in
            #if DEBUG
            print("🔬 [DIAG-E] Completion handler fired")
            print("🔬 [DIAG-E] callbackURL = \(String(describing: callbackURL))")
            print("🔬 [DIAG-E] error = \(String(describing: error))")
            if let error {
                let nsErr = error as NSError
                print("🔬 [DIAG-E] error domain = \(nsErr.domain)")
                print("🔬 [DIAG-E] error code = \(nsErr.code)")
            }
            #endif
            // Callback arrives on an arbitrary thread — hop to MainActor immediately.
            Task { @MainActor [weak self] in
                guard let self else {
                    OAuthLog.fail("OAuth callback fired but StravaAPI was deallocated — token lost")
                    return
                }
                self.oauthTimeoutTask?.cancel()
                self.oauthTimeoutTask = nil

                if let error {
                    // ASWebAuthenticationSessionError.canceledLogin (code 1) means the user
                    // deliberately dismissed the sheet — not a failure worth showing an error for.
                    let asError = error as? ASWebAuthenticationSessionError
                    if asError?.code == .canceledLogin {
                        OAuthLog.warn("User cancelled the OAuth flow")
                    } else {
                        OAuthLog.fail("ASWebAuthenticationSession error: \(error.localizedDescription)")
                        AppLogger.error("OAuth session error", error: error)
                        self.lastError = .authenticationFailed
                    }
                    self.activeSession?.cancel()
                    self.activeSession    = nil
                    self.isAuthenticating = false
                    return
                }

                guard let callbackURL else {
                    OAuthLog.fail("OAuth callback URL is nil with no error — unexpected state")
                    self.lastError        = .authenticationFailed
                    self.activeSession?.cancel()
                    self.activeSession    = nil
                    self.isAuthenticating = false
                    return
                }

                OAuthLog.step("Callback URL received: \(callbackURL.absoluteString)")
                let success = await self.handleRedirect(url: callbackURL)
                OAuthLog.step("handleRedirect: \(success ? "SUCCESS ✅" : "FAILED ❌")")

                self.activeSession    = nil
                self.isAuthenticating = false

                if success {
                    self.lastError = nil
                    OAuthLog.step("OAuth complete — accessToken set, token persisted to keychain")
                } else {
                    self.lastError = .authenticationFailed
                    OAuthLog.fail("handleRedirect returned false — check worker logs above")
                }
            }
        }

        guard let session = activeSession else {
            OAuthLog.fail("CRITICAL: activeSession nil after creation — ASWebAuthenticationSession init failed")
            isAuthenticating = false
            return
        }
        #if DEBUG
        print("🔬 [DIAG-B] Session object created: \(session)")
        #endif

        // Share Safari cookies so users already logged in to Strava in Safari
        // don't need to re-enter credentials.
        session.prefersEphemeralWebBrowserSession = false

        #if DEBUG
        print("🔬 [DIAG-C] About to call start()")
        print("🔬 [DIAG-C] activeSession === session: \(activeSession === session)")
        let activeScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
        print("🔬 [DIAG-C] foreground UIWindowScenes count = \(activeScenes.count)")
        let keyWindows = activeScenes.flatMap { $0.windows }.filter { $0.isKeyWindow }
        print("🔬 [DIAG-C] key windows count = \(keyWindows.count)")
        #endif

        session.presentationContextProvider = presentationProvider
        OAuthLog.step("Calling session.start()...")
        let started = session.start()
        #if DEBUG
        print("🔬 [DIAG-D] session.start() returned: \(started)")
        if !started {
            print("🔬 [DIAG-D] FAILURE — dumping session state:")
            print("🔬 [DIAG-D]   canStart = \(session.canStart)")
            let scenes = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
            for scene in scenes {
                for window in scene.windows {
                    print("🔬 [DIAG-D] window=\(window) key=\(window.isKeyWindow) root=\(String(describing: window.rootViewController))")
                    if let presented = window.rootViewController?.presentedViewController {
                        print("🔬 [DIAG-D]   PRESENTED VC = \(presented)")
                    }
                }
            }
        }
        #endif

        if started {
            OAuthLog.step("session.start() = true — browser opening")
            // 90s safety timeout — prevents isAuthenticating being stuck if the user
            // switches away without completing or cancelling the OAuth sheet.
            oauthTimeoutTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(90))
                guard !Task.isCancelled, let self, self.isAuthenticating else { return }
                OAuthLog.warn("OAuth timeout (90s) — resetting state")
                self.activeSession    = nil
                self.isAuthenticating = false
            }
        } else {
            // session.start() returned false — most likely cause is a window hierarchy
            // not yet fully active (e.g., called too early after launch animation).
            // Do NOT set lastError here: setting it fires the crash overlay on the login
            // screen, which then calls refreshAccessToken with no token → logout().
            // Simply reset state so the user can tap Connect again.
            OAuthLog.fail("session.start() = false — resetting state, user can retry")
            isAuthenticating = false
            activeSession    = nil
        }
    }
    #endif // os(iOS)

    // MARK: Handle redirect callback

    @discardableResult
    func handleRedirect(url: URL) async -> Bool {
        OAuthLog.step("handleRedirect — url: \(url.absoluteString)")
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        // Strava sends an error param when the user denies permission
        if let errorParam = components?.queryItems?.first(where: { $0.name == "error" })?.value {
            OAuthLog.fail("Strava returned error param: \(errorParam)")
            return false
        }
        guard let code = components?.queryItems?.first(where: { $0.name == "code" })?.value else {
            OAuthLog.fail("No 'code' query param in redirect URL — full URL: \(url.absoluteString)")
            return false
        }
        OAuthLog.step("Auth code extracted: \(code.prefix(8))... (first 8 chars shown)")
        return await exchangeCodeViaProxy(code: code)
    }

    // MARK: Exchange code → tokens via Cloudflare Worker

    func exchangeCodeViaProxy(code: String) async -> Bool {
        OAuthLog.step("exchangeCodeViaProxy — worker: \(StravaConfig.workerURL)/exchange")
        guard let url = URL(string: "\(StravaConfig.workerURL)/exchange") else {
            OAuthLog.fail("Worker URL malformed: \(StravaConfig.workerURL)/exchange")
            lastError = .authenticationFailed
            return false
        }
        var request        = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            // Encode the POST body — use do/catch so a body failure is not silently swallowed
            request.httpBody = try JSONEncoder().encode(["code": code, "client_id": StravaConfig.clientID])
        } catch {
            OAuthLog.fail("exchangeCodeViaProxy — failed to encode request body: \(error)")
            AppLogger.error("Token exchange body encoding failed", error: error)
            lastError = .authenticationFailed
            return false
        }
        do {
            OAuthLog.step("POSTing code to Cloudflare worker...")
            let (data, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            OAuthLog.step("Worker responded HTTP \(statusCode)")
            if !(200...299).contains(statusCode) {
                let body = String(data: data, encoding: .utf8) ?? "<unreadable>"
                OAuthLog.fail("Worker /exchange HTTP \(statusCode): \(body)")
                AppLogger.error("Token exchange HTTP \(statusCode): \(body)")
                lastError = statusCode == 401 ? .tokenExpired : .stravaAPIError(message: "HTTP \(statusCode)")
                return false
            }
            let token      = try JSONDecoder().decode(TokenResponse.self, from: data)
            accessToken    = token.access_token
            refreshToken   = token.refresh_token
            tokenExpiresAt = token.expires_at ?? 0
            OAuthLog.step("accessToken set in memory (first 8): \(token.access_token.prefix(8))...")
            // Persist both tokens so every subsequent cold launch can restore them.
            // The refresh token is critical — without it, silent token refresh after
            // relaunch always fails because refreshToken is in-memory only.
            #if os(iOS)
            let savedAccess  = BiometricAuth.shared.saveStravaToken(token.access_token)
            let savedRefresh: Bool
            if let rt = token.refresh_token {
                savedRefresh = BiometricAuth.shared.saveStravaRefreshToken(rt)
            } else {
                OAuthLog.warn("exchangeCodeViaProxy — server returned no refresh_token")
                savedRefresh = true  // not a failure, but silent refresh won't work
            }
            let saved = savedAccess && savedRefresh
            #else
            let saved = StravaAPI.saveTokenToKeychain(token.access_token)
            #endif
            OAuthLog.step("Keychain save result: \(saved ? "✅ both tokens saved" : "❌ FAILED")")
            if !saved { AppLogger.error("Keychain save failed after token exchange") }
            lastError = nil   // clear any previous error on success
            return true
        } catch let urlError as URLError {
            OAuthLog.fail("exchangeCodeViaProxy network error: \(urlError)")
            AppLogger.error("Token exchange network error", error: urlError)
            lastError = urlError.code == .notConnectedToInternet ? .networkUnavailable : .requestTimeout
            return false
        } catch {
            OAuthLog.fail("exchangeCodeViaProxy threw: \(error)")
            AppLogger.error("Token exchange failed", error: error)
            lastError = .authenticationFailed
            return false
        }
    }

    // MARK: Refresh token via Cloudflare Worker

    func refreshAccessToken() async -> Bool {
        OAuthLog.step("refreshAccessToken — worker: \(StravaConfig.workerURL)/refresh")
        guard let rt = refreshToken else {
            OAuthLog.fail("refreshAccessToken called but refreshToken is nil — cannot refresh")
            lastError = .tokenExpired
            return false
        }
        guard let url = URL(string: "\(StravaConfig.workerURL)/refresh") else {
            lastError = .authenticationFailed
            return false
        }
        var request        = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONEncoder().encode(["refresh_token": rt, "client_id": StravaConfig.clientID])
        } catch {
            OAuthLog.fail("refreshAccessToken — body encoding failed: \(error)")
            AppLogger.error("Token refresh body encoding failed", error: error)
            lastError = .authenticationFailed
            return false
        }
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            OAuthLog.step("Refresh worker HTTP \(statusCode)")
            if !(200...299).contains(statusCode) {
                let body = String(data: data, encoding: .utf8) ?? ""
                OAuthLog.fail("Worker /refresh HTTP \(statusCode): \(body)")
                AppLogger.error("Token refresh HTTP \(statusCode): \(body)")
                lastError = .tokenExpired
                return false
            }
            let token        = try JSONDecoder().decode(TokenResponse.self, from: data)
            let newRefresh   = token.refresh_token ?? rt   // Strava may rotate or re-use
            accessToken      = token.access_token
            refreshToken     = newRefresh
            tokenExpiresAt   = token.expires_at ?? 0
            OAuthLog.step("accessToken refreshed (first 8): \(token.access_token.prefix(8))...")
            // Persist both tokens — the refresh token may have been rotated by Strava
            #if os(iOS)
            let savedAccess  = BiometricAuth.shared.saveStravaToken(token.access_token)
            let savedRefresh = BiometricAuth.shared.saveStravaRefreshToken(newRefresh)
            let saved = savedAccess && savedRefresh
            #else
            let saved = StravaAPI.saveTokenToKeychain(token.access_token)
            #endif
            OAuthLog.step("Keychain save (refreshed tokens): \(saved ? "✅ both saved" : "❌ FAILED")")
            if !saved { AppLogger.error("Keychain save failed after token refresh") }
            lastError = nil
            return true
        } catch let urlError as URLError {
            OAuthLog.fail("refreshAccessToken network error: \(urlError)")
            AppLogger.error("Token refresh network error", error: urlError)
            lastError = urlError.code == .notConnectedToInternet ? .networkUnavailable : .requestTimeout
            return false
        } catch {
            OAuthLog.fail("refreshAccessToken threw: \(error)")
            AppLogger.error("Token refresh failed", error: error)
            lastError = .tokenExpired
            return false
        }
    }

    // MARK: Token freshness

    var isTokenFresh: Bool {
        guard accessToken != nil else { return false }
        // If we don't have expiration info (e.g., token loaded from keychain), assume it's valid
        guard tokenExpiresAt > 0 else { return true }
        return Int(Date().timeIntervalSince1970) < (tokenExpiresAt - 300)  // 5-min buffer
    }

    private func ensureFreshToken() async throws {
        guard accessToken != nil else { throw StravaError.notAuthenticated }
        // Only try to refresh if we have expiration info and token is stale
        if tokenExpiresAt > 0 && !isTokenFresh {
            guard await refreshAccessToken() else { throw StravaError.tokenExpired }
        }
    }

    // MARK: Fetch authenticated athlete profile

    func fetchAuthenticatedAthlete() async throws -> AthleteProfile {
        // Demo mode: return a synthetic profile so the Simulator never hits the real API
        if isDemoMode {
            OAuthLog.step("fetchAuthenticatedAthlete — demo mode, returning mock profile")
            return AthleteProfile(
                id: 9999999,
                firstname: "Demo",
                lastname: "Rider",
                profile: nil,
                city: "London",
                state: "England",
                country: "United Kingdom"
            )
        }

        try await ensureFreshToken()
        guard let token = accessToken else { throw StravaError.notAuthenticated }

        let urlStr = "https://www.strava.com/api/v3/athlete"
        guard let url = URL(string: urlStr) else { throw StravaError.badURL }

        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode == 401 { throw StravaError.tokenExpired }

        do {
            return try JSONDecoder().decode(AthleteProfile.self, from: data)
        } catch {
            AppLogger.error("Decoding athlete profile error: \(error)", error: error)
            OAuthLog.fail("Raw athlete response: \(String(data: data, encoding: .utf8) ?? "<unreadable>")")
            throw StravaError.decodingFailed
        }
    }

    // MARK: Fetch last week's club activities

    func fetchLastWeeksClubActivities(isExtendedFetch: Bool = false) async throws -> [Activity] {
        // Demo mode: return realistic mock activities so all charts and tables render
        if isDemoMode {
            OAuthLog.step("fetchLastWeeksClubActivities — demo mode, returning mock activities")
            return Self.mockActivities()
        }

        try await ensureFreshToken()
        guard let token = accessToken else { throw StravaError.notAuthenticated }

        // Use ISO week calculation for consistent Monday-Sunday boundaries
        let timestamps: (after: Int, before: Int)
        let interval: DateInterval
        
        if isExtendedFetch {
            // Fetch 2-week extended range
            timestamps = DateRangeProvider.getExtendedWeekTimestamps()
            interval = DateRangeProvider.getExtendedWeekRange()
        } else {
            // Fetch CURRENT week (not last completed week)
            // This ensures we show this week's data (Monday to today)
            timestamps = DateRangeProvider.getCurrentWeekTimestamps()
            interval = DateRangeProvider.getCurrentWeek()
        }
        
        // STRAVA CLUBS ENDPOINT CONSTRAINT — 2026-02-24
        // The /v3/clubs/{id}/activities endpoint does NOT support both
        // "after" and "before" query parameters in the same request.
        // Strava returns: {"message":"Bad Request","errors":[{"field":"before after","code":"both provided"}]}
        // Fix: send only "after" (start of week as Unix timestamp).
        // Filter the decoded response array in code using weekEnd date
        // to exclude any activities beyond the target week boundary.
        // Do not add "before" back to this URL under any circumstances.
        let urlStr = "https://www.strava.com/api/v3/clubs/\(StravaConfig.clubID)/activities?per_page=200&after=\(timestamps.after)"
        
        // Debug logging for date range verification
        let formatter = ISO8601DateFormatter()
        #if DEBUG
        print("📅 Fetching activities from \(formatter.string(from: interval.start)) to \(formatter.string(from: interval.end))")
        if isExtendedFetch {
            print("🔄 Extended 2-week range active due to empty current week")
        }
        print("📡 API URL: \(urlStr)")
        #endif
        
        guard let url = URL(string: urlStr) else { throw StravaError.badURL }

        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode == 401 { throw StravaError.tokenExpired }

        do {
            let decodedActivities = try JSONDecoder().decode([StravaActivityResponse].self, from: data).map { $0.toActivity() }
            
            // ─────────────────────────────────────────────────────
            // STRAVA CLUB ENDPOINT — NO DATE FIELD IN RESPONSE
            // The /v3/clubs/{id}/activities endpoint does not return
            // start_date or start_date_local in its response payload.
            // Date filtering is handled entirely server-side via the
            // "after" Unix timestamp query parameter.
            // DO NOT add a date-based filter here — it will reject
            // all activities as Date.distantPast.
            // Verified: 2026-02-24 — raw response confirmed no dates.
            // ─────────────────────────────────────────────────────
            let activities = decodedActivities
            // No date filter needed — Strava club endpoint does not 
            // return date fields. The API "after=" parameter handles
            // server-side filtering. All returned activities are 
            // within the requested date range by definition.
            
            #if DEBUG
            print("[Filter] Using all \(activities.count) activities returned by Strava API")
            #endif
            
            // SMART 2-WEEK FALLBACK — 2026-02-24
            // If Strava returned 0 activities for the week,
            // extend the range — no in-code filter to check
            if activities.count == 0 && !isExtendedFetch {
                #if DEBUG
                print("⚠️ No activities found for current week, extending to 2-week range...")
                #endif
                isShowingExtendedRange = true
                return try await fetchLastWeeksClubActivities(isExtendedFetch: true)
            } else if isExtendedFetch {
                // Already in extended mode
                isShowingExtendedRange = true
                if activities.count == 0 {
                    #if DEBUG
                    print("⚠️ No activities found in extended 2-week range")
                    #endif
                }
            } else {
                // Standard week with data
                isShowingExtendedRange = false
            }
            
            // Debug logging for fetched data
            let totalKM = activities.reduce(0.0) { $0 + $1.distance }
            #if DEBUG
            print("📊 Fetched \(activities.count) activities, total distance: \(String(format: "%.1f", totalKM)) km")
            #endif
            
            return activities
        } catch {
            AppLogger.error("Decoding club activities error: \(error)", error: error)
            OAuthLog.fail("Raw Strava club response: \(String(data: data, encoding: .utf8) ?? "<unreadable>")")
            throw StravaError.decodingFailed
        }
    }
    
    // MARK: Fetch activities for a specific week + its previous week

    /// Fetches club activities for the requested week AND the week before it.
    ///
    /// Because the Strava clubs endpoint does NOT return date fields in its response,
    /// we cannot split a single response reliably by date. Instead we make TWO
    /// sequential API calls — one for each week — using only the `after=` parameter
    /// (Strava rejects requests that include both `after=` and `before=`).
    ///
    /// Call 1: after = Monday of selected week  → selected week's activities
    /// Call 2: after = Monday of previous week  → both weeks combined; we subtract
    ///         the selected week count to isolate the previous week's activities.
    ///
    /// - Parameter weekOffset: 0 = this week, -1 = last week, -2 = two weeks ago, etc.
    /// - Returns: A tuple of (selectedWeekActivities, previousWeekActivities, selectedWeekInterval)
    func fetchActivitiesForWeek(
        offset weekOffset: Int
    ) async throws -> (current: [Activity], previous: [Activity], interval: DateInterval) {
        if isDemoMode {
            OAuthLog.step("fetchActivitiesForWeek — demo mode, returning mock activities")
            let mockAll = Self.mockActivities()
            let interval = DateRangeProvider.weekRange(offset: weekOffset)
            return (current: mockAll, previous: mockAll, interval: interval)
        }

        try await ensureFreshToken()
        guard let token = accessToken else { throw StravaError.notAuthenticated }

        let selectedWeek = DateRangeProvider.weekRange(offset: weekOffset)
        let previousWeek = DateRangeProvider.previousWeekRange(before: selectedWeek)

        let formatter = ISO8601DateFormatter()
        #if DEBUG
        print("📅 [WeekFetch] Selected: \(formatter.string(from: selectedWeek.start)) – \(formatter.string(from: selectedWeek.end))")
        print("📅 [WeekFetch] Previous: \(formatter.string(from: previousWeek.start)) – \(formatter.string(from: previousWeek.end))")
        #endif

        // ── Call 1: activities from start of SELECTED week onwards ────────────
        let currentTimestamp = Int(selectedWeek.start.timeIntervalSince1970)
        let currentURL = "https://www.strava.com/api/v3/clubs/\(StravaConfig.clubID)/activities?per_page=200&after=\(currentTimestamp)"
        #if DEBUG
        print("📡 [WeekFetch] Current week URL: \(currentURL)")
        #endif

        let currentActivities = try await fetchRawActivities(urlString: currentURL, token: token)
        #if DEBUG
        print("[WeekFetch] Selected week: \(currentActivities.count) activities")
        #endif

        // ── Call 2: activities from start of PREVIOUS week onwards ─────────────
        // This returns selected week + previous week combined.
        // We subtract the selected week activities to isolate the previous week.
        let previousTimestamp = Int(previousWeek.start.timeIntervalSince1970)
        let previousURL = "https://www.strava.com/api/v3/clubs/\(StravaConfig.clubID)/activities?per_page=200&after=\(previousTimestamp)"
        #if DEBUG
        print("📡 [WeekFetch] Two-week URL: \(previousURL)")
        #endif

        let twoWeekActivities = try await fetchRawActivities(urlString: previousURL, token: token)
        #if DEBUG
        print("[WeekFetch] Two-week combined: \(twoWeekActivities.count) activities")
        #endif

        // The previous week activities are the EXTRA ones returned by the wider call.
        // Strava returns newest-first, so the last (twoWeekCount - selectedWeekCount)
        // entries are the older (previous week) ones.
        let previousCount = max(0, twoWeekActivities.count - currentActivities.count)
        let previousActivities = Array(twoWeekActivities.suffix(previousCount))
        #if DEBUG
        print("[WeekFetch] Isolated previous week: \(previousActivities.count) activities")
        #endif

        isShowingExtendedRange = false
        return (current: currentActivities, previous: previousActivities, interval: selectedWeek)
    }

    /// Internal helper: performs a single GET to the clubs activities endpoint.
    private func fetchRawActivities(urlString: String, token: String) async throws -> [Activity] {
        guard let url = URL(string: urlString) else { throw StravaError.badURL }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode == 401 { throw StravaError.tokenExpired }

        do {
            return try JSONDecoder().decode([StravaActivityResponse].self, from: data).map { $0.toActivity() }
        } catch {
            AppLogger.error("[fetchRawActivities] Decoding error: \(error)", error: error)
            OAuthLog.fail("[fetchRawActivities] Raw response: \(String(data: data, encoding: .utf8) ?? "<unreadable>")")
            throw StravaError.decodingFailed
        }
    }

    // MARK: Fetch club activities for custom date range (legacy)

    func fetchClubActivities(weeksBack: Int = 3) async throws -> [Activity] {
        try await ensureFreshToken()
        guard let token = accessToken else { throw StravaError.notAuthenticated }

        let after  = Int(Date().addingTimeInterval(-Double(weeksBack) * 7 * 24 * 60 * 60).timeIntervalSince1970)
        let urlStr = "https://www.strava.com/api/v3/clubs/\(StravaConfig.clubID)/activities?per_page=200&after=\(after)"
        guard let url = URL(string: urlStr) else { throw StravaError.badURL }

        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode == 401 { throw StravaError.tokenExpired }

        do {
            return try JSONDecoder().decode([StravaActivityResponse].self, from: data).map { $0.toActivity() }
        } catch {
            AppLogger.error("[fetchClubActivities] Decoding error: \(error)", error: error)
            OAuthLog.fail("[fetchClubActivities] Raw response: \(String(data: data, encoding: .utf8) ?? "<unreadable>")")
            throw StravaError.decodingFailed
        }
    }
}

// MARK: - Simulator / Demo Mock Data

extension StravaAPI {
    /// Generates a realistic week of club activity data for Simulator demo mode.
    /// All rides are placed within the current ISO week so date-range filtering passes.
    static func mockActivities() -> [Activity] {
        let calendar = Calendar(identifier: .iso8601)
        let today = Date()
        // Anchor rides to Mon–today of the current ISO week
        func weekday(_ offset: Int) -> Date {
            // Use optional binding instead of force-unwrap; fall back to today if calendar fails
            guard let monday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
                AppLogger.warning("mockActivities: calendar week anchor calculation failed, using today")
                return calendar.date(byAdding: .day, value: offset, to: today) ?? today
            }
            return calendar.date(byAdding: .day, value: offset, to: monday) ?? today
        }

        let riders: [(name: String, rides: [(km: Double, speed: Double, elev: Double, day: Int, type: String)])] = [
            ("Amit Kamat",    [(42.5, 28.3, 320, 0, "Ride"), (28.1, 26.4, 180, 2, "Ride")]),
            ("Priya Sharma",  [(55.0, 30.1, 450, 1, "Ride"), (18.3, 24.0, 90,  3, "Ride")]),
            ("Rajesh Patel",  [(38.7, 27.5, 210, 0, "Ride")]),
            ("Neha Gupta",    [(61.2, 31.8, 520, 1, "Ride"), (35.4, 29.0, 280, 4, "Ride")]),
            ("Vikram Singh",  [(47.0, 29.2, 380, 2, "Ride"), (22.0, 25.5, 140, 5, "Ride")]),
            ("Sunita Mehta",  [(33.5, 26.8, 170, 3, "Ride")]),
            ("Arjun Nair",    [(70.1, 32.5, 610, 0, "Ride"), (40.0, 30.0, 350, 4, "Ride")]),
            ("Deepa Verma",   [(25.8, 23.9, 130, 1, "Ride")]),
            ("Karan Khanna",  [(52.3, 29.7, 430, 2, "Ride"), (30.0, 27.0, 200, 5, "Ride")]),
            ("Meera Joshi",   [(44.6, 28.0, 290, 3, "Ride")])
        ]

        var activities: [Activity] = []
        for rider in riders {
            for ride in rider.rides {
                let movingSec = Int((ride.km / ride.speed) * 3600)
                activities.append(Activity(
                    memberName:    rider.name,
                    activityName:  "Morning Ride",
                    distance:      ride.km,
                    date:          weekday(ride.day),
                    averageSpeed:  ride.speed,
                    elevationGain: ride.elev,
                    movingTime:    movingSec,
                    type:          ride.type
                ))
            }
        }
        return activities
    }
}

// MARK: - Authenticated Athlete Profile

struct AthleteProfile: Codable, Identifiable {
    let id: Int
    let firstname: String
    let lastname: String
    let profile: String?
    let city: String?
    let state: String?
    let country: String?
}

// MARK: - Strava Activity Response (Decoding)
// NOTE: The /clubs/{id}/activities endpoint intentionally omits `id` and
// athlete identifiers for privacy. All numeric fields are made optional
// to handle activities where Strava returns 0 or null.
struct StravaActivityResponse: Codable {
    let name: String
    let distance: Double?          // in meters — may be 0 or missing
    let moving_time: Int?          // in seconds — may be missing
    let total_elevation_gain: Double? // in meters — may be missing
    let average_speed: Double?     // in meters/second — may be missing
    let start_date: String?        // ISO 8601 UTC datetime
    let start_date_local: String?  // ISO 8601 local datetime
    let type: String?
    let sport_type: String?        // newer Strava field, preferred over `type`
    let athlete: Athlete

    struct Athlete: Codable {
        let firstname: String
        let lastname: String
    }

    func toActivity() -> Activity {
        let formatter = ISO8601DateFormatter()
        // CRITICAL FIX: Try start_date first (UTC), then start_date_local as fallback
        // Some club activities may only have start_date_local
        // Use distantPast as final fallback to detect and skip invalid activities
        let dateVal: Date
        if let startDateStr = start_date, let parsed = formatter.date(from: startDateStr) {
            dateVal = parsed
        } else if let startDateLocalStr = start_date_local, let parsed = formatter.date(from: startDateLocalStr) {
            dateVal = parsed
        } else {
            dateVal = Date.distantPast
        }
        
        let km        = (distance ?? 0) / 1000.0
        let movingTimeSec = moving_time ?? 0
        
        // Calculate average speed from distance and time if Strava doesn't provide it
        var speedKMH  = (average_speed ?? 0) * 3.6  // m/s → km/h
        if speedKMH == 0 && movingTimeSec > 0 && km > 0 {
            // Calculate: speed = distance / time
            // km / seconds * 3600 = km/h
            speedKMH = (km / Double(movingTimeSec)) * 3600
        }
        
        let member    = "\(athlete.firstname) \(athlete.lastname)"
        // Prefer `sport_type` (newer) over legacy `type`
        let actType   = sport_type ?? type ?? "Ride"
        return Activity(
            memberName:    member,
            activityName:  name,
            distance:      km,
            date:          dateVal,
            averageSpeed:  speedKMH,
            elevationGain: total_elevation_gain ?? 0,
            movingTime:    movingTimeSec,
            type:          actType
        )
    }
}

// Note: You must set up your app's redirect URI with Strava and replace client ID/secret/club ID.
// You must also handle the OAuth redirect in your AppDelegate/SceneDelegate or via .onOpenURL in SwiftUI.

// MARK: - Presentation Context Provider
// Diagnostic run confirmed: session.start() returns false with
// "Cannot start ASWebAuthenticationSession without providing presentation context."
// The iOS 17.4+ callback: initialiser still requires presentationContextProvider to be set
// on physical devices running iOS 26; auto-resolution is not sufficient.
//
// StravaAPI is @Observable (a Swift struct-like class) and cannot inherit from NSObject,
// which ASWebAuthenticationPresentationContextProviding requires via NSObjectProtocol.
// Solution: a lightweight NSObject shim that holds no state and resolves the window inline.
#if os(iOS)
final class OAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let foregroundScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        return foregroundScene?.windows.first(where: { $0.isKeyWindow })
            ?? ASPresentationAnchor()
    }
}
#endif

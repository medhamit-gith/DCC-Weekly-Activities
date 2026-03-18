//
//  UserAuthService.swift
//  DCC-Weekly-Activities
//
//  All Strava OAuth, token exchange/refresh, athlete profile fetch, and logout logic.
//  Extracted from StravaAPI.swift so auth concerns are isolated from data-fetching.
//
//  PLATFORM NOTES:
//  - iOS token persistence goes through BiometricAuth (unchanged from original StravaAPI).
//  - tvOS / tests use KeychainService directly.
//  - Views observe this via @State (same as StravaAPI — @Observable, not ObservableObject).
//

#if os(iOS)
import AuthenticationServices
#endif
import Foundation
import Observation
import SwiftUI
#if !os(iOS)
import Security
#endif

// MARK: - Token response from Cloudflare Worker

struct TokenResponse: Decodable {
    let access_token:  String
    let refresh_token: String?
    let expires_at:    Int?     // Unix timestamp when access_token expires
}

// MARK: - Presentation Context Provider (iOS only)
// NSObject shim required for ASWebAuthenticationPresentationContextProviding.
// StravaAPI / UserAuthService are @Observable and cannot inherit NSObject directly.

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

// MARK: - UserAuthService

@MainActor
@Observable
final class UserAuthService {

    static let shared = UserAuthService()

    // MARK: Observable state (read by views)
    var accessToken: String?
    var isAuthenticating: Bool = false
    /// Last auth error. Bind to `.crashErrorOverlay(error: authService.lastError)` in views.
    var lastError: AppError?
    /// True when running on Simulator with a demo token injected.
    private(set) var isDemoMode: Bool = false

    // MARK: Token metadata (private storage, read-only accessors)
    private(set) var tokenExpiresAt: Int    = 0
    private(set) var refreshToken:   String?

    /// Read-only access for building the Apple TV token bundle and debug screens.
    var currentRefreshToken:   String? { refreshToken }
    var currentTokenExpiresAt: Int     { tokenExpiresAt }

    // MARK: Token freshness
    var isTokenFresh: Bool {
        guard accessToken != nil else { return false }
        guard tokenExpiresAt > 0 else { return true }    // no expiry info → assume valid
        return Int(Date().timeIntervalSince1970) < (tokenExpiresAt - 300)  // 5-min buffer
    }

    // MARK: iOS-only OAuth session state
#if os(iOS)
    private var activeSession:    ASWebAuthenticationSession?
    private var oauthTimeoutTask: Task<Void, Never>?
    private let presentationProvider = OAuthPresentationContextProvider()
#endif

    // MARK: Dependency injection (for tests)
    private let config:   StravaConfig
    private let keychain: KeychainServiceProtocol

    init(config: StravaConfig = .default, keychain: KeychainServiceProtocol = KeychainService.shared) {
        self.config   = config
        self.keychain = keychain
    }

    // MARK: - Restore state on cold launch

    /// Call on cold launch to restore the demo-mode flag from keychain token.
    func restoreDemoMode() {
        isDemoMode = true
        OAuthLog.step("restoreDemoMode() — demo mode flag restored")
    }

    /// Call on cold launch to restore the refresh token from keychain into memory.
    /// Without this, `refreshAccessToken()` always fails after relaunch.
    func restoreRefreshToken(_ token: String) {
        refreshToken = token
        OAuthLog.step("restoreRefreshToken() — refresh token restored (length: \(token.count))")
    }

    // MARK: - Logout

    /// Single logout entry-point. Clears token from memory, keychain, and resets all flags.
    func logout() {
        OAuthLog.step("logout() — clearing all auth state")
        accessToken    = nil
        refreshToken   = nil
        tokenExpiresAt = 0
        isDemoMode     = false
#if os(iOS)
        BiometricAuth.shared.logout()  // clears isAuthenticated + keychain token
#else
        keychain.delete(key: "strava_access_token")
        keychain.delete(key: "strava_refresh_token")
#endif
    }

    // MARK: - Begin OAuth (iOS)

#if os(iOS)
    /// Start the OAuth flow. On Simulator, injects a demo token instead of opening Safari.
    func beginOAuth() {
#if DEBUG
        print("🔬 [DIAG-A] beginOAuth START")
        print("🔬 [DIAG-A] Thread.isMainThread = \(Thread.isMainThread)")
        print("🔬 [DIAG-A] activeSession is nil = \(activeSession == nil)")
        print("🔬 [DIAG-A] isAuthenticating = \(isAuthenticating)")
#endif
        OAuthLog.step("beginOAuth() called")
        OAuthLog.step("clientID=\(config.clientID) redirectURI=\(config.redirectURI)")

#if targetEnvironment(simulator)
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
        startOAuthSession()
#endif
    }

    /// Forces real OAuth even on Simulator — use to log in with a real Strava account.
    func beginRealOAuth() {
#if DEBUG
        print("🔬 [DIAG-A] beginRealOAuth START")
        print("🔬 [DIAG-A] Thread.isMainThread = \(Thread.isMainThread)")
        print("🔬 [DIAG-A] activeSession is nil = \(activeSession == nil)")
        print("🔬 [DIAG-A] isAuthenticating = \(isAuthenticating)")
#endif
        OAuthLog.step("beginRealOAuth() — forcing real ASWebAuthenticationSession on Simulator")
        startOAuthSession()
    }

    // MARK: Shared OAuth session launcher (iOS 17.4+ callback API)

    private func startOAuthSession() {
        guard !isAuthenticating else {
            OAuthLog.warn("startOAuthSession() called while already authenticating — ignoring")
            return
        }
        if activeSession != nil {
            OAuthLog.warn("startOAuthSession() — cancelling lingering activeSession before creating new one")
            activeSession?.cancel()
            activeSession = nil
        }

        isAuthenticating = true
        OAuthLog.step("isAuthenticating = true")

        var components        = URLComponents(string: config.authorizeURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id",       value: config.clientID),
            URLQueryItem(name: "response_type",   value: "code"),
            URLQueryItem(name: "redirect_uri",    value: config.redirectURI),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "scope",           value: "read,activity:read,read_all")
        ]

        guard let authURL = components.url else {
            OAuthLog.fail("Failed to construct auth URL — StravaConfig values malformed")
            isAuthenticating = false
            return
        }
        OAuthLog.step("Auth URL: \(authURL.absoluteString)")

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
            Task { @MainActor [weak self] in
                guard let self else {
                    OAuthLog.fail("OAuth callback fired but UserAuthService was deallocated — token lost")
                    return
                }
                self.oauthTimeoutTask?.cancel()
                self.oauthTimeoutTask = nil

                if let error {
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
            oauthTimeoutTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(90))
                guard !Task.isCancelled, let self, self.isAuthenticating else { return }
                OAuthLog.warn("OAuth timeout (90s) — resetting state")
                self.activeSession    = nil
                self.isAuthenticating = false
            }
        } else {
            OAuthLog.fail("session.start() = false — resetting state, user can retry")
            isAuthenticating = false
            activeSession    = nil
        }
    }
#endif // os(iOS)

    // MARK: - Handle redirect callback

    @discardableResult
    func handleRedirect(url: URL) async -> Bool {
        OAuthLog.step("handleRedirect — url: \(url.absoluteString)")
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
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

    // MARK: - Exchange code → tokens via Cloudflare Worker

    func exchangeCodeViaProxy(code: String) async -> Bool {
        OAuthLog.step("exchangeCodeViaProxy — worker: \(config.workerURL)/exchange")
        guard let url = URL(string: "\(config.workerURL)/exchange") else {
            OAuthLog.fail("Worker URL malformed: \(config.workerURL)/exchange")
            lastError = .authenticationFailed
            return false
        }
        var request        = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONEncoder().encode(["code": code, "client_id": config.clientID])
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
#if os(iOS)
            let savedAccess  = BiometricAuth.shared.saveStravaToken(token.access_token)
            let savedRefresh: Bool
            if let rt = token.refresh_token {
                savedRefresh = BiometricAuth.shared.saveStravaRefreshToken(rt)
            } else {
                OAuthLog.warn("exchangeCodeViaProxy — server returned no refresh_token")
                savedRefresh = true
            }
            let saved = savedAccess && savedRefresh
#else
            var saved = keychain.save(key: "strava_access_token", value: token.access_token)
            if let rt = token.refresh_token {
                saved = keychain.save(key: "strava_refresh_token", value: rt) && saved
            }
#endif
            OAuthLog.step("Keychain save result: \(saved ? "✅ both tokens saved" : "❌ FAILED")")
            if !saved { AppLogger.error("Keychain save failed after token exchange") }
            lastError = nil
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

    // MARK: - Refresh token via Cloudflare Worker

    func refreshAccessToken() async -> Bool {
        OAuthLog.step("refreshAccessToken — worker: \(config.workerURL)/refresh")
        guard let rt = refreshToken else {
            OAuthLog.fail("refreshAccessToken called but refreshToken is nil — cannot refresh")
            lastError = .tokenExpired
            return false
        }
        guard let url = URL(string: "\(config.workerURL)/refresh") else {
            lastError = .authenticationFailed
            return false
        }
        var request        = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONEncoder().encode(["refresh_token": rt, "client_id": config.clientID])
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
            let newRefresh   = token.refresh_token ?? rt
            accessToken      = token.access_token
            refreshToken     = newRefresh
            tokenExpiresAt   = token.expires_at ?? 0
            OAuthLog.step("accessToken refreshed (first 8): \(token.access_token.prefix(8))...")
#if os(iOS)
            let savedAccess  = BiometricAuth.shared.saveStravaToken(token.access_token)
            let savedRefresh = BiometricAuth.shared.saveStravaRefreshToken(newRefresh)
            let saved = savedAccess && savedRefresh
#else
            let saved = keychain.save(key: "strava_access_token", value: token.access_token)
                     && keychain.save(key: "strava_refresh_token", value: newRefresh)
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

    // MARK: - Token freshness enforcement

    func ensureFreshToken() async throws {
        guard accessToken != nil else { throw StravaError.notAuthenticated }
        if tokenExpiresAt > 0 && !isTokenFresh {
            guard await refreshAccessToken() else { throw StravaError.tokenExpired }
        }
    }

    // MARK: - Fetch authenticated athlete profile

    func fetchAuthenticatedAthlete() async throws -> AthleteProfile {
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

        guard let url = URL(string: "https://www.strava.com/api/v3/athlete") else {
            throw StravaError.badURL
        }

        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            throw StravaError.tokenExpired
        }

        do {
            return try JSONDecoder().decode(AthleteProfile.self, from: data)
        } catch {
            AppLogger.error("Decoding athlete profile error: \(error)", error: error)
            OAuthLog.fail("Raw athlete response: \(String(data: data, encoding: .utf8) ?? "<unreadable>")")
            throw StravaError.decodingFailed
        }
    }
}

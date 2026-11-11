//
//  UserAuthServiceTests.swift
//  DCC-Weekly-Activities Tests
//
//  Unit tests for UserAuthService (SCRUM-37, AC-1).
//
//  Scope note: UserAuthService's network calls (exchangeCodeViaProxy, the
//  request in refreshAccessToken, the non-demo branch of
//  fetchAuthenticatedAthlete) go through AppNetwork.session, which has no
//  injection point, so they cannot be unit-tested without a live network.
//  These tests cover the branches that return before any request is made:
//  token-freshness logic, cold-launch state restore, the early exits in
//  handleRedirect() and refreshAccessToken(), and the demo-mode fast path in
//  fetchAuthenticatedAthlete(). AC-1's "successful OAuth flow" and "token
//  refresh works" scenarios need a mocked worker response and are not
//  covered here.
//
//  logout() is deliberately not exercised: on iOS it calls
//  BiometricAuth.shared.logout(), which deletes the real Strava tokens from
//  the test host's keychain. Running the suite would sign the host app out.
//

import Testing
import Foundation
@testable import DCC_Weekly_Activities

/// In-memory keychain for these tests.
/// MockServices.swift in this folder is not compiled into this target
/// (project.pbxproj lists it as a membership exception), so the double is
/// declared here instead.
private final class InMemoryKeychain: KeychainServiceProtocol {

    private var store: [String: String] = [:]

    @discardableResult
    func save(key: String, value: String) -> Bool {
        store[key] = value
        return true
    }

    func load(key: String) -> String? {
        store[key]
    }

    @discardableResult
    func delete(key: String) -> Bool {
        store.removeValue(forKey: key)
        return true
    }
}

@Suite("UserAuthService Tests")
@MainActor
struct UserAuthServiceTests {

    private func makeService() -> UserAuthService {
        UserAuthService(config: .default, keychain: InMemoryKeychain())
    }

    // MARK: - Initial state

    @Test("Freshly created service has no tokens and is not authenticating")
    func initialState() async throws {
        let service = makeService()
        #expect(service.accessToken == nil)
        #expect(service.isAuthenticating == false)
        #expect(service.isDemoMode == false)
        #expect(service.currentRefreshToken == nil)
        #expect(service.currentTokenExpiresAt == 0)
    }

    // MARK: - Token freshness

    @Test("isTokenFresh is false when there is no access token")
    func tokenFreshnessWithNoToken() async throws {
        let service = makeService()
        #expect(service.isTokenFresh == false)
    }

    @Test("isTokenFresh is true for a token with no expiry information")
    func tokenFreshnessWithNoExpiry() async throws {
        let service = makeService()
        service.accessToken = "test_access_token"
        #expect(service.currentTokenExpiresAt == 0)
        #expect(service.isTokenFresh == true)
    }

    @Test("ensureFreshToken throws notAuthenticated when there is no access token")
    func ensureFreshTokenThrowsWhenLoggedOut() async throws {
        let service = makeService()
        var caughtNotAuthenticated = false
        do {
            try await service.ensureFreshToken()
        } catch let error as StravaError {
            if case .notAuthenticated = error {
                caughtNotAuthenticated = true
            }
        }
        #expect(caughtNotAuthenticated, "ensureFreshToken() should throw .notAuthenticated when accessToken is nil")
    }

    @Test("ensureFreshToken succeeds without a refresh when the token has no expiry information")
    func ensureFreshTokenPassesWithNoExpiry() async throws {
        let service = makeService()
        service.accessToken = "test_access_token"
        try await service.ensureFreshToken()
        #expect(service.accessToken == "test_access_token")
    }

    // MARK: - Token refresh (pre-network-call branch only)

    @Test("refreshAccessToken fails with tokenExpired when there is no refresh token")
    func refreshFailsWithoutRefreshToken() async throws {
        let service = makeService()
        let refreshed = await service.refreshAccessToken()
        #expect(refreshed == false)

        var isTokenExpired = false
        if let error = service.lastError, case .tokenExpired = error {
            isTokenExpired = true
        }
        #expect(isTokenExpired, "refreshAccessToken() should set lastError to .tokenExpired when refreshToken is nil")
    }

    // MARK: - State restore (cold launch)

    @Test("restoreRefreshToken stores the token for later reads")
    func restoreRefreshTokenStoresValue() async throws {
        let service = makeService()
        service.restoreRefreshToken("test_refresh_token")
        #expect(service.currentRefreshToken == "test_refresh_token")
    }

    @Test("restoreDemoMode flips isDemoMode on")
    func restoreDemoModeSetsFlag() async throws {
        let service = makeService()
        #expect(service.isDemoMode == false)
        service.restoreDemoMode()
        #expect(service.isDemoMode == true)
    }

    // MARK: - handleRedirect (pre-network-call branches only)

    @Test("handleRedirect returns false when the callback carries an error parameter")
    func handleRedirectFailsOnErrorParam() async throws {
        let service = makeService()
        let url = URL(string: "dcc-activities://localhost/oauth/strava?error=access_denied")!
        let result = await service.handleRedirect(url: url)
        #expect(result == false)
        #expect(service.accessToken == nil)
    }

    @Test("handleRedirect returns false when no authorization code is present")
    func handleRedirectFailsWithoutCode() async throws {
        let service = makeService()
        let url = URL(string: "dcc-activities://localhost/oauth/strava")!
        let result = await service.handleRedirect(url: url)
        #expect(result == false)
        #expect(service.accessToken == nil)
    }

    // MARK: - Demo mode

    @Test("fetchAuthenticatedAthlete returns the mock demo profile in demo mode, without a network call")
    func fetchAuthenticatedAthleteReturnsDemoProfileInDemoMode() async throws {
        let service = makeService()
        service.restoreDemoMode()

        let athlete = try await service.fetchAuthenticatedAthlete()

        #expect(athlete.id == 9999999)
        #expect(athlete.firstname == "Demo")
        #expect(athlete.lastname == "Rider")
        #expect(athlete.city == "London")
        #expect(athlete.country == "United Kingdom")
    }
}

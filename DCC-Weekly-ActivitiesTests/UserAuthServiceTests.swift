//
//  UserAuthServiceTests.swift
//  DCC-Weekly-Activities Tests
//
//  Unit tests for UserAuthService (SCRUM-37, AC-1).
//
//  Scope note: UserAuthService's network calls (exchangeCodeViaProxy,
//  refreshAccessToken, the non-demo branch of fetchAuthenticatedAthlete) go
//  through URLSession.shared directly with no injectable session, so they
//  cannot be unit-tested without a live network or a URLProtocol swizzle —
//  neither of which this suite attempts. These tests instead cover every
//  branch that's reachable without a network round-trip: token-freshness
//  logic, state restore/reset, the pre-network-call early-exits in
//  handleRedirect(), and the demo-mode fast path in
//  fetchAuthenticatedAthlete(). AC-1's "successful OAuth flow" and
//  "token refresh" scenarios need a mocked worker response and are not
//  covered here.
//

import Testing
import Foundation
@testable import DCC_Weekly_Activities

@Suite("UserAuthService Tests")
@MainActor
struct UserAuthServiceTests {

    private func makeService() -> UserAuthService {
        UserAuthService(config: .default, keychain: MockKeychainService())
    }

    // MARK: - Initial state

    @Test("Freshly created service has no access token and is not authenticating")
    func initialState() async throws {
        let service = makeService()
        #expect(service.accessToken == nil)
        #expect(service.isAuthenticating == false)
        #expect(service.currentRefreshToken == nil)
        #expect(service.currentTokenExpiresAt == 0)
    }

    // MARK: - Token freshness

    @Test("isTokenFresh is false when there is no access token")
    func tokenFreshnessWithNoToken() async throws {
        let service = makeService()
        #expect(service.isTokenFresh == false)
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

    // MARK: - Logout

    @Test("logout clears access token, refresh token, expiry, and demo mode")
    func logoutClearsAllAuthState() async throws {
        let service = makeService()
        service.restoreRefreshToken("stale_refresh_token")
        service.restoreDemoMode()

        service.logout()

        #expect(service.accessToken == nil)
        #expect(service.currentRefreshToken == nil)
        #expect(service.currentTokenExpiresAt == 0)
        #expect(service.isDemoMode == false)
    }

    // MARK: - handleRedirect (pre-network-call branches only)

    @Test("handleRedirect returns false when the callback carries an error parameter")
    func handleRedirectFailsOnErrorParam() async throws {
        let service = makeService()
        let url = URL(string: "dcc-activities://localhost/oauth/strava?error=access_denied")!
        let result = await service.handleRedirect(url: url)
        #expect(result == false)
    }

    @Test("handleRedirect returns false when no authorization code is present")
    func handleRedirectFailsWithoutCode() async throws {
        let service = makeService()
        let url = URL(string: "dcc-activities://localhost/oauth/strava")!
        let result = await service.handleRedirect(url: url)
        #expect(result == false)
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

// MARK: - KeychainServiceProtocol conformance (SCRUM-37, AC-1 keychain bullet)
//
// UserAuthService only routes token persistence through its injected
// KeychainServiceProtocol on non-iOS builds (tvOS) — on iOS it goes through
// BiometricAuth (a protected file, untouched here). These tests instead
// verify the injected double's own save/load/delete contract, which is what
// UserAuthService actually calls when it does use it.

@Suite("MockKeychainService Tests")
struct MockKeychainServiceTests {

    @Test("save then load round-trips the value")
    func saveThenLoadRoundTrips() async throws {
        let keychain = MockKeychainService()
        #expect(keychain.save(key: "strava_access_token", value: "abc123") == true)
        #expect(keychain.load(key: "strava_access_token") == "abc123")
    }

    @Test("load returns nil for a key that was never saved")
    func loadReturnsNilForMissingKey() async throws {
        let keychain = MockKeychainService()
        #expect(keychain.load(key: "never_saved") == nil)
    }

    @Test("save overwrites a previously stored value for the same key")
    func saveOverwritesExistingValue() async throws {
        let keychain = MockKeychainService()
        keychain.save(key: "strava_refresh_token", value: "first")
        keychain.save(key: "strava_refresh_token", value: "second")
        #expect(keychain.load(key: "strava_refresh_token") == "second")
    }

    @Test("delete removes the value so a later load returns nil")
    func deleteRemovesValue() async throws {
        let keychain = MockKeychainService()
        keychain.save(key: "strava_access_token", value: "abc123")
        #expect(keychain.delete(key: "strava_access_token") == true)
        #expect(keychain.load(key: "strava_access_token") == nil)
    }

    @Test("delete on a key that was never saved still succeeds")
    func deleteOnMissingKeySucceeds() async throws {
        let keychain = MockKeychainService()
        #expect(keychain.delete(key: "never_saved") == true)
    }
}

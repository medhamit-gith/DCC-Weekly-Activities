//
//  BiometricAuth.swift
//  DCC-Weekly-Activities
//
//  Handles Face ID, Touch ID authentication and secure storage
//

import Foundation
import LocalAuthentication
import Observation
import Security

// MARK: - Structured keychain / biometric diagnostic logger
// Filter in Xcode console with "[Keychain]" or "[Biometric]"

enum KeychainLog {
    static func step(_ msg: String) {
        #if DEBUG
        print("🔵 [Keychain] \(msg)")
        #endif
    }
    static func warn(_ msg: String) {
        #if DEBUG
        print("🟡 [Keychain] \(msg)")
        #endif
    }
    static func fail(_ msg: String) {
        #if DEBUG
        print("🔴 [Keychain] \(msg)")
        #endif
    }
}

enum BiometricLog {
    static func step(_ msg: String) {
        #if DEBUG
        print("🔵 [Biometric] \(msg)")
        #endif
    }
    static func warn(_ msg: String) {
        #if DEBUG
        print("🟡 [Biometric] \(msg)")
        #endif
    }
    static func fail(_ msg: String) {
        #if DEBUG
        print("🔴 [Biometric] \(msg)")
        #endif
    }
}

@MainActor
@Observable
final class BiometricAuth {
    static let shared = BiometricAuth()
    private init() {}
    
    var isAuthenticated = false
    var biometricType: BiometricType = .none
    
    enum BiometricType {
        case faceID
        case touchID
        case none
        
        var displayName: String {
            switch self {
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            case .none: return "Passcode"
            }
        }
        
        var icon: String {
            switch self {
            case .faceID: return "faceid"
            case .touchID: return "touchid"
            case .none: return "lock.fill"
            }
        }
    }
    
    // MARK: - Check Biometric Availability
    // FIX: Lazy biometric type checking to prevent XPC entitlement errors
    // Only check when actually needed, not on app launch
    func checkBiometricAvailability() {
        // Defer actual type checking until authentication is needed
        // This prevents XPC errors (501) on app launch
        biometricType = .none  // Default to none, will be determined at auth time
    }
    
    // MARK: - Get Biometric Type (On-Demand)
    // Check biometric type only when needed to avoid XPC errors
    private func determineBiometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        default:
            return .none
        }
    }
    
    // MARK: - Authenticate with Biometrics
    @MainActor
    func authenticate() async -> Bool {
        // ── Simulator fast-path ────────────────────────────────────────────
        // LAContext cannot evaluate biometric policy on Simulator when the
        // demo token path is active. Auto-approve so the dashboard is reachable.
        #if targetEnvironment(simulator)
        if StravaAPI.shared.isDemoMode {
            BiometricLog.step("Simulator demo mode — auto-approving biometric gate")
            biometricType   = .faceID
            isAuthenticated = true
            return true
        }
        #endif
        // ── End Simulator fast-path ────────────────────────────────────────

        biometricType = determineBiometricType()
        BiometricLog.step("authenticate() — biometricType: \(biometricType.displayName)")

        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = 0
        context.localizedCancelTitle = "Use Passcode"

        #if os(tvOS)
        context.localizedReason = "Authenticate to access DCC Weekly Activities"
        #endif

        var canEvalError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &canEvalError) else {
            BiometricLog.warn("Biometrics unavailable — \(canEvalError?.localizedDescription ?? "unknown error") — falling back to passcode")
            context.invalidate()
            return await authenticateWithPasscode()
        }

        BiometricLog.step("Biometrics available — calling evaluatePolicy...")
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock DCC Weekly Activities")
            isAuthenticated = success
            context.invalidate()
            BiometricLog.step("evaluatePolicy result: \(success ? "✅ authenticated" : "❌ denied")")
            return success
        } catch let error {
            context.invalidate()
            if let laError = error as? LAError {
                BiometricLog.warn("LAError \(laError.code.rawValue): \(laError.localizedDescription)")
                switch laError.code {
                case .userCancel, .userFallback:
                    BiometricLog.step("User chose fallback — trying passcode")
                    return await authenticateWithPasscode()
                default:
                    BiometricLog.fail("Biometric failed with non-recoverable LAError")
                    return false
                }
            }
            BiometricLog.fail("Unexpected auth error: \(error)")
            return false
        }
    }
    
    // MARK: - Authenticate with Passcode (Fallback)
    private func authenticateWithPasscode() async -> Bool {
        // CHANGE 2: Create fresh LAContext for passcode auth
        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = 0
        
        do {
            let reason = "Unlock DCC Weekly Activities"
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            
            isAuthenticated = success
            
            // CHANGE 3: Invalidate context after successful use
            context.invalidate()
            
            return success
        } catch {
            AppLogger.error("Passcode authentication failed", error: error)
            BiometricLog.fail("Passcode auth error: \(error.localizedDescription)")
            
            // CHANGE 3: Invalidate context on failure
            context.invalidate()
            
            return false
        }
    }
    
    // MARK: - Save Strava Token Securely
    func saveStravaToken(_ token: String) -> Bool {
        KeychainLog.step("saveStravaToken — token length: \(token.count), first 8: \(token.prefix(8))...")
        let tokenData = Data(token.utf8)

        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrAccount as String:      "strava_access_token",
            kSecAttrService as String:      "com.dcc.weeklyactivities",
            kSecValueData as String:        tokenData,
            kSecAttrAccessible as String:   kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let deleteStatus = SecItemDelete(query as CFDictionary)
        KeychainLog.step("Pre-save delete status: \(deleteStatus) (errSecSuccess=0, errSecItemNotFound=-25300)")

        let addStatus = SecItemAdd(query as CFDictionary, nil)
        if addStatus == errSecSuccess {
            KeychainLog.step("✅ Token saved to keychain")
            return true
        } else {
            KeychainLog.fail("SecItemAdd failed — OSStatus: \(addStatus). Common causes: entitlements missing keychain-access-groups, device locked, or provisioning mismatch")
            return false
        }
    }

    // MARK: - Load Strava Token Securely
    func loadStravaToken() -> String? {
        KeychainLog.step("loadStravaToken — querying keychain")
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrAccount as String:  "strava_access_token",
            kSecAttrService as String:  "com.dcc.weeklyactivities",
            kSecReturnData as String:   true,
            kSecMatchLimit as String:   kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            if let tokenData = result as? Data, let token = String(data: tokenData, encoding: .utf8) {
                KeychainLog.step("✅ Token loaded — length: \(token.count), first 8: \(token.prefix(8))...")
                return token
            } else {
                KeychainLog.fail("SecItemCopyMatching succeeded but data could not be decoded as UTF-8 String")
                return nil
            }
        case errSecItemNotFound:
            KeychainLog.warn("No token in keychain (errSecItemNotFound) — user needs to connect with Strava")
            return nil
        default:
            KeychainLog.fail("SecItemCopyMatching failed — OSStatus: \(status)")
            return nil
        }
    }

    // MARK: - Delete Strava Token
    func deleteStravaToken() -> Bool {
        KeychainLog.step("deleteStravaToken")
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrAccount as String:  "strava_access_token",
            kSecAttrService as String:  "com.dcc.weeklyactivities"
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            KeychainLog.step("✅ Token deleted (or was already absent)")
            return true
        } else {
            KeychainLog.fail("SecItemDelete failed — OSStatus: \(status)")
            return false
        }
    }

    // MARK: - Save Strava Refresh Token Securely
    /// The refresh token is long-lived (6 months) and must survive cold launches.
    /// Without persisting it, refreshAccessToken() always fails after relaunch because
    /// refreshToken is an in-memory-only property that never gets restored.
    @discardableResult
    func saveStravaRefreshToken(_ token: String) -> Bool {
        KeychainLog.step("saveStravaRefreshToken — length: \(token.count)")
        let tokenData = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrAccount as String:      "strava_refresh_token",
            kSecAttrService as String:      "com.dcc.weeklyactivities",
            kSecValueData as String:        tokenData,
            kSecAttrAccessible as String:   kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        _ = SecItemDelete(query as CFDictionary)   // delete any stale entry first
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            KeychainLog.step("✅ Refresh token saved to keychain")
            return true
        } else {
            KeychainLog.fail("saveStravaRefreshToken SecItemAdd failed — OSStatus: \(status)")
            return false
        }
    }

    // MARK: - Load Strava Refresh Token Securely
    func loadStravaRefreshToken() -> String? {
        KeychainLog.step("loadStravaRefreshToken — querying keychain")
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrAccount as String:  "strava_refresh_token",
            kSecAttrService as String:  "com.dcc.weeklyactivities",
            kSecReturnData as String:   true,
            kSecMatchLimit as String:   kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            if let data = result as? Data, let token = String(data: data, encoding: .utf8) {
                KeychainLog.step("✅ Refresh token loaded — length: \(token.count)")
                return token
            }
            KeychainLog.fail("loadStravaRefreshToken — data decoded as nil")
            return nil
        case errSecItemNotFound:
            KeychainLog.warn("No refresh token in keychain — silent refresh will not be possible until next OAuth")
            return nil
        default:
            KeychainLog.fail("loadStravaRefreshToken SecItemCopyMatching failed — OSStatus: \(status)")
            return nil
        }
    }

    // MARK: - Delete Strava Refresh Token
    @discardableResult
    func deleteStravaRefreshToken() -> Bool {
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrAccount as String:  "strava_refresh_token",
            kSecAttrService as String:  "com.dcc.weeklyactivities"
        ]
        let status = SecItemDelete(query as CFDictionary)
        KeychainLog.step("deleteStravaRefreshToken — OSStatus: \(status)")
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Lock (re-require biometric without touching the keychain token)
    /// Drops `isAuthenticated` back to `false` so `RootView` returns to `BiometricGateView`.
    /// Use this when a Strava token expires mid-session — the token stays in keychain so it can
    /// be refreshed after the user re-authenticates. Does NOT delete the token.
    func lock() {
        KeychainLog.step("lock() — setting isAuthenticated = false (token preserved in keychain)")
        isAuthenticated = false
    }

    // MARK: - Logout
    func logout() {
        KeychainLog.step("logout() — clearing isAuthenticated and deleting access + refresh tokens")
        isAuthenticated = false
        _ = deleteStravaToken()
        _ = deleteStravaRefreshToken()
    }
}

//
//  BiometricAuth.swift
//  DCC-Weekly-Activities
//
//  Handles Face ID, Touch ID authentication and secure storage
//

import Foundation
import LocalAuthentication
import Security

@MainActor
class BiometricAuth: ObservableObject {
    static let shared = BiometricAuth()
    private init() {}
    
    @Published var isAuthenticated = false
    @Published var biometricType: BiometricType = .none
    
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
    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .faceID:
                biometricType = .faceID
            case .touchID:
                biometricType = .touchID
            default:
                biometricType = .none
            }
        } else {
            biometricType = .none
        }
    }
    
    // MARK: - Authenticate with Biometrics
    func authenticate() async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Use Passcode"
        
        #if os(tvOS)
        context.localizedReason = "Authenticate to access DCC Weekly Activities"
        #endif
        
        var error: NSError?
        
        // Check if biometrics are available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Fallback to passcode
            return await authenticateWithPasscode()
        }
        
        do {
            let reason = "Unlock DCC Weekly Activities"
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            
            await MainActor.run {
                isAuthenticated = success
            }
            
            return success
        } catch let error {
            print("❌ Biometric authentication failed: \(error.localizedDescription)")
            
            // If user cancels, try passcode
            if let laError = error as? LAError {
                switch laError.code {
                case .userCancel, .userFallback:
                    return await authenticateWithPasscode()
                default:
                    return false
                }
            }
            
            return false
        }
    }
    
    // MARK: - Authenticate with Passcode (Fallback)
    private func authenticateWithPasscode() async -> Bool {
        let context = LAContext()
        
        do {
            let reason = "Unlock DCC Weekly Activities"
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            
            await MainActor.run {
                isAuthenticated = success
            }
            
            return success
        } catch {
            print("❌ Passcode authentication failed: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Save Strava Token Securely
    func saveStravaToken(_ token: String) -> Bool {
        let tokenData = Data(token.utf8)
        
        // Create query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "strava_access_token",
            kSecAttrService as String: "com.dcc.weeklyactivities",
            kSecValueData as String: tokenData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing token
        SecItemDelete(query as CFDictionary)
        
        // Add new token
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("✅ Token saved securely")
            return true
        } else {
            print("❌ Failed to save token: \(status)")
            return false
        }
    }
    
    // MARK: - Load Strava Token Securely
    func loadStravaToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "strava_access_token",
            kSecAttrService as String: "com.dcc.weeklyactivities",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let tokenData = result as? Data,
           let token = String(data: tokenData, encoding: .utf8) {
            print("✅ Token loaded from keychain")
            return token
        } else {
            print("⚠️ No token found in keychain")
            return nil
        }
    }
    
    // MARK: - Delete Strava Token
    func deleteStravaToken() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "strava_access_token",
            kSecAttrService as String: "com.dcc.weeklyactivities"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            print("✅ Token deleted from keychain")
            return true
        } else {
            print("❌ Failed to delete token: \(status)")
            return false
        }
    }
    
    // MARK: - Logout
    func logout() {
        isAuthenticated = false
        _ = deleteStravaToken()
    }
}

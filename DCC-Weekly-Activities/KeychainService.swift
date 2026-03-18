//
//  KeychainService.swift
//  DCC-Weekly-Activities
//
//  Protocol-based keychain abstraction used by UserAuthService.
//  On iOS the token persistence path goes through BiometricAuth (unchanged).
//  On tvOS and in unit tests this concrete implementation is used directly.
//

import Foundation
import Security

// MARK: - Protocol

protocol KeychainServiceProtocol {
    /// Saves (or overwrites) a string value for the given key.
    /// - Returns: `true` if the save succeeded.
    @discardableResult
    func save(key: String, value: String) -> Bool

    /// Loads the string value stored under the given key, or `nil` if absent.
    func load(key: String) -> String?

    /// Deletes the item for the given key.
    /// - Returns: `true` if the item was deleted (or was already absent).
    @discardableResult
    func delete(key: String) -> Bool
}

// MARK: - Concrete Implementation

/// Keychain wrapper using the same service identifier and accessibility level as
/// `BiometricAuth` so tokens written here are readable by the rest of the app.
final class KeychainService: KeychainServiceProtocol {

    static let shared = KeychainService()

    private let service = "com.dcc.weeklyactivities"

    private init() {}

    @discardableResult
    func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Delete any existing item first so SecItemAdd doesn't fail.
        delete(key: key)

        let query: [CFString: Any] = [
            kSecClass:                kSecClassGenericPassword,
            kSecAttrService:          service,
            kSecAttrAccount:          key,
            kSecValueData:            data,
            kSecAttrAccessible:       kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func load(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecAttrAccount:      key,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8)
        else { return nil }
        return string
    }

    @discardableResult
    func delete(key: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass:        kSecClassGenericPassword,
            kSecAttrService:  service,
            kSecAttrAccount:  key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

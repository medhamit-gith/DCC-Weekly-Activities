//
//  MockServices.swift
//  DCC-Weekly-Activities
//
//  Test doubles for UserAuthService dependencies.
//  All types are guarded by #if DEBUG so they are stripped from Release builds.
//

import Foundation

// MARK: - MockKeychainService

#if DEBUG
/// In-memory keychain substitute for unit tests and Xcode Previews.
final class MockKeychainService: KeychainServiceProtocol {

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
#endif

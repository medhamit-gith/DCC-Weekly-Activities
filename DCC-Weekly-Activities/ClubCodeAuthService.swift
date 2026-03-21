//
//  ClubCodeAuthService.swift
//  DCC-Weekly-Activities
//
//  Simple club code authentication — replaces Strava OAuth for Approach A.
//  Members enter a shared club code instead of logging into Strava.
//

import Foundation
import Observation

@MainActor
@Observable
final class ClubCodeAuthService {
    static let shared = ClubCodeAuthService()

    // Valid club access codes — share with DCC members via WhatsApp
    private let validCodes: Set<String> = ["DCC2026", "DESI2026"]

    var isAuthenticated: Bool = false
    var memberName: String = ""
    var errorMessage: String?

    private let codeKey = "dcc_club_code"
    private let nameKey = "dcc_member_name"

    private init() {
        if let savedCode = UserDefaults.standard.string(forKey: codeKey),
           validCodes.contains(savedCode.uppercased()) {
            isAuthenticated = true
            memberName = UserDefaults.standard.string(forKey: nameKey) ?? "DCC Member"
        }
    }

    func authenticate(code: String, name: String) -> Bool {
        let normalised = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard validCodes.contains(normalised) else {
            errorMessage = "Invalid club code. Contact your DCC admin for the correct code."
            return false
        }
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter your name."
            return false
        }
        UserDefaults.standard.set(normalised, forKey: codeKey)
        UserDefaults.standard.set(name.trimmingCharacters(in: .whitespacesAndNewlines), forKey: nameKey)
        isAuthenticated = true
        memberName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        errorMessage = nil
        return true
    }

    func logout() {
        UserDefaults.standard.removeObject(forKey: codeKey)
        UserDefaults.standard.removeObject(forKey: nameKey)
        isAuthenticated = false
        memberName = ""
    }
}

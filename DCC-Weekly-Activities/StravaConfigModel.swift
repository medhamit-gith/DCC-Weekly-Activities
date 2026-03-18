//
//  StravaConfigModel.swift
//  DCC-Weekly-Activities
//
//  Extracted from StravaAPI.swift — all Strava API configuration in one place.
//  The static accessors (StravaConfig.clientID etc.) are preserved for backward
//  compatibility so every existing call-site compiles without change.
//

import Foundation

// MARK: - Strava Configuration

/// Holds Strava API settings.
/// Instance form used for dependency injection / testing.
/// Static accessors kept for backward compatibility with existing call-sites.
struct StravaConfig {
    /// Public client ID — safe to ship in binary.
    let clientID: String
    /// Numeric club ID visible in the club's Strava URL — safe to ship in binary.
    let clubID: String
    /// Cloudflare Worker URL (no trailing slash).
    /// Handles POST /exchange { code, client_id }
    ///         POST /refresh  { refresh_token, client_id }
    let workerURL: String
    /// OAuth redirect URI. Must match "Authorization Callback Domain" in Strava API settings.
    let redirectURI: String
    /// Mobile OAuth endpoint — deep-links into the Strava app if installed.
    let authorizeURL: String

    /// Production singleton with real values.
    static let `default` = StravaConfig(
        clientID:     "161984",
        clubID:       "212760",
        workerURL:    "https://dcc-strava.amit-r-kamat.workers.dev",
        redirectURI:  "dcc-activities://localhost/oauth/strava",
        authorizeURL: "https://www.strava.com/oauth/mobile/authorize"
    )
}

// MARK: - Backward-compatible static accessors
// All existing StravaConfig.clientID / .clubID / .workerURL / .redirectURI / .authorizeURL
// references continue to compile without any change.

extension StravaConfig {
    static let clientID    = StravaConfig.default.clientID
    static let clubID      = StravaConfig.default.clubID
    static let workerURL   = StravaConfig.default.workerURL
    static let redirectURI = StravaConfig.default.redirectURI
    static let authorizeURL = StravaConfig.default.authorizeURL

    /// Full token-exchange URL convenience.
    static var tokenExchangeURL: String { "\(workerURL)/exchange" }
    /// Full token-refresh URL convenience.
    static var tokenRefreshURL:  String { "\(workerURL)/refresh" }
}

//
//  AppNetwork.swift
//  DCC-Weekly-Activities
//
//  One URLSession for the whole app, configured to fail fast.
//
//  Every network call used to go through URLSession.shared, which defaults to a
//  60-second request timeout and a SEVEN DAY resource timeout. The launch
//  sequence issues several requests one after another — token refresh, athlete
//  profile, club data — and the dashboard shows a non-interactive loading
//  screen until they all finish. On a slow, flaky or captive network those
//  60-second waits stack up, and the app appears frozen for minutes with
//  nothing tappable.
//
//  Failing in a few seconds and letting the user retry is far better than an
//  unresponsive screen. These timeouts are deliberately short: every endpoint
//  this app talks to is a small JSON response that should answer well inside
//  them.
//

import Foundation

enum AppNetwork {

    /// Request timeout: how long to wait for the next packet before giving up.
    static let requestTimeout: TimeInterval = 15

    /// Resource timeout: the ceiling for a whole request, retries included.
    static let resourceTimeout: TimeInterval = 30

    /// The session every call in the app should use.
    static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = resourceTimeout
        // Off by default, but set explicitly: when true, a request made with no
        // connection waits for one to appear rather than returning an error the
        // UI can show. That is the opposite of what a launch path needs.
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    /// True when an error means "the network did not answer in time", so the UI
    /// can offer a retry rather than reporting something is broken.
    static func isTimeout(_ error: Error) -> Bool {
        let code = (error as NSError).code
        return code == NSURLErrorTimedOut
            || code == NSURLErrorNetworkConnectionLost
            || code == NSURLErrorNotConnectedToInternet
    }
}

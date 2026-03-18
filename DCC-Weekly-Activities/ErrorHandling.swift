//
//  ErrorHandling.swift
//  DCC-Weekly-Activities
//
//  Centralized error handling for production
//

import Combine
import Foundation
import SwiftUI

// MARK: - App Errors

enum AppError: LocalizedError, Identifiable {
    var id: String { errorDescription ?? "unknown_error" }
    
    // Network errors
    case networkUnavailable
    case requestTimeout
    case serverError(statusCode: Int)
    case invalidResponse
    case rateLimitExceeded
    
    // Authentication errors
    case authenticationFailed
    case tokenExpired
    case invalidCredentials
    case biometricAuthFailed
    case biometricNotAvailable
    
    // Data errors
    case noData
    case invalidData
    case parsingError
    case cacheError
    
    // Strava specific
    case clubNotFound
    case insufficientPermissions
    case stravaAPIError(message: String)
    
    // General
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection available"
        case .requestTimeout:
            return "Request timed out. Please try again"
        case .serverError(let code):
            return "Server error (\(code)). Please try again later"
        case .invalidResponse:
            return "Invalid response from server"
        case .rateLimitExceeded:
            return "Too many requests. Please wait a moment"
            
        case .authenticationFailed:
            return "Authentication failed. Please log in again"
        case .tokenExpired:
            return "Your session has expired. Please log in again"
        case .invalidCredentials:
            return "Invalid credentials"
        case .biometricAuthFailed:
            return "Biometric authentication failed"
        case .biometricNotAvailable:
            return "Biometric authentication is not available"
            
        case .noData:
            return "No data available"
        case .invalidData:
            return "Invalid data received"
        case .parsingError:
            return "Failed to process data"
        case .cacheError:
            return "Failed to load cached data"
            
        case .clubNotFound:
            return "Club not found"
        case .insufficientPermissions:
            return "Insufficient permissions to access club data"
        case .stravaAPIError(let message):
            return "Strava API: \(message)"
            
        case .unknown(let error):
            #if DEBUG
            return "Error: \(error.localizedDescription)"
            #else
            return "An unexpected error occurred"
            #endif
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Please check your internet connection and try again"
        case .requestTimeout:
            return "Make sure you have a stable internet connection"
        case .serverError:
            return "The server is temporarily unavailable. Please try again in a few minutes"
        case .rateLimitExceeded:
            return "You've made too many requests. Please wait 15 minutes before trying again"
        case .authenticationFailed, .tokenExpired:
            return "Please log out and log back in with Strava"
        case .biometricAuthFailed:
            return "Try using your device passcode instead"
        case .biometricNotAvailable:
            return "Enable Face ID or Touch ID in Settings to use this feature"
        case .clubNotFound:
            return "Make sure you're a member of the Desi Cycling Club on Strava"
        case .insufficientPermissions:
            return "Re-authorize the app with Strava to grant necessary permissions"
        default:
            return "Please try again or contact support if the problem persists"
        }
    }
    
    var icon: String {
        switch self {
        case .networkUnavailable, .requestTimeout:
            return "wifi.slash"
        case .serverError, .invalidResponse, .rateLimitExceeded:
            return "exclamationmark.triangle"
        case .authenticationFailed, .tokenExpired, .invalidCredentials:
            return "lock.slash"
        case .biometricAuthFailed, .biometricNotAvailable:
            return "faceid"
        case .noData:
            return "tray"
        case .clubNotFound:
            return "person.3.slash"
        default:
            return "exclamationmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .networkUnavailable, .requestTimeout:
            return .orange
        case .authenticationFailed, .tokenExpired, .biometricAuthFailed:
            return .red
        case .noData:
            return .gray
        default:
            return .red
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let error: AppError
    let retryAction: (() -> Void)?
    
    init(error: AppError, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: error.icon)
                .font(.system(size: 60))
                .foregroundStyle(error.color)
            
            VStack(spacing: 8) {
                Text(error.errorDescription ?? "An error occurred")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal)
            
            if let retry = retryAction {
                Button(action: retry) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.dccSaffron)
            }
        }
        .padding()
    }
}

// MARK: - Error Handler

@MainActor
class ErrorHandler: ObservableObject {
    @Published var currentError: AppError?
    @Published var showError = false
    
    func handle(_ error: Error) {
        if let appError = error as? AppError {
            currentError = appError
        } else if let urlError = error as? URLError {
            currentError = mapURLError(urlError)
        } else {
            currentError = .unknown(error)
        }
        
        showError = true
        AppLogger.error("Error occurred: \(error.localizedDescription)", error: error)
    }
    
    func clearError() {
        currentError = nil
        showError = false
    }
    
    private func mapURLError(_ error: URLError) -> AppError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkUnavailable
        case .timedOut:
            return .requestTimeout
        case .badServerResponse:
            return .invalidResponse
        default:
            return .unknown(error)
        }
    }
}

// MARK: - View Extension for Error Handling

extension View {
    func errorAlert(errorHandler: ErrorHandler, retryAction: (() -> Void)? = nil) -> some View {
        alert(
            "Error",
            isPresented: Binding(
                get: { errorHandler.showError },
                set: { errorHandler.showError = $0 }
            ),
            presenting: errorHandler.currentError
        ) { error in
            if let retry = retryAction {
                Button("Try Again") {
                    retry()
                    errorHandler.clearError()
                }
            }
            Button("OK") {
                errorHandler.clearError()
            }
        } message: { error in
            VStack {
                if let description = error.errorDescription {
                    Text(description)
                }
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                }
            }
        }
    }
}

// MARK: - Result Extension

extension Result {
    func mapError(to appError: AppError) -> Result<Success, AppError> {
        switch self {
        case .success(let value):
            return .success(value)
        case .failure:
            return .failure(appError)
        }
    }
}

#Preview("Network Error") {
    ErrorView(
        error: .networkUnavailable,
        retryAction: {
            #if DEBUG
            print("Retry tapped")
            #endif
        }
    )
}

#Preview("Authentication Error") {
    ErrorView(
        error: .authenticationFailed,
        retryAction: nil
    )
}

#Preview("No Data") {
    ErrorView(
        error: .noData,
        retryAction: {
            #if DEBUG
            print("Retry tapped")
            #endif
        }
    )
}

//
//  GlassComponents.swift
//  DCC-Weekly-Activities
//
//  Reusable Liquid Glass components for the app
//

import SwiftUI

// MARK: - Glass Member Stats Card
struct GlassMemberCard: View {
    let member: MemberStats
    
    var body: some View {
        HStack(spacing: 16) {
            // Member info
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 12) {
                    Label("\(member.count)", systemImage: "figure.run")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if member.averageSpeed > 0 {
                        Label(member.formattedAverageSpeed, systemImage: "speedometer")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Distance (prominent)
            VStack(alignment: .trailing, spacing: 2) {
                Text(member.formattedDistance)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.dccSaffron)
                
                Text("km")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .glassEffect(
            .regular.tint(Color.dccSaffron.opacity(0.08)),
            in: .rect(cornerRadius: 16)
        )
    }
}

// MARK: - Glass Activity Row
struct GlassActivityRow: View {
    let activity: ClubActivity
    
    var body: some View {
        HStack(spacing: 12) {
            // Activity icon
            Image(systemName: activityIcon)
                .font(.title2)
                .foregroundStyle(Color.dccGreen)
                .frame(width: 40, height: 40)
                .background(Color.dccGreen.opacity(0.1))
                .clipShape(Circle())
            
            // Activity details
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.activityName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(activity.memberName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Distance and date
            VStack(alignment: .trailing, spacing: 4) {
                Text(activity.formattedDistance)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.dccSaffron)
                
                Text(activity.formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .glassEffect(
            .regular.tint(Color.dccGreen.opacity(0.05)),
            in: .rect(cornerRadius: 12)
        )
    }
    
    private var activityIcon: String {
        switch activity.type.lowercased() {
        case "ride":
            return "bicycle"
        case "run":
            return "figure.run"
        case "walk":
            return "figure.walk"
        case "swim":
            return "figure.pool.swim"
        default:
            return "figure.mixed.cardio"
        }
    }
}

// MARK: - Glass Summary Card
struct GlassSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(
            .regular.tint(color.opacity(0.1)),
            in: .rect(cornerRadius: 14)
        )
    }
}

// MARK: - Glass Button Style (Custom)
struct DCCGlassButtonStyle: ButtonStyle {
    let tintColor: Color
    let isProminent: Bool
    
    init(tintColor: Color = .orange, isProminent: Bool = false) {
        self.tintColor = tintColor
        self.isProminent = isProminent
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isProminent {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(tintColor.opacity(0.15))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.clear)
                    }
                }
            )
            .glassEffect(
                .regular.tint(tintColor.opacity(isProminent ? 0.2 : 0.1)).interactive(),
                in: .rect(cornerRadius: 12)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Extension for easy button styling
extension ButtonStyle where Self == DCCGlassButtonStyle {
    static var dccGlass: DCCGlassButtonStyle {
        DCCGlassButtonStyle()
    }
    
    static func dccGlass(tintColor: Color, isProminent: Bool = false) -> DCCGlassButtonStyle {
        DCCGlassButtonStyle(tintColor: tintColor, isProminent: isProminent)
    }
}

// MARK: - Glass Error View
struct GlassErrorView: View {
    let error: String
    let isAuthError: Bool
    let onRetry: () -> Void
    let onLogInAgain: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.dccSaffron)
            
            VStack(spacing: 8) {
                Text("Oops!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if isAuthError {
                Button("Log In Again") {
                    onLogInAgain()
                }
                .buttonStyle(.dccGlass(tintColor: Color.dccSaffron, isProminent: true))
            } else {
                Button("Try Again") {
                    onRetry()
                }
                .buttonStyle(.dccGlass(tintColor: Color.dccSaffron, isProminent: true))
            }
        }
        .padding(32)
        .glassEffect(
            .regular.tint(.orange.opacity(0.05)),
            in: .rect(cornerRadius: 24)
        )
    }
}

// MARK: - Glass Loading View
struct GlassLoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color.dccSaffron)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .glassEffect(
            .regular.tint(.white.opacity(0.05)),
            in: .rect(cornerRadius: 20)
        )
    }
}

// MARK: - Glass Welcome Card (for login screen)
struct GlassWelcomeCard: View {
    let onConnect: () -> Void
    let biometricType: BiometricAuth.BiometricType
    
    var body: some View {
        VStack(spacing: 24) {
            // Logo/Icon area
            VStack(spacing: 12) {
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.dccSaffron, Color.dccGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("DCC Weekly Activities")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Track your club's running achievements")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Connect button
            Button(action: onConnect) {
                HStack {
                    Image(systemName: "person.fill")
                    Text("Connect with Strava")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.dccGlass(tintColor: Color.dccSaffron, isProminent: true))
            
            // Biometric info
            if biometricType != .none {
                HStack(spacing: 8) {
                    Image(systemName: biometricType.icon)
                        .foregroundStyle(Color.dccGreen)
                    Text("Secured with \(biometricType.displayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .glassEffect(
                    .regular.tint(Color.dccGreen.opacity(0.05)),
                    in: .rect(cornerRadius: 20)
                )
            }
        }
        .padding(32)
        .glassEffect(
            .regular.tint(.white.opacity(0.08)),
            in: .rect(cornerRadius: 24)
        )
    }
}

// MARK: - Glass Toolbar Background
struct GlassToolbarBackground: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .glassEffect(.regular.tint(.white.opacity(0.02)))
            .ignoresSafeArea(edges: .top)
    }
}

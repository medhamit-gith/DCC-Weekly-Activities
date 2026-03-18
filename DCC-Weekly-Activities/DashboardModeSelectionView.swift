//
//  DashboardModeSelectionView.swift
//  DCC-Weekly-Activities
//
//  Dashboard mode selection screen - appears after authentication
//

import SwiftUI

struct DashboardModeSelectionView: View {
    let athleteProfile: AthleteProfile
    let onModeSelected: (DashboardMode) -> Void
    
    @State private var selectedMode: DashboardMode?
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.dccBlue.opacity(0.15), Color.dccSaffron.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "figure.cycling")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.dccSaffron, Color.dccGreen],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Welcome, \(athleteProfile.firstname)!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Choose your dashboard view")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Mode selection cards
                    VStack(spacing: 20) {
                        ForEach([DashboardMode.justMyStats, .meVsTop3, .worstPerformer]) { mode in
                            ModeCard(
                                mode: mode,
                                isSelected: selectedMode == mode
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedMode = mode
                                }
                                // Delay navigation slightly for animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    onModeSelected(mode)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Mode Card

struct ModeCard: View {
    let mode: DashboardMode
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: mode.icon)
                .font(.system(size: 32))
                .foregroundStyle(mode.color)
                .frame(width: 60, height: 60)
                .background(mode.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Text content
            VStack(alignment: .leading, spacing: 6) {
                Text(mode.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(mode.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .imageScale(.small)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(
            color: isSelected ? mode.color.opacity(0.3) : .black.opacity(0.1),
            radius: isSelected ? 12 : 8,
            x: 0,
            y: isSelected ? 6 : 4
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
    }
}

// MARK: - Preview

#Preview {
    DashboardModeSelectionView(
        athleteProfile: AthleteProfile(
            id: 12345,
            firstname: "John",
            lastname: "Doe",
            profile: nil,
            city: "Delhi",
            state: nil,
            country: "India"
        ),
        onModeSelected: { mode in
            #if DEBUG
            print("Selected: \(mode.rawValue)")
            #endif
        }
    )
}

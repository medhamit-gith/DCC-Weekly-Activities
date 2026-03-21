//
//  LaunchAnimationView.swift
//  DCC-Weekly-Activities
//  Created on 2026-03-05
//

import SwiftUI

struct LaunchAnimationView: View {
    @State private var textScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background gradient matching app theme
            LinearGradient(
                colors: [Color.blue.opacity(0.15), Color.orange.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated cyclist with India flag streaks
            AnimatedCyclistView(size: 80, showFlag: true, loop: true)
            
            // DCC Weekly text with pulse
            VStack(spacing: 12) {
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "figure.outdoor.cycle")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.orange)
                        .accessibilityHidden(true)
                    
                    Text("DCC Weekly")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary)
                }
                .scaleEffect(textScale)
                
                Text("Track your cycling achievements")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                    .frame(height: 100)
            }
        }
        .onAppear {
            startTextAnimation()
        }
    }
    
    private func startTextAnimation() {
        // Text pulse animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5).repeatForever(autoreverses: true)) {
            textScale = 1.05
        }
    }
}

#Preview {
    LaunchAnimationView()
}

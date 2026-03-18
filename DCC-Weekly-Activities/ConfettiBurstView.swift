//
//  ConfettiBurstView.swift
//  DCC-Weekly-Activities
//
//  60-particle celebration effect using pure SwiftUI
//

import SwiftUI

struct ConfettiBurstView: View {
    let trigger: Bool
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                
                for particle in particles {
                    let progress = min(1.0, (now - particle.createdAt) / particle.lifetime)
                    
                    if progress < 1.0 {
                        var particleContext = context
                        let currentX = particle.startX + particle.velocityX * progress
                        let currentY = particle.startY + particle.velocityY * progress - (particle.gravity * progress * progress * 200)
                        
                        let scale = particle.startScale * (1.0 - progress * 0.5)
                        let rotation = Angle(degrees: particle.rotationSpeed * progress * 360)
                        let opacity = 1.0 - (progress * progress)
                        
                        particleContext.opacity = opacity
                        particleContext.translateBy(x: currentX, y: currentY)
                        particleContext.rotate(by: rotation)
                        particleContext.scaleBy(x: scale, y: scale)
                        
                        let rect = CGRect(x: -particle.size/2, y: -particle.size/2, width: particle.size, height: particle.size)
                        particleContext.fill(Circle().path(in: rect), with: .color(particle.color))
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, newValue in
            if newValue {
                createBurst()
            }
        }
    }
    
    private func createBurst() {
        let colors: [Color] = [
            .accent,
            .accentSecondary,
            .dccSaffron,
            .dccGreen,
            .success
        ]
        
        particles = (0..<60).map { index in
            let angle = (Double(index) / 60.0) * 2 * .pi
            let speed = Double.random(in: 150...300)
            let spiralOffset = Double(index % 6) * 0.3
            
            return ConfettiParticle(
                startX: 0,
                startY: 0,
                velocityX: cos(angle + spiralOffset) * speed,
                velocityY: sin(angle + spiralOffset) * speed,
                gravity: Double.random(in: 0.8...1.5),
                size: CGFloat.random(in: 4...12),
                color: colors.randomElement() ?? .accent,
                rotationSpeed: Double.random(in: -3...3),
                startScale: 1.0,
                lifetime: Double.random(in: 0.4...0.8),
                createdAt: Date.timeIntervalSinceReferenceDate
            )
        }
        
        // Clear particles after max lifetime
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            particles.removeAll()
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let startY: CGFloat
    let velocityX: CGFloat
    let velocityY: CGFloat
    let gravity: CGFloat
    let size: CGFloat
    let color: Color
    let rotationSpeed: Double
    let startScale: Double
    let lifetime: TimeInterval
    let createdAt: TimeInterval
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        ConfettiBurstView(trigger: true)
    }
}

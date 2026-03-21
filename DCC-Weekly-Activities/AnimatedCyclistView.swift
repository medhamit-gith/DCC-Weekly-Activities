//
//  AnimatedCyclistView.swift
//  DCC-Weekly-Activities
//
//  Reusable animated cyclist with India flag color streaks
//  Created on 2026-03-05
//

import SwiftUI

struct AnimatedCyclistView: View {
    let size: CGFloat
    let showFlag: Bool
    let loop: Bool
    
    @State private var containerWidth: CGFloat = 400 // updated by GeometryReader on appear
    @State private var cyclistOffset: CGFloat = -200
    @State private var saffronScale: CGFloat = 0
    @State private var whiteScale: CGFloat = 0
    @State private var greenScale: CGFloat = 0
    @State private var saffronOpacity: Double = 0
    @State private var whiteOpacity: Double = 0
    @State private var greenOpacity: Double = 0
    
    init(size: CGFloat = 44, showFlag: Bool = true, loop: Bool = true) {
        self.size = size
        self.showFlag = showFlag
        self.loop = loop
    }
    
    var body: some View {
        ZStack {
            if showFlag {
                // India flag trail streaks
                VStack(spacing: size * 0.133) { // Proportional spacing (8/60 = 0.133)
                    // Saffron streak
                    RoundedRectangle(cornerRadius: size * 0.067) // Proportional corner radius (4/60)
                        .fill(Color.orange)
                        .frame(height: size * 0.1) // Proportional height (6/60 = 0.1)
                        .scaleEffect(x: saffronScale, y: 1.0, anchor: .leading)
                        .opacity(saffronOpacity)
                    
                    // White streak
                    RoundedRectangle(cornerRadius: size * 0.067)
                        .fill(Color.white)
                        .frame(height: size * 0.1)
                        .scaleEffect(x: whiteScale, y: 1.0, anchor: .leading)
                        .opacity(whiteOpacity)
                    
                    // Green streak
                    RoundedRectangle(cornerRadius: size * 0.067)
                        .fill(Color.green)
                        .frame(height: size * 0.1)
                        .scaleEffect(x: greenScale, y: 1.0, anchor: .leading)
                        .opacity(greenOpacity)
                }
                .frame(width: size * 5) // Proportional width (300/60 = 5)
                .offset(x: cyclistOffset - size * 1.333) // Proportional offset (80/60 = 1.333)
            }
            
            // Animated cyclist
            Image(systemName: "figure.outdoor.cycle")
                .font(.system(size: size))
                .foregroundStyle(Color.blue)
                .offset(x: cyclistOffset)
        }
        .background(
            GeometryReader { geo in
                Color.clear.onAppear { containerWidth = geo.size.width }
            }
        )
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Cyclist animation - moves left to right.
        // Uses containerWidth captured via GeometryReader instead of UIScreen.main
        // to avoid the unsafeForcedSync Swift Concurrency warning.
        let animation: Animation = loop 
            ? .linear(duration: 1.5).repeatForever(autoreverses: false)
            : .linear(duration: 1.5)
        
        withAnimation(animation) {
            cyclistOffset = containerWidth + 200
        }
        
        // Flag trail animations only if showFlag is true
        if showFlag {
            animateStreaks()
        }
    }
    
    private func animateStreaks() {
        let streakDelay = 0.3
        
        if loop {
            // Looping animations with Timer
            // Saffron (top) - animates first
            Timer.scheduledTimer(withTimeInterval: streakDelay, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.8)) {
                    saffronScale = 3.0
                    saffronOpacity = 0.8
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        saffronScale = 0
                        saffronOpacity = 0
                    }
                }
            }
            
            // White (middle) - slightly delayed
            Timer.scheduledTimer(withTimeInterval: streakDelay + 0.05, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.8)) {
                    whiteScale = 3.0
                    whiteOpacity = 0.8
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        whiteScale = 0
                        whiteOpacity = 0
                    }
                }
            }
            
            // Green (bottom) - most delayed
            Timer.scheduledTimer(withTimeInterval: streakDelay + 0.1, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.8)) {
                    greenScale = 3.0
                    greenOpacity = 0.8
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        greenScale = 0
                        greenOpacity = 0
                    }
                }
            }
        } else {
            // Single-shot animations
            DispatchQueue.main.asyncAfter(deadline: .now() + streakDelay) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    saffronScale = 3.0
                    saffronOpacity = 0.8
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        saffronScale = 0
                        saffronOpacity = 0
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + streakDelay + 0.05) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    whiteScale = 3.0
                    whiteOpacity = 0.8
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        whiteScale = 0
                        whiteOpacity = 0
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + streakDelay + 0.1) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    greenScale = 3.0
                    greenOpacity = 0.8
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        greenScale = 0
                        greenOpacity = 0
                    }
                }
            }
        }
    }
}

#Preview("Default - Looping with Flag") {
    ZStack {
        Color.black.ignoresSafeArea()
        AnimatedCyclistView()
    }
}

#Preview("Large - Looping with Flag") {
    ZStack {
        Color.black.ignoresSafeArea()
        AnimatedCyclistView(size: 80, showFlag: true, loop: true)
    }
}

#Preview("No Flag - Looping") {
    ZStack {
        Color.black.ignoresSafeArea()
        AnimatedCyclistView(size: 60, showFlag: false, loop: true)
    }
}

#Preview("Single Shot") {
    ZStack {
        Color.black.ignoresSafeArea()
        AnimatedCyclistView(size: 60, showFlag: true, loop: false)
    }
}

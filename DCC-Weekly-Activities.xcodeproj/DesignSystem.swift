//
//  DesignSystem.swift
//  DCC-Weekly-Activities
//
//  Professional design system for dark-first sports app UI
//  Inspired by Strava, Apple Fitness, and Whoop
//

import SwiftUI

// MARK: - Color System

extension Color {
    // MARK: Backgrounds
    static let appBackground = Color(hex: "#0D0D0D")      // Near black
    static let surface = Color(hex: "#1A1A1A")            // Card background
    static let surfaceElevated = Color(hex: "#242424")    // Elevated cards
    
    // MARK: Strava Orange Accent (Primary)
    static let accent = Color(hex: "#FC4C02")             // Strava orange
    static let accentSecondary = Color(hex: "#FF8C42")    // Lighter orange
    
    // MARK: DCC Club Colors (Secondary - keep for brand)
    static let dccBlue = Color(hex: "#1E90FF")            // Club blue
    static let dccSaffron = Color(hex: "#FF9933")         // India saffron
    static let dccGreen = Color(hex: "#138808")           // India green
    
    // MARK: Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#8E8E93")
    static let textTertiary = Color(hex: "#636366")
    
    // MARK: Semantic Colors
    static let success = Color(hex: "#34C759")
    static let warning = Color(hex: "#FF9F0A")
    static let error = Color(hex: "#FF3B30")
    
    // MARK: Podium Gradients
    static func goldGradient() -> LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#FFD700"), Color(hex: "#FFA500")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static func silverGradient() -> LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#C0C0C0"), Color(hex: "#808080")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static func bronzeGradient() -> LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#CD7F32"), Color(hex: "#8B4513")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: Helper
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography System

extension Font {
    // MARK: Display (Stats/Heroes)
    static let heroStat = Font.system(size: 56, weight: .black, design: .rounded)
    static let largeStat = Font.system(size: 48, weight: .black, design: .rounded)
    static let mediumStat = Font.system(size: 32, weight: .bold, design: .rounded)
    static let smallStat = Font.system(size: 24, weight: .bold, design: .rounded)
    
    // MARK: Headers
    static let sectionTitle = Font.system(size: 22, weight: .bold, design: .default)
    static let cardTitle = Font.system(size: 18, weight: .semibold, design: .default)
    static let subtitle = Font.system(size: 16, weight: .medium, design: .default)
    
    // MARK: Body
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyDefault = Font.system(size: 15, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)
    
    // MARK: Labels
    static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    static let labelDefault = Font.system(size: 12, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 10, weight: .medium, design: .default)
    
    // MARK: Captions
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let captionMedium = Font.system(size: 12, weight: .medium, design: .default)
    static let captionSmall = Font.system(size: 10, weight: .regular, design: .default)
}

// MARK: - Spacing System

enum Spacing {
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

// MARK: - Corner Radius

enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let full: CGFloat = 999
}

// MARK: - Shadow Styles

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    static let soft = ShadowStyle(
        color: .black.opacity(0.1),
        radius: 8,
        x: 0,
        y: 2
    )
    
    static let medium = ShadowStyle(
        color: .black.opacity(0.2),
        radius: 12,
        x: 0,
        y: 4
    )
    
    static let heavy = ShadowStyle(
        color: .black.opacity(0.3),
        radius: 20,
        x: 0,
        y: 8
    )
    
    static let glow = ShadowStyle(
        color: Color.accent.opacity(0.5),
        radius: 16,
        x: 0,
        y: 0
    )
}

// MARK: - View Modifiers

extension View {
    /// Apply consistent card styling
    func cardStyle(
        backgroundColor: Color = .surface,
        cornerRadius: CGFloat = CornerRadius.xl,
        padding: CGFloat = Spacing.md
    ) -> some View {
        self
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
    }
    
    /// Apply glass morphism effect
    func glassCardStyle(cornerRadius: CGFloat = CornerRadius.xl) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
    }
    
    /// Apply shadow
    func shadowStyle(_ style: ShadowStyle) -> some View {
        self.shadow(
            color: style.color,
            radius: style.radius,
            x: style.x,
            y: style.y
        )
    }
    
    /// Tap scale effect for interactions
    func tappableScale() -> some View {
        self.scaleEffect(0.96)
    }
    
    /// Shimmer loading effect
    func shimmer(isActive: Bool = true) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isActive {
                        LinearGradient(
                            colors: [
                                .clear,
                                Color.white.opacity(0.3),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
                        .onAppear {
                            withAnimation(
                                .linear(duration: 1.5)
                                .repeatForever(autoreverses: false)
                            ) {
                                phase = 1
                            }
                        }
                    }
                }
            )
            .clipped()
    }
}

// MARK: - Number Formatting

extension Double {
    /// Format as distance with 1 decimal
    var asDistance: String {
        String(format: "%.1f", self)
    }
    
    /// Format as elevation (no decimals)
    var asElevation: String {
        String(format: "%.0f", self)
    }
    
    /// Format as speed with 1 decimal
    var asSpeed: String {
        String(format: "%.1f", self)
    }
    
    /// Format as percentage with 1 decimal
    var asPercentage: String {
        String(format: "%.1f%%", self)
    }
}

extension Int {
    /// Format with thousands separator
    var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

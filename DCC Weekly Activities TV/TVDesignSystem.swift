//
//  TVDesignSystem.swift
//  DCC Weekly Activities TV
//
//  Premium design tokens for the tvOS app.
//  Implements the DCC Weekly UX spec:
//  — Dark-first palette (#0A0A0B background, Strava orange accent)
//  — French tricolor cultural identity (blue/white/red)
//  — Typography: SF Pro + SF Mono (system fonts) for 10-foot legibility
//  — Focus: scale + glow + border animation
//  — tvOS safe zone: 90pt margins
//

import SwiftUI

// MARK: - Typography

/// All sizes validated for 10-foot viewing distance.
/// Apple HIG minimum: 31pt for supplementary labels, 36pt+ for body.
struct TVFont {
    // Display — hero headlines
    static func heroTitle() -> Font {
        .system(size: 76, weight: .light, design: .default)
    }
    static func screenTitle() -> Font {
        .system(size: 52, weight: .semibold, design: .rounded)
    }
    static func sectionHeader() -> Font {
        .system(size: 44, weight: .bold, design: .default)
    }

    // Data — stats and values
    static func heroStat() -> Font {
        .system(size: 72, weight: .bold, design: .rounded)
    }
    static func statValue() -> Font {
        .system(size: 44, weight: .semibold, design: .default)
    }
    static func cardHeadline() -> Font {
        .system(size: 36, weight: .medium, design: .default)
    }
    static func bodyData() -> Font {
        .system(size: 32, weight: .regular, design: .default)
    }

    // Labels — supplementary (min 31pt per HIG)
    static func dataLabel() -> Font {
        .system(size: 24, weight: .medium, design: .monospaced)
    }
    static func caption() -> Font {
        .system(size: 22, weight: .regular, design: .monospaced)
    }
    static func rankNumber() -> Font {
        .system(size: 56, weight: .black, design: .rounded)
    }
    static func rankSmall() -> Font {
        .system(size: 32, weight: .bold, design: .rounded)
    }
    static func monoSmall() -> Font {
        .system(size: 20, weight: .regular, design: .monospaced)
    }
}

// MARK: - Layout

struct TVLayout {
    static let screenMargin: CGFloat     = 90    // Apple tvOS safe zone
    static let cardPadding: CGFloat      = 36
    static let cardGap: CGFloat          = 24
    static let sectionGap: CGFloat       = 56
    static let rowHeight: CGFloat        = 100
    static let cardCornerRadius: CGFloat = 16
    static let focusedScale: CGFloat     = 1.06
    static let headerHeight: CGFloat     = 96
}

// MARK: - Colors

extension Color {
    // Backgrounds
    static let tvBackground      = Color(red: 0.039, green: 0.039, blue: 0.043)  // #0A0A0B
    static let tvSurface         = Color(red: 0.067, green: 0.067, blue: 0.071)  // #111114
    static let tvCard            = Color(red: 0.094, green: 0.094, blue: 0.102)  // #18181A
    static let tvCardFocused     = Color(red: 0.137, green: 0.137, blue: 0.149)  // focused surface

    // Accent — Strava orange (primary brand color)
    static let tvAccent          = Color(red: 0.988, green: 0.298, blue: 0.008)  // #FC4C02
    static let tvAccentDim       = Color(red: 0.988, green: 0.298, blue: 0.008).opacity(0.14)
    static let tvAccentGlow      = Color(red: 0.988, green: 0.298, blue: 0.008).opacity(0.35)

    // French tricolor cultural identity
    static let tvFrenchBlue      = Color(red: 0.0,   green: 0.137, blue: 0.584)  // #002395
    static let tvFrenchRed       = Color(red: 0.929, green: 0.161, blue: 0.224)  // #ED2939

    // Semantic colors
    static let tvGold            = Color(red: 1.0,   green: 0.839, blue: 0.0)    // #FFD700
    static let tvSilver          = Color(red: 0.749, green: 0.749, blue: 0.749)
    static let tvBronze          = Color(red: 0.804, green: 0.498, blue: 0.196)
    static let tvGreen           = Color(red: 0.204, green: 0.780, blue: 0.349)  // #34C759
    static let tvRed             = Color(red: 1.0,   green: 0.271, blue: 0.227)  // #FF453A
    static let tvBlue            = Color(red: 0.290, green: 0.620, blue: 1.0)    // #4A9EFF
    static let tvSaffron         = Color(red: 0.984, green: 0.737, blue: 0.059)  // #FBC00F

    // Text hierarchy
    static let tvTextPrimary     = Color.white
    static let tvTextSecondary   = Color.white.opacity(0.60)
    static let tvTextTertiary    = Color.white.opacity(0.35)

    // Structural
    static let tvDivider         = Color.white.opacity(0.07)
    static let tvDividerAccent   = Color.white.opacity(0.14)
}

// MARK: - Focus card modifier

/// Applies scale, glow shadow, and border when focused.
/// Focus-in: 120ms easeOut. Focus-out: 350ms easeOut (per spec).
struct TVFocusCardModifier: ViewModifier {
    let isFocused: Bool
    let baseColor: Color
    let accentColor: Color

    init(isFocused: Bool, baseColor: Color = .tvCard, accentColor: Color = .tvAccent) {
        self.isFocused = isFocused
        self.baseColor = baseColor
        self.accentColor = accentColor
    }

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: TVLayout.cardCornerRadius)
                    .fill(isFocused ? Color.tvCardFocused : baseColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TVLayout.cardCornerRadius)
                    .strokeBorder(
                        isFocused ? accentColor.opacity(0.55) : Color.tvDivider,
                        lineWidth: isFocused ? 2 : 1
                    )
            )
            .shadow(
                color: isFocused ? accentColor.opacity(0.28) : .black.opacity(0.35),
                radius: isFocused ? 24 : 8,
                y: isFocused ? 10 : 3
            )
            .scaleEffect(isFocused ? TVLayout.focusedScale : 1.0)
            .animation(
                isFocused
                    ? .easeOut(duration: 0.12)
                    : .easeOut(duration: 0.35),
                value: isFocused
            )
    }
}

extension View {
    func tvFocusCard(
        isFocused: Bool,
        baseColor: Color = .tvCard,
        accentColor: Color = .tvAccent
    ) -> some View {
        modifier(TVFocusCardModifier(isFocused: isFocused, baseColor: baseColor, accentColor: accentColor))
    }
}

// MARK: - Rank color helper

func tvRankColor(_ rank: Int) -> Color {
    switch rank {
    case 1:  return .tvGold
    case 2:  return .tvSilver
    case 3:  return .tvBronze
    default: return .tvTextSecondary
    }
}

// MARK: - French Tricolor Bar

/// 3mm accent bar in French national colors — applied at top of header.
struct TricolorBar: View {
    var body: some View {
        HStack(spacing: 0) {
            Color.tvFrenchBlue
            Color.white.opacity(0.9)
            Color.tvFrenchRed
        }
        .frame(height: 3)
    }
}

// MARK: - Strava-branded pill badge

struct StravaAccentPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(TVFont.monoSmall())
            .tracking(1.5)
            .foregroundStyle(Color.tvAccent)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.tvAccent.opacity(0.12))
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.tvAccent.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Ambient background orbs

/// Decorative blur orbs — Strava orange bottom-center, blue top-right.
struct TVAmbientBackground: View {
    var body: some View {
        ZStack {
            Color.tvBackground

            GeometryReader { geo in
                ZStack {
                    // Strava orange — bottom center glow
                    Circle()
                        .fill(Color.tvAccent.opacity(0.055))
                        .frame(width: 700, height: 700)
                        .blur(radius: 140)
                        .position(x: geo.size.width * 0.5, y: geo.size.height * 0.95)

                    // Blue — top left
                    Circle()
                        .fill(Color.tvBlue.opacity(0.040))
                        .frame(width: 500, height: 500)
                        .blur(radius: 120)
                        .position(x: 0, y: 0)

                    // Subtle purple — bottom right
                    Circle()
                        .fill(Color.tvFrenchBlue.opacity(0.03))
                        .frame(width: 400, height: 400)
                        .blur(radius: 100)
                        .position(x: geo.size.width, y: geo.size.height)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Section header label

struct TVSectionLabel: View {
    let eyebrow: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow)
                .font(TVFont.caption())
                .tracking(3)
                .foregroundStyle(Color.tvAccent)
            Text(title)
                .font(TVFont.sectionHeader())
                .foregroundStyle(Color.tvTextPrimary)
        }
    }
}

// MARK: - Animated number counter

/// Counts from 0 to target value when animate changes to true.
struct AnimatedNumber: View {
    let target: Double
    let format: String
    let font: Font
    let color: Color

    @State private var displayed: Double = 0

    var body: some View {
        Text(String(format: format, displayed))
            .font(font)
            .foregroundStyle(color)
            .monospacedDigit()
            .contentTransition(.numericText())
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    displayed = target
                }
            }
            .onChange(of: target) { _, newVal in
                displayed = 0
                withAnimation(.easeOut(duration: 0.6)) {
                    displayed = newVal
                }
            }
    }
}

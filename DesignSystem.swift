// DesignSystem.swift
// DCC-Weekly-Activities
//
// Single source of truth for all visual design tokens.
// Every screen in the app must reference ONLY these values.
// Do not hardcode any spacing, font size, corner radius, or color anywhere else.

import SwiftUI

// MARK: - Color Tokens
extension Color {
    // Brand — one primary accent. Use sparingly.
    static let dccAccent   = Color(red: 1.0, green: 0.6,  blue: 0.2)  // Saffron orange
    static let dccGreenAccent = Color(red: 0.13, green: 0.55, blue: 0.13) // Muted forest green

    // Semantic backgrounds — always use iOS system colors so Dark Mode is free.
    static let appBackground          = Color(.systemBackground)
    static let cardBackground         = Color(.secondarySystemBackground)
    static let raisedCardBackground   = Color(.tertiarySystemBackground)

    // Text — semantic so they invert automatically in Dark Mode.
    static let labelPrimary           = Color(.label)
    static let labelSecondary         = Color(.secondaryLabel)
    static let labelTertiary          = Color(.tertiaryLabel)

    // Ranking — only used for podium positions.
    static let rankGold   = Color(red: 1.0,  green: 0.84, blue: 0.0)
    static let rankSilver = Color(red: 0.75, green: 0.75, blue: 0.75)
    static let rankBronze = Color(red: 0.80, green: 0.50, blue: 0.20)

    // Status
    static let statusUp     = Color(.systemGreen)
    static let statusDown   = Color(.systemOrange)
    static let statusStable = Color(.systemGray)
    static let statusNew    = Color(.systemBlue)
}

// MARK: - Spacing Tokens (4pt grid)
enum DS {
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs:  CGFloat = 8
        static let sm:  CGFloat = 12
        static let md:  CGFloat = 16   // Default horizontal inset
        static let lg:  CGFloat = 24   // Between sections
        static let xl:  CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius Tokens
    enum Radius {
        static let sm:  CGFloat = 10
        static let md:  CGFloat = 16   // Cards
        static let lg:  CGFloat = 20   // Hero card
        static let xl:  CGFloat = 28   // Sheets / modals
    }

    // MARK: - Animation Tokens
    enum Motion {
        /// Standard content transitions
        static let standard = Animation.easeInOut(duration: 0.3)
        /// Micro-interactions (button press, toggle)
        static let micro    = Animation.spring(response: 0.3, dampingFraction: 0.7)
        /// Chart bars animating in
        static func stagger(_ index: Int) -> Animation {
            .spring(response: 0.5, dampingFraction: 0.75)
             .delay(Double(index) * 0.04)
        }
    }

    // MARK: - Haptic helpers
    static func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        #if !os(tvOS)
        let g = UIImpactFeedbackGenerator(style: style)
        g.impactOccurred()
        #endif
    }
    static func hapticSelect() {
        #if !os(tvOS)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }
    static func hapticNotify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        #if !os(tvOS)
        UINotificationFeedbackGenerator().notificationOccurred(type)
        #endif
    }
}

// MARK: - Typography helpers
extension Font {
    /// 34pt / Semibold — screen large title
    static let dccLargeTitle = Font.system(size: 34, weight: .semibold, design: .rounded)
    /// 22pt / Semibold — section header
    static let dccSectionTitle = Font.system(size: 22, weight: .semibold)
    /// 28pt / Bold — hero metric number
    static let dccMetricLarge = Font.system(size: 48, weight: .bold, design: .rounded)
    /// Inside mini-metric tiles
    static let dccMetricMed   = Font.system(size: 24, weight: .bold, design: .rounded)
    static let dccMetricSmall = Font.system(size: 17, weight: .semibold, design: .rounded)
    /// Bar chart labels
    static let dccBarLabel    = Font.system(size: 13, weight: .medium)
    /// Secondary labels
    static let dccCaption      = Font.system(size: 13, weight: .regular)
    static let dccMicro        = Font.system(size: 11, weight: .medium)
}

// MARK: - View modifiers that enforce the system
struct DSCard: ViewModifier {
    var prominent: Bool = false
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: prominent ? DS.Radius.lg : DS.Radius.md)
                    .fill(Color.cardBackground)
            )
    }
}

extension View {
    func dsCard(prominent: Bool = false) -> some View {
        modifier(DSCard(prominent: prominent))
    }

    // Tap scale feedback used everywhere
    func dsTapScale(pressed: Bool) -> some View {
        self.scaleEffect(pressed ? 0.97 : 1.0)
            .animation(DS.Motion.micro, value: pressed)
    }
}

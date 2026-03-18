//
//  IPadDesignSystem.swift
//  DCC-Weekly-Activities
//
//  iPad-specific design tokens and layout constants.
//  Extends (does not replace) DesignSystem.swift.
//  Sized between iPhone (DesignSystem.swift) and Apple TV (TVDesignSystem.swift).
//

import SwiftUI

// MARK: - iPad Layout Constants

enum IPadLayout {
    // MARK: Content widths
    /// Max readable width for scrollable content on large iPads
    static let maxContentWidth: CGFloat = 920
    /// Sidebar width for NavigationSplitView
    static let sidebarWidth: CGFloat = 320

    // MARK: Card sizing
    static let cardMinWidth: CGFloat = 260
    static let cardMaxWidth: CGFloat = 440

    // MARK: Grid columns
    static let quickStatsColumns: Int = 4      // vs 2 on iPhone
    static let overviewColumns: Int = 2
    static let insightColumns: Int = 3

    // MARK: Spacing
    static let sectionGap: CGFloat = 32
    static let cardGap: CGFloat = 20
    static let screenMargin: CGFloat = 24
    static let sidebarItemPadding: CGFloat = 6

    // MARK: Corner radii
    static let cardCornerRadius: CGFloat = 20
    static let panelCornerRadius: CGFloat = 24
    static let tagCornerRadius: CGFloat = 10
}

// MARK: - iPad Typography

extension Font {
    /// 64pt black rounded — hero distance stat
    static let iPadHeroStat = Font.system(size: 64, weight: .black, design: .rounded)
    /// 26pt bold — section headers
    static let iPadSectionTitle = Font.system(size: 26, weight: .bold, design: .default)
    /// 20pt semibold — card titles
    static let iPadCardTitle = Font.system(size: 20, weight: .semibold, design: .default)
    /// 18pt regular — body copy
    static let iPadBodyLarge = Font.system(size: 18, weight: .regular, design: .default)
    /// 36pt bold rounded — metric numbers
    static let iPadStatNumber = Font.system(size: 36, weight: .bold, design: .rounded)
    /// 22pt semibold rounded — sub-stats
    static let iPadSubStatNumber = Font.system(size: 22, weight: .semibold, design: .rounded)
}

// MARK: - iPad Rank Color Helper

extension Color {
    /// Gold, silver, bronze tints for top-3 ranks; secondary for others
    static func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return Color(hex: "#FFD700")
        case 2: return Color(hex: "#C0C0C0")
        case 3: return Color(hex: "#CD7F32")
        default: return Color.textSecondary
        }
    }
}

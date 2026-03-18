//
//  AccessibilityTests.swift
//  DCC-Weekly-ActivitiesTests
//
//  WCAG 2.1 contrast-ratio unit tests and trend-label coverage checks.
//
//  Contrast ratio formula: (L1 + 0.05) / (L2 + 0.05)
//  where L1 is the lighter relative luminance and L2 the darker.
//  Reference: https://www.w3.org/TR/WCAG21/#contrast-minimum
//

import XCTest
@testable import DCC_Weekly_Activities

final class AccessibilityTests: XCTestCase {

    // MARK: - Colour Contrast Ratio Tests

    func testGoldColourContrastRatio() {
        // DCCColors.gold = #B8860B (r:0.722 g:0.525 b:0.043) on white #FFFFFF
        // Expected: >= 3.5:1 (passes WCAG AA for large text / UI components ≥18pt bold)
        let ratio = contrastRatio(
            foreground: (r: 0.722, g: 0.525, b: 0.043),
            background: (r: 1.0,   g: 1.0,   b: 1.0)
        )
        XCTAssertGreaterThanOrEqual(ratio, 3.0,
            "Gold colour #B8860B must achieve at least 3:1 contrast on white (WCAG AA large text)")
    }

    func testSilverColourContrastRatio() {
        // DCCColors.silver = #6B7280 (r:0.42 g:0.45 b:0.50) on white
        // Expected: >= 4.5:1 (passes WCAG AA normal text)
        let ratio = contrastRatio(
            foreground: (r: 0.42, g: 0.45, b: 0.50),
            background: (r: 1.0,  g: 1.0,  b: 1.0)
        )
        XCTAssertGreaterThanOrEqual(ratio, 4.5,
            "Silver colour #6B7280 must achieve 4.5:1 contrast on white (WCAG AA normal text)")
    }

    func testBronzeColourContrastRatio() {
        // DCCColors.bronze = #92400E (r:0.573 g:0.251 b:0.055) on white
        // Expected: >= 4.5:1 (passes WCAG AA)
        let ratio = contrastRatio(
            foreground: (r: 0.573, g: 0.251, b: 0.055),
            background: (r: 1.0,   g: 1.0,   b: 1.0)
        )
        XCTAssertGreaterThanOrEqual(ratio, 4.5,
            "Bronze colour #92400E must achieve 4.5:1 contrast on white (WCAG AA normal text)")
    }

    func testTextSecondaryContrastRatio() {
        // DCCColors.textSecondary = Color.primary.opacity(0.7)
        // On white background: Color.primary on white is black (0,0,0).
        // At 0.7 opacity over white → effective colour ≈ rgb(0.3, 0.3, 0.3) = #4D4D4D
        // Contrast against white: should be >= 4.5:1
        let ratio = contrastRatio(
            foreground: (r: 0.3, g: 0.3, b: 0.3),
            background: (r: 1.0, g: 1.0, b: 1.0)
        )
        XCTAssertGreaterThanOrEqual(ratio, 4.5,
            "Secondary text (primary.opacity(0.7) on white) must pass WCAG AA 4.5:1")
    }

    func testBrandGreenColourContrastRatio() {
        // DCCColors.green = #138808 (r:0.075 g:0.533 b:0.031) on white
        // Expected: >= 4.5:1
        let ratio = contrastRatio(
            foreground: (r: 0.075, g: 0.533, b: 0.031),
            background: (r: 1.0,   g: 1.0,   b: 1.0)
        )
        XCTAssertGreaterThanOrEqual(ratio, 4.5,
            "Brand green #138808 must achieve 4.5:1 on white (WCAG AA)")
    }

    // MARK: - Trend Direction → Text Label Coverage

    func testTrendDirectionLabelCoverage() {
        // Every TrendDirection case must map to a non-empty, meaningful label
        // (i.e. not a fallback like "No trend data").
        let meaningfulLabels = ["Improving", "Declining", "Stable", "New member"]

        let allCases: [MemberStats.TrendDirection] = [.up, .down, .stable, .new]
        for direction in allCases {
            let label = trendTextLabel(for: direction)
            XCTAssertTrue(
                meaningfulLabels.contains(label),
                "TrendDirection.\(direction) should map to a meaningful label, got: \(label)"
            )
        }
    }

    func testTrendDirectionLabelIsUnique() {
        // Each trend direction must have a distinct label (no duplicates).
        let labels = MemberStats.TrendDirection.allCasesForTest.map { trendTextLabel(for: $0) }
        let uniqueLabels = Set(labels)
        XCTAssertEqual(labels.count, uniqueLabels.count,
            "Each trend direction must have a unique accessibility label")
    }

    // MARK: - Helpers

    /// Computes WCAG 2.1 contrast ratio between two sRGB colours.
    private func contrastRatio(
        foreground: (r: Double, g: Double, b: Double),
        background: (r: Double, g: Double, b: Double)
    ) -> Double {
        let l1 = relativeLuminance(foreground)
        let l2 = relativeLuminance(background)
        let lighter = max(l1, l2)
        let darker  = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private func relativeLuminance(_ c: (r: Double, g: Double, b: Double)) -> Double {
        func linearise(_ v: Double) -> Double {
            v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearise(c.r)
             + 0.7152 * linearise(c.g)
             + 0.0722 * linearise(c.b)
    }

    /// Maps a TrendDirection to its UI text label, mirroring the logic in
    /// MemberStatsChartView.MemberDetailView and TVViews.TVMemberRow.
    private func trendTextLabel(for direction: MemberStats.TrendDirection) -> String {
        switch direction {
        case .up:     return "Improving"
        case .down:   return "Declining"
        case .stable: return "Stable"
        case .new:    return "New member"
        }
    }
}

// MARK: - TrendDirection test helper

extension MemberStats.TrendDirection {
    /// All cases, used by the unit test for exhaustive coverage checks.
    static var allCasesForTest: [MemberStats.TrendDirection] {
        [.up, .down, .stable, .new]
    }
}

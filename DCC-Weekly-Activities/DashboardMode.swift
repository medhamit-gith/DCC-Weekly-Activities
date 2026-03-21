//
//  DashboardMode.swift
//  DCC-Weekly-Activities
//
//  Represents the three analysis modes available from metric selection
//
//  VERSION HISTORY:
//  2026-02-24: [ICON] Updated worst performer icon from arrow.down.circle.fill
//              to tortoise.fill for cycling-appropriate iconography.
//

import SwiftUI

enum DashboardMode: String, Identifiable, CaseIterable {
    case justMyStats = "Just My Stats"
    case meVsTop3 = "Me vs Top 3 Riders"
    case worstPerformer = "Worst Performer & Why"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .justMyStats:
            return "person.fill"
        case .meVsTop3:
            return "chart.bar.xaxis"
        case .worstPerformer:
            return "tortoise.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .justMyStats:
            return .dccSaffron
        case .meVsTop3:
            return .dccGreen
        case .worstPerformer:
            return .dccBlue
        }
    }
    
    var description: String {
        switch self {
        case .justMyStats:
            return "View your complete weekly breakdown with club comparisons"
        case .meVsTop3:
            return "Compare yourself against the top 3 distance leaders"
        case .worstPerformer:
            return "See who had the quietest week and why"
        }
    }
}

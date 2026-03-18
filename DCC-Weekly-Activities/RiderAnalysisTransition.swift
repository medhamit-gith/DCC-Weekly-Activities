//
//  RiderAnalysisTransition.swift
//  DCC-Weekly-Activities
//
//  Custom animated transitions for RiderAnalysisView navigation
//

import SwiftUI

// MARK: - Slide In/Out + Fade Transition

extension AnyTransition {
    
    /// Premium slide-in transition for presenting RiderAnalysisView
    static var riderAnalysisPresent: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing)
                .combined(with: .opacity),
            removal: .move(edge: .trailing)
                .combined(with: .opacity)
        )
    }
    
    /// Hero card reveal with scale effect
    static var heroCardReveal: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.92)
                .combined(with: .opacity),
            removal: .scale(scale: 0.92)
                .combined(with: .opacity)
        )
    }
    
    /// Staggered slide-up for content sections
    static var slideUpFade: AnyTransition {
        .move(edge: .bottom)
            .combined(with: .opacity)
    }
}

// MARK: - Navigation Transition Modifier

struct AnalysisNavigationTransition: ViewModifier {
    let isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .transition(.riderAnalysisPresent)
            .animation(
                .spring(response: 0.45, dampingFraction: 0.82, blendDuration: 0),
                value: isPresented
            )
    }
}

extension View {
    /// Apply premium navigation transition to RiderAnalysisView
    func analysisNavigationTransition(isPresented: Bool) -> some View {
        modifier(AnalysisNavigationTransition(isPresented: isPresented))
    }
}

//
//  EmptyStateView.swift
//  DCC-Weekly-Activities
//
//  Reusable empty state component
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(Color.textTertiary)
                .accessibilityHidden(true)
            
            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.h2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                
                Text(message)
                    .font(.bodyDefault)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Empty State") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        EmptyStateView(
            icon: "chart.xyaxis.line",
            title: "No Data Yet",
            message: "Insights will appear once riders log activities"
        )
    }
}

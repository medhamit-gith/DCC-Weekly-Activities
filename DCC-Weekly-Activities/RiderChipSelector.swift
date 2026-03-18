//
//  RiderChipSelector.swift
//  DCC-Weekly-Activities
//
//  Horizontal scrolling pill selector for riders
//

import SwiftUI

struct RiderChipSelector: View {
    let stats: [MemberStats]
    @Binding var selectedRiderName: String?
    let viewModel: InsightsViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(viewModel.sortedStats, id: \.id) { rider in
                    RiderChip(
                        rider: rider,
                        rank: viewModel.rank(for: rider),
                        isSelected: selectedRiderName == rider.memberName,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedRiderName = rider.memberName
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
        }
    }
}

struct RiderChip: View {
    let rider: MemberStats
    let rank: Int
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var hapticTrigger = false
    
    private var rankEmoji: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(rank)"
        }
    }
    
    var body: some View {
        Button(action: {
            action()
            hapticTrigger.toggle()
        }) {
            HStack(spacing: Spacing.xs) {
                Text(rankEmoji)
                    .font(.system(size: 14))
                
                Text(rider.memberName)
                    .font(.bodyDefault)
                    .fontWeight(isSelected ? .bold : .medium)
            }
            .foregroundStyle(isSelected ? Color.textPrimary : Color.textSecondary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accent : Color.surface)
                    .shadow(
                        color: isSelected ? Color.accent.opacity(0.4) : .clear,
                        radius: isSelected ? 8 : 0,
                        x: 0,
                        y: isSelected ? 2 : 0
                    )
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .scaleEffect(isPressed ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        RiderChipSelector(
            stats: [
                MemberStats(memberName: "Alice", activities: []),
                MemberStats(memberName: "Bob", activities: []),
                MemberStats(memberName: "Charlie", activities: [])
            ],
            selectedRiderName: .constant("Alice"),
            viewModel: InsightsViewModel()
        )
    }
}

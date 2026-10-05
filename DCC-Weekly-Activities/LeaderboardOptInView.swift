//
//  LeaderboardOptInView.swift
//  DCC-Weekly-Activities
//
//  Lets a rider choose whether their rides appear on the club leaderboard.
//
//  Since Strava removed the club activity feed on 1 September 2026, the board
//  can only show riders who have opted in here. This screen is the only place
//  that choice is made — enrolment must never happen as a side effect of
//  signing in, because it grants ongoing read access to a rider's activities.
//

import SwiftUI

struct LeaderboardOptInView: View {
    @State private var membership = LeaderboardMembership.shared
    @State private var auth = UserAuthService.shared
    @State private var isWorking = false
    @State private var showLeaveConfirmation = false
    /// Validation the view does before calling the service, kept separate from
    /// the service's own `lastError`, which is private(set).
    @State private var localError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            header
            explanation
            actionButton

            if let error = localError ?? membership.lastError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.bodySmall)
                    .foregroundStyle(Color.error)
            }

            footnote
        }
        .padding(Spacing.lg)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .confirmationDialog(
            "Stop sharing your rides?",
            isPresented: $showLeaveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Stop sharing", role: .destructive) { Task { await leave() } }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your rides will be removed from the club leaderboard and deleted from the DCC server. You can rejoin at any time.")
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: membership.isEnrolled ? "checkmark.seal.fill" : "person.2.fill")
                .font(.title2)
                .foregroundStyle(membership.isEnrolled ? Color.success : Color.accent)

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text("Club leaderboard")
                    .font(.h3)
                    .foregroundStyle(Color.textPrimary)

                Text(membership.isEnrolled ? "You're sharing your rides" : "You're not sharing yet")
                    .font(.bodySmall)
                    .foregroundStyle(membership.isEnrolled ? Color.success : Color.textSecondary)
            }
        }
    }

    private var explanation: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(membership.isEnrolled
                 ? "DCC can see these rides of yours:"
                 : "If you share, DCC will be able to see:")
                .font(.bodyDefault)
                .foregroundStyle(Color.textSecondary)

            ForEach(sharedItems, id: \.self) { item in
                HStack(alignment: .top, spacing: Spacing.xs) {
                    Text("•").foregroundStyle(Color.textTertiary)
                    Text(item)
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }

    private var sharedItems: [String] {
        [
            "Your first name and last initial",
            "Distance, time and climbing for each ride",
            "Each ride's name and when you rode it"
        ]
    }

    private var actionButton: some View {
        Button {
            if membership.isEnrolled {
                showLeaveConfirmation = true
            } else {
                Task { await join() }
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                if isWorking {
                    ProgressView().tint(Color.textPrimary)
                }
                Text(buttonTitle)
                    .font(.labelLarge)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(membership.isEnrolled ? Color.surfaceElevated : Color.accent)
            .foregroundStyle(Color.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        }
        .disabled(isWorking)
    }

    private var buttonTitle: String {
        if isWorking { return membership.isEnrolled ? "Removing…" : "Joining…" }
        return membership.isEnrolled ? "Stop sharing" : "Share my rides"
    }

    private var footnote: some View {
        Text("The leaderboard only shows riders who have chosen to share, so it won't cover the whole club. Only rides count — walks and runs are ignored.")
            .font(.bodySmall)
            .foregroundStyle(Color.textTertiary)
    }

    // MARK: - Actions

    @MainActor
    private func join() async {
        localError = nil
        guard let refreshToken = auth.currentRefreshToken else {
            localError = "Please sign in with Strava first."
            return
        }
        isWorking = true
        defer { isWorking = false }
        if await membership.enrol(refreshToken: refreshToken) {
            await CloudDataFetcher.shared.fetchData()
        }
    }

    @MainActor
    private func leave() async {
        localError = nil
        guard let accessToken = auth.accessToken else {
            localError = "Please sign in with Strava first."
            return
        }
        isWorking = true
        defer { isWorking = false }
        if await membership.leave(accessToken: accessToken) {
            await CloudDataFetcher.shared.fetchData()
        }
    }
}

// MARK: - Status bar

/// Slim, always-present strip above the dashboard showing whether this rider is
/// sharing, and opening the opt-in screen when tapped.
///
/// Since Strava's club feed was withdrawn, a rider who has not opted in sees an
/// empty leaderboard with nothing explaining why. This is that explanation, and
/// the way in and back out again.
struct LeaderboardStatusBar: View {
    @State private var membership = LeaderboardMembership.shared
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: membership.isEnrolled ? "checkmark.circle.fill" : "person.badge.plus")
                    .foregroundStyle(membership.isEnrolled ? Color.success : Color.accent)

                Text(membership.isEnrolled
                     ? "You're sharing your rides with DCC"
                     : "Share your rides to appear on the leaderboard")
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)

                Spacer(minLength: Spacing.xs)

                Image(systemName: "chevron.right")
                    .font(.labelDefault)
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(Color.surface)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(membership.isEnrolled
                            ? "You are sharing your rides. Tap to manage."
                            : "Share your rides with the club leaderboard.")
    }
}

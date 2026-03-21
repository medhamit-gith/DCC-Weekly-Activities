//
//  ClubCodeLoginView.swift
//  DCC-Weekly-Activities
//
//  Simple club code entry screen — replaces the Strava OAuth login.
//

import SwiftUI

struct ClubCodeLoginView: View {
    @State private var clubAuth = ClubCodeAuthService.shared
    @State private var codeText = ""
    @State private var nameText = ""
    @State private var isShaking = false

    var body: some View {
        ZStack {
            // Match existing app background
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Club branding — reuse existing app icon if available
                VStack(spacing: 12) {
                    Image(systemName: "bicycle")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)

                    Text("DCC Weekly Activities")
                        .font(.title2).fontWeight(.bold)

                    Text("Desi Cycling Club")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Input fields
                VStack(spacing: 14) {
                    TextField("Your name", text: $nameText)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 32)

                    TextField("Club code", text: $codeText)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                        .padding(.horizontal, 32)
                }
                .offset(x: isShaking ? -8 : 0)

                if let error = clubAuth.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Button(action: {
                    let success = clubAuth.authenticate(code: codeText, name: nameText)
                    if !success {
                        withAnimation(.default.repeatCount(3, autoreverses: true)) {
                            isShaking = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            isShaking = false
                        }
                    }
                }) {
                    Text("Join DCC")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 32)

                Text("Ask your DCC admin for the club code")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer()
                Spacer()
            }
        }
    }
}

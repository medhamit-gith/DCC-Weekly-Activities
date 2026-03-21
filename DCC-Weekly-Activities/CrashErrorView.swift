//
//  CrashErrorView.swift
//  DCC-Weekly-Activities
//
//  Animated crash-sequence error view.
//  A cyclist rides in, hits an obstacle, goes airborne, crashes, sees stars,
//  gives a thumbs-up, and the error card slides up — turning frustration into a smile.
//
//  Usage:
//      CrashErrorView(error: .networkUnavailable) { await viewModel.load() }
//
//  Accessibility: @Environment(\.accessibilityReduceMotion) skips straight to the
//  error card when the user has reduced motion enabled.
//

import SwiftUI

// MARK: - Animation phases

private enum CrashPhase {
    case idle, riding, impact, airborne, crashed, stars, recovering, done
}

// MARK: - Error presentation config

private struct CrashErrorConfig {
    let code: String
    let title: String
    let message: String
    let buttonLabel: String
    let requiresReauth: Bool

    init(for error: AppError) {
        switch error {
        case .networkUnavailable, .requestTimeout:
            code = "NETWORK_ERR"
            title = "Dropped Chain!"
            message = "No connection found.\nCheck your network and try again."
            buttonLabel = "Try Again"
            requiresReauth = false

        case .tokenExpired, .authenticationFailed, .invalidCredentials:
            code = "STRAVA_401"
            title = "Bonked!"
            message = "Authentication expired.\nEven champions need to re-connect."
            buttonLabel = "Reconnect Strava"
            requiresReauth = true

        case .rateLimitExceeded:
            code = "API_429"
            title = "Pace Too Hot!"
            message = "Strava rate limit hit.\nTake a breather for a moment."
            buttonLabel = "Try Again Later"
            requiresReauth = false

        case .parsingError, .invalidData, .invalidResponse:
            code = "PARSE_ERR"
            title = "Mechanical!"
            message = "Couldn't read the data.\nThe team is on it."
            buttonLabel = "Try Again"
            requiresReauth = false

        case .noData:
            code = "NO_DATA"
            title = "Empty Roads!"
            message = "No activities found yet.\nGet out and ride!"
            buttonLabel = "Refresh"
            requiresReauth = false

        case .serverError(let code):
            self.code = "SERVER_\(code)"
            title = "Race Neutralised!"
            message = "Server is taking a rest.\nHang tight and try again."
            buttonLabel = "Try Again"
            requiresReauth = false

        default:
            code = "UNKNOWN"
            title = "Puncture!"
            message = "Something went wrong.\nWe'll get you back on the road."
            buttonLabel = "Try Again"
            requiresReauth = false
        }
    }
}

// MARK: - Main view

struct CrashErrorView: View {
    let error: AppError
    /// Called when the primary button is tapped. Use async throwing closure for retry/reauth work.
    var retryAction: (() async -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CrashPhase = .idle
    @State private var showCard = false
    @State private var isRetrying = false
    @State private var retryHaptic = false

    private let config: CrashErrorConfig

    init(error: AppError, retryAction: (() async -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
        self.config = CrashErrorConfig(for: error)
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                // Cyclist stage
                ZStack {
                    // Ground glow when crashed
                    if phase == .crashed || phase == .stars || phase == .recovering || phase == .done {
                        Ellipse()
                            .fill(
                                RadialGradient(
                                    colors: [Color.accent.opacity(0.18), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 120
                                )
                            )
                            .frame(width: 240, height: 28)
                            .offset(y: 80)
                    }

                    CyclistCanvas(phase: phase)
                        .frame(width: 280, height: 200)

                    // Star burst overlay
                    if phase == .stars {
                        StarBurstView()
                    }
                }
                .frame(height: 220)
                .modifier(ShakeModifier(active: phase == .impact))

                Spacer().frame(height: 8)

                // Error card
                errorCard
                    .opacity(showCard ? 1 : 0)
                    .offset(y: showCard ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.78), value: showCard)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear { startSequence() }
    }

    // MARK: - Error card

    private var errorCard: some View {
        VStack(spacing: 0) {
            // Code badge
            Text(config.code)
                .font(.system(.caption2, design: .monospaced).weight(.semibold))
                .tracking(2.5)
                .foregroundStyle(Color.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.accent.opacity(0.1))
                        .overlay(Capsule().strokeBorder(Color.accent.opacity(0.25), lineWidth: 1))
                )
                .padding(.bottom, 16)

            // Title
            Text(config.title)
                .font(.system(size: 30, weight: .light, design: .serif))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)

            // Message
            Text(config.message)
                .font(.subheadline.weight(.light))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.bottom, 28)

            // Primary CTA
            Button {
                Task { await handleRetry() }
            } label: {
                Group {
                    if isRetrying {
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(0.8)
                            Text("Clipping back in…")
                        }
                    } else {
                        Text(config.buttonLabel)
                    }
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isRetrying ? Color.accent.opacity(0.6) : Color.accent)
                )
            }
            .disabled(isRetrying)
            .sensoryFeedback(.impact(weight: .medium), trigger: retryHaptic)
            .padding(.bottom, 12)

            // Support link
            Button("Contact Support") {}
                .font(.footnote)
                .foregroundStyle(Color.textTertiary)
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 40, y: 16)
        )
    }

    // MARK: - Sequence

    private func startSequence() {
        guard phase == .idle else { return }

        if reduceMotion {
            // Skip straight to the error card
            phase = .done
            showCard = true
            return
        }

        let steps: [(CrashPhase, Double)] = [
            (.riding,     0.0),
            (.impact,     1.2),
            (.airborne,   1.55),
            (.crashed,    1.95),
            (.stars,      2.15),
            (.recovering, 3.5),
            (.done,       3.85),
        ]

        for (newPhase, delay) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.18)) { phase = newPhase }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.05) {
            withAnimation { showCard = true }
        }
    }

    private func handleRetry() async {
        guard !isRetrying else { return }
        isRetrying = true
        retryHaptic.toggle()

        await retryAction?()

        // Reset and replay the animation sequence after a short pause
        withAnimation { showCard = false }
        try? await Task.sleep(for: .milliseconds(600))
        phase = .idle
        isRetrying = false
        startSequence()
    }
}

// MARK: - Cyclist Canvas

/// Draws the cyclist using Canvas for crisp, GPU-composited rendering at all sizes.
private struct CyclistCanvas: View {
    let phase: CrashPhase

    var body: some View {
        Canvas { context, size in
            let cx = size.width / 2
            let cy = size.height / 2

            switch phase {
            case .idle, .riding:
                drawRiding(context: context, cx: cx, cy: cy)
            case .impact:
                drawImpact(context: context, cx: cx, cy: cy)
            case .airborne:
                var ctx = context
                ctx.transform = CGAffineTransform(translationX: cx, y: cy + 20)
                    .rotated(by: -.pi / 8)
                    .translatedBy(x: -cx, y: -(cy + 20))
                drawAirborne(context: ctx, cx: cx, cy: cy - 20)
            case .crashed, .stars:
                drawCrashed(context: context, cx: cx, cy: cy, thumbsUp: false)
            case .recovering, .done:
                drawCrashed(context: context, cx: cx, cy: cy, thumbsUp: true)
            }
        }
    }

    // ── Shared drawing helpers ──────────────────────────────────────────────

    private let orange = Color.accent
    private let skin   = Color(red: 0.98, green: 0.75, blue: 0.54)
    private let bike   = Color(red: 0.16, green: 0.16, blue: 0.20)
    private let wheel  = Color(red: 0.20, green: 0.20, blue: 0.26)
    private let shorts = Color(red: 0.10, green: 0.10, blue: 0.14)
    private let helmet = Color.accent

    private func stroke(_ context: GraphicsContext, path: Path, color: Color, lineWidth: CGFloat = 5, cap: CGLineCap = .round) {
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: cap))
    }

    private func wheelAt(_ context: GraphicsContext, cx: CGFloat, cy: CGFloat, r: CGFloat, dashed: Bool = false) {
        var path = Path()
        path.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        let style: StrokeStyle = dashed
            ? StrokeStyle(lineWidth: 5, dash: [9, 5])
            : StrokeStyle(lineWidth: 5)
        context.stroke(path, with: .color(wheel), style: style)

        // Hub
        var hub = Path()
        hub.addEllipse(in: CGRect(x: cx - 4, y: cy - 4, width: 8, height: 8))
        context.fill(hub, with: .color(wheel))

        // Spokes (4 × 45°)
        for a in stride(from: 0.0, to: .pi, by: .pi / 4) {
            var spoke = Path()
            spoke.move(to: CGPoint(x: cx, y: cy))
            spoke.addLine(to: CGPoint(x: cx + (r - 4) * CGFloat(cos(a)), y: cy + (r - 4) * CGFloat(sin(a))))
            spoke.move(to: CGPoint(x: cx, y: cy))
            spoke.addLine(to: CGPoint(x: cx - (r - 4) * CGFloat(cos(a)), y: cy - (r - 4) * CGFloat(sin(a))))
            context.stroke(spoke, with: .color(Color(white: 0.28)), style: StrokeStyle(lineWidth: 1.5))
        }
    }

    private func line(_ context: GraphicsContext, from: CGPoint, to: CGPoint, color: Color, width: CGFloat = 5) {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    private func circle(_ context: GraphicsContext, at pt: CGPoint, r: CGFloat, fill color: Color) {
        var path = Path()
        path.addEllipse(in: CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2))
        context.fill(path, with: .color(color))
    }

    // ── Riding ──────────────────────────────────────────────────────────────

    private func drawRiding(context: GraphicsContext, cx: CGFloat, cy: CGFloat) {
        // Rear wheel (left), front wheel (right)
        wheelAt(context, cx: cx - 70, cy: cy + 50, r: 38)
        wheelAt(context, cx: cx + 60, cy: cy + 50, r: 38)

        // Frame
        line(context, from: CGPoint(x: cx - 70, y: cy + 50), to: CGPoint(x: cx - 10, y: cy - 5), color: bike)
        line(context, from: CGPoint(x: cx - 10, y: cy - 5), to: CGPoint(x: cx + 60, y: cy + 50), color: bike)
        line(context, from: CGPoint(x: cx - 10, y: cy - 5), to: CGPoint(x: cx - 22, y: cy - 42), color: bike)
        line(context, from: CGPoint(x: cx - 22, y: cy - 42), to: CGPoint(x: cx + 60, y: cy + 50), color: bike, width: 3)

        // Seat post + saddle
        line(context, from: CGPoint(x: cx - 10, y: cy - 5), to: CGPoint(x: cx - 32, y: cy - 16), color: bike, width: 4)
        var saddle = Path()
        saddle.addRoundedRect(in: CGRect(x: cx - 46, y: cy - 22, width: 28, height: 9), cornerSize: CGSize(width: 4, height: 4))
        context.fill(saddle, with: .color(Color(white: 0.22)))

        // Handlebars
        line(context, from: CGPoint(x: cx - 22, y: cy - 42), to: CGPoint(x: cx - 8, y: cy - 50), color: bike, width: 4)
        var bar = Path()
        bar.addRoundedRect(in: CGRect(x: cx - 8, y: cy - 55, width: 14, height: 6), cornerSize: CGSize(width: 3, height: 3))
        context.fill(bar, with: .color(Color(white: 0.22)))

        // Legs (aero tuck)
        line(context, from: CGPoint(x: cx - 32, y: cy - 16), to: CGPoint(x: cx - 50, y: cy + 26), color: shorts, width: 10)
        line(context, from: CGPoint(x: cx - 50, y: cy + 26), to: CGPoint(x: cx - 60, y: cy + 48), color: skin, width: 8)
        line(context, from: CGPoint(x: cx - 32, y: cy - 16), to: CGPoint(x: cx - 14, y: cy + 20), color: shorts, width: 10)
        line(context, from: CGPoint(x: cx - 14, y: cy + 20), to: CGPoint(x: cx - 10, y: cy + 46), color: skin, width: 8)

        // Body
        line(context, from: CGPoint(x: cx - 32, y: cy - 16), to: CGPoint(x: cx - 4, y: cy - 38), color: orange, width: 14)

        // Arms
        line(context, from: CGPoint(x: cx - 10, y: cy - 34), to: CGPoint(x: cx - 10, y: cy - 50), color: orange, width: 8)
        line(context, from: CGPoint(x: cx - 10, y: cy - 50), to: CGPoint(x: cx - 6, y: cy - 53), color: skin, width: 6)

        // Head
        circle(context, at: CGPoint(x: cx + 2, y: cy - 48), r: 15, fill: skin)
        // Helmet
        var helmetPath = Path()
        helmetPath.addEllipse(in: CGRect(x: cx - 14, y: cy - 69, width: 32, height: 20))
        context.fill(helmetPath, with: .color(helmet))
    }

    // ── Impact ───────────────────────────────────────────────────────────────

    private func drawImpact(context: GraphicsContext, cx: CGFloat, cy: CGFloat) {
        wheelAt(context, cx: cx - 70, cy: cy + 52, r: 34, dashed: true)
        wheelAt(context, cx: cx + 58, cy: cy + 50, r: 36)

        line(context, from: CGPoint(x: cx - 70, y: cy + 52), to: CGPoint(x: cx - 12, y: cy + 2), color: bike)
        line(context, from: CGPoint(x: cx - 12, y: cy + 2), to: CGPoint(x: cx + 58, y: cy + 50), color: bike)
        line(context, from: CGPoint(x: cx - 12, y: cy + 2), to: CGPoint(x: cx - 24, y: cy - 36), color: bike)

        // Saddle
        var saddle = Path()
        saddle.addRoundedRect(in: CGRect(x: cx - 46, y: cy - 20, width: 28, height: 9), cornerSize: CGSize(width: 4, height: 4))
        context.fill(saddle, with: .color(Color(white: 0.22)))

        // Lurching legs
        line(context, from: CGPoint(x: cx - 34, y: cy - 12), to: CGPoint(x: cx - 56, y: cy + 30), color: shorts, width: 10)
        line(context, from: CGPoint(x: cx - 56, y: cy + 30), to: CGPoint(x: cx - 66, y: cy + 50), color: skin, width: 8)
        line(context, from: CGPoint(x: cx - 34, y: cy - 12), to: CGPoint(x: cx - 14, y: cy + 22), color: shorts, width: 10)
        line(context, from: CGPoint(x: cx - 14, y: cy + 22), to: CGPoint(x: cx - 8, y: cy + 46), color: skin, width: 8)

        // Body
        line(context, from: CGPoint(x: cx - 34, y: cy - 12), to: CGPoint(x: cx, y: cy - 36), color: orange, width: 14)

        // Flailing arm
        line(context, from: CGPoint(x: cx - 6, y: cy - 30), to: CGPoint(x: cx + 16, y: cy - 52), color: orange, width: 8)
        line(context, from: CGPoint(x: cx + 16, y: cy - 52), to: CGPoint(x: cx + 28, y: cy - 60), color: skin, width: 6)

        // Head jolt (shifted right)
        circle(context, at: CGPoint(x: cx + 14, y: cy - 44), r: 15, fill: skin)
        var helmetPath = Path()
        helmetPath.addEllipse(in: CGRect(x: cx, y: cy - 65, width: 32, height: 20))
        context.fill(helmetPath, with: .color(helmet))

        // Impact burst lines
        let burstOrigin = CGPoint(x: cx + 50, y: cy + 42)
        for angle in [CGFloat(-2.3), -1.7, -1.2, -0.7, -0.2] {
            var burst = Path()
            burst.move(to: burstOrigin)
            burst.addLine(to: CGPoint(x: burstOrigin.x + 24 * cos(angle), y: burstOrigin.y + 24 * sin(angle)))
            context.stroke(burst, with: .color(orange), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        }

        // Sparks
        circle(context, at: CGPoint(x: cx + 42, y: cy + 52), r: 3, fill: Color(red: 1.0, green: 0.84, blue: 0.0))
        circle(context, at: CGPoint(x: cx + 56, y: cy + 46), r: 2, fill: .white)
        circle(context, at: CGPoint(x: cx + 50, y: cy + 58), r: 2.5, fill: Color(red: 1.0, green: 0.84, blue: 0.0))
    }

    // ── Airborne ─────────────────────────────────────────────────────────────

    private func drawAirborne(context: GraphicsContext, cx: CGFloat, cy: CGFloat) {
        wheelAt(context, cx: cx - 68, cy: cy + 52, r: 34, dashed: true)
        wheelAt(context, cx: cx + 50, cy: cy + 46, r: 32)

        line(context, from: CGPoint(x: cx - 68, y: cy + 52), to: CGPoint(x: cx - 14, y: cy + 5), color: bike)
        line(context, from: CGPoint(x: cx - 14, y: cy + 5), to: CGPoint(x: cx + 50, y: cy + 46), color: bike)
        line(context, from: CGPoint(x: cx - 14, y: cy + 5), to: CGPoint(x: cx - 22, y: cy - 30), color: bike)

        // Legs flailing upward
        line(context, from: CGPoint(x: cx - 30, y: cy - 2), to: CGPoint(x: cx - 58, y: cy - 28), color: shorts, width: 10)
        line(context, from: CGPoint(x: cx - 58, y: cy - 28), to: CGPoint(x: cx - 74, y: cy - 40), color: skin, width: 8)
        line(context, from: CGPoint(x: cx - 30, y: cy - 2), to: CGPoint(x: cx - 6, y: cy - 24), color: shorts, width: 10)
        line(context, from: CGPoint(x: cx - 6, y: cy - 24), to: CGPoint(x: cx + 6, y: cy - 34), color: skin, width: 8)

        // Body
        line(context, from: CGPoint(x: cx - 30, y: cy - 2), to: CGPoint(x: cx - 12, y: cy - 32), color: orange, width: 14)

        // Arms wide
        line(context, from: CGPoint(x: cx - 18, y: cy - 24), to: CGPoint(x: cx - 40, y: cy - 48), color: orange, width: 8)
        line(context, from: CGPoint(x: cx - 40, y: cy - 48), to: CGPoint(x: cx - 56, y: cy - 56), color: skin, width: 6)
        line(context, from: CGPoint(x: cx - 18, y: cy - 24), to: CGPoint(x: cx + 4, y: cy - 44), color: orange, width: 8)
        line(context, from: CGPoint(x: cx + 4, y: cy - 44), to: CGPoint(x: cx + 18, y: cy - 52), color: skin, width: 6)

        // Head
        circle(context, at: CGPoint(x: cx - 4, y: cy - 46), r: 15, fill: skin)
        var helmetPath = Path()
        helmetPath.addEllipse(in: CGRect(x: cx - 20, y: cy - 67, width: 32, height: 20))
        context.fill(helmetPath, with: .color(helmet))
    }

    // ── Crashed ──────────────────────────────────────────────────────────────

    private func drawCrashed(context: GraphicsContext, cx: CGFloat, cy: CGFloat, thumbsUp: Bool) {
        // Ground line
        var ground = Path()
        ground.move(to: CGPoint(x: cx - 130, y: cy + 82))
        ground.addLine(to: CGPoint(x: cx + 130, y: cy + 82))
        context.stroke(ground, with: .color(Color.white.opacity(0.05)), style: StrokeStyle(lineWidth: 1))

        // Wheels flat on ground
        wheelAt(context, cx: cx - 48, cy: cy + 74, r: 44, dashed: false)
        wheelAt(context, cx: cx + 46, cy: cy + 70, r: 38, dashed: true)

        // Frame horizontal
        line(context, from: CGPoint(x: cx - 48, y: cy + 74), to: CGPoint(x: cx - 2, y: cy + 50), color: bike)
        line(context, from: CGPoint(x: cx - 2, y: cy + 50), to: CGPoint(x: cx + 46, y: cy + 70), color: bike)
        line(context, from: CGPoint(x: cx - 2, y: cy + 50), to: CGPoint(x: cx + 4, y: cy + 30), color: bike)

        // Rider flat
        line(context, from: CGPoint(x: cx - 70, y: cy + 52), to: CGPoint(x: cx + 10, y: cy + 40), color: orange, width: 14)

        // Legs
        line(context, from: CGPoint(x: cx - 70, y: cy + 52), to: CGPoint(x: cx - 90, y: cy + 68), color: shorts, width: 10)
        line(context, from: CGPoint(x: cx - 90, y: cy + 68), to: CGPoint(x: cx - 110, y: cy + 78), color: skin, width: 8)
        line(context, from: CGPoint(x: cx - 70, y: cy + 52), to: CGPoint(x: cx - 62, y: cy + 70), color: shorts, width: 10)
        line(context, from: CGPoint(x: cx - 62, y: cy + 70), to: CGPoint(x: cx - 74, y: cy + 80), color: skin, width: 8)

        // Head on ground
        circle(context, at: CGPoint(x: cx + 30, y: cy + 36), r: 16, fill: skin)
        var helmetPath = Path()
        helmetPath.addEllipse(in: CGRect(x: cx + 14, y: cy + 18, width: 32, height: 20))
        context.fill(helmetPath, with: .color(helmet))

        // X eyes
        let eyeCx = cx + 34
        let eyeCy = cy + 38
        line(context, from: CGPoint(x: eyeCx - 5, y: eyeCy - 4), to: CGPoint(x: eyeCx, y: eyeCy + 1), color: Color.black.opacity(0.35), width: 1.5)
        line(context, from: CGPoint(x: eyeCx - 5, y: eyeCy + 1), to: CGPoint(x: eyeCx, y: eyeCy - 4), color: Color.black.opacity(0.35), width: 1.5)

        // Normal arm
        line(context, from: CGPoint(x: cx + 10, y: cy + 40), to: CGPoint(x: cx + 20, y: cy + 28), color: orange, width: 7)
        line(context, from: CGPoint(x: cx + 20, y: cy + 28), to: CGPoint(x: cx + 28, y: cy + 20), color: skin, width: 5)

        // Thumbs-up arm (recovering)
        if thumbsUp {
            line(context, from: CGPoint(x: cx - 30, y: cy + 44), to: CGPoint(x: cx - 22, y: cy + 15), color: orange, width: 8)
            line(context, from: CGPoint(x: cx - 22, y: cy + 15), to: CGPoint(x: cx - 18, y: cy), color: skin, width: 6)

            // Fist + thumb
            circle(context, at: CGPoint(x: cx - 16, y: cy - 8), r: 8, fill: skin)
            // Thumb extending up
            line(context, from: CGPoint(x: cx - 16, y: cy - 16), to: CGPoint(x: cx - 16, y: cy - 28), color: skin, width: 5.5)
        }
    }
}

// MARK: - Star burst overlay (emoji via Text canvas)

private struct StarBurstView: View {
    @State private var angle: Double = 0

    private let items = ["⭐", "✨", "💫", "⭐", "✨", "💫", "⭐"]

    var body: some View {
        ZStack {
            ForEach(Array(items.enumerated()), id: \.offset) { index, emoji in
                Text(emoji)
                    .font(.system(size: index % 2 == 0 ? 13 : 9))
                    .offset(
                        x: 52 * cos(angle + Double(index) * (.pi * 2 / Double(items.count))),
                        y: 52 * sin(angle + Double(index) * (.pi * 2 / Double(items.count)))
                    )
            }
        }
        .offset(y: -30) // Align to head position
        .onAppear {
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                angle = .pi * 2
            }
        }
    }
}

// MARK: - Shake modifier

private struct ShakeModifier: ViewModifier {
    let active: Bool
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: active) { _, isActive in
                guard isActive else { return }
                let keyframes: [(CGFloat, Double)] = [
                    (-8, 0.05), (8, 0.10), (-5, 0.15), (5, 0.20), (-2, 0.25), (0, 0.30)
                ]
                for (x, delay) in keyframes {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        withAnimation(.easeInOut(duration: 0.04)) { offset = x }
                    }
                }
            }
    }
}

// MARK: - Convenience modifier

extension View {
    /// Overlays the crash animation error screen when an AppError is present.
    func crashErrorOverlay(
        error: AppError?,
        retryAction: (() async -> Void)? = nil
    ) -> some View {
        overlay {
            if let error {
                CrashErrorView(error: error, retryAction: retryAction)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.easeOut(duration: 0.3), value: error?.id)
    }
}

// MARK: - Previews

#Preview("Network Error") {
    CrashErrorView(error: .networkUnavailable) {
        try? await Task.sleep(for: .seconds(1))
    }
    .preferredColorScheme(.dark)
}

#Preview("Auth / Bonked") {
    CrashErrorView(error: .tokenExpired) {}
    .preferredColorScheme(.dark)
}

#Preview("Rate Limit") {
    CrashErrorView(error: .rateLimitExceeded) {}
    .preferredColorScheme(.dark)
}

#Preview("Mechanical / Parse") {
    CrashErrorView(error: .parsingError) {}
    .preferredColorScheme(.dark)
}

#Preview("Reduced Motion") {
    // accessibilityReduceMotion is read-only from EnvironmentValues;
    // trigger via the accessibility API or simulate in code using the existing #if DEBUG path.
    CrashErrorView(error: .networkUnavailable) {}
        .preferredColorScheme(.dark)
}

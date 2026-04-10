import SwiftUI

struct SplashView: View {
    let onComplete: () -> Void

    // Logo
    @State private var logoScale: CGFloat = 0.25
    @State private var logoOpacity: Double = 0
    @State private var logoRotation: Double = -30

    // Icon inside logo
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0

    // Rings
    @State private var ring1Scale: CGFloat = 0.6
    @State private var ring1Opacity: Double = 0
    @State private var ring2Scale: CGFloat = 0.6
    @State private var ring2Opacity: Double = 0

    // Glow blob
    @State private var glowOpacity: Double = 0
    @State private var glowScale: CGFloat = 0.8

    // Particles
    @State private var particlesVisible: Bool = false

    // Text
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 12
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = 10

    // Shimmer on logo circle
    @State private var shimmerOffset: CGFloat = -160

    // Final fade-out
    @State private var wholeOpacity: Double = 1

    private let particles: [(angle: Double, distance: CGFloat, size: CGFloat)] = (0..<8).map { i in
        let angle = Double(i) * 45.0
        let distance = CGFloat.random(in: 72...110)
        let size = CGFloat.random(in: 3...6)
        return (angle, distance, size)
    }

    var body: some View {
        ZStack {
            Color.blazeBackground.ignoresSafeArea()

            // Background ambient glow
            Circle()
                .fill(Color.blazeRed.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .scaleEffect(glowScale)
                .opacity(glowOpacity)

            // Outer thin ring
            Circle()
                .stroke(
                    LinearGradient.blazeFire.opacity(0.35),
                    lineWidth: 1
                )
                .frame(width: 210, height: 210)
                .scaleEffect(ring2Scale)
                .opacity(ring2Opacity)

            // Inner stroke ring
            Circle()
                .stroke(LinearGradient.blazeFire, lineWidth: 1.5)
                .frame(width: 158, height: 158)
                .scaleEffect(ring1Scale)
                .opacity(ring1Opacity)

            // Burst particles
            if particlesVisible {
                ForEach(0..<particles.count, id: \.self) { i in
                    let p = particles[i]
                    Circle()
                        .fill(i % 2 == 0 ? Color.blazeRed : Color.blazeOrange)
                        .frame(width: p.size, height: p.size)
                        .offset(
                            x: cos(p.angle * .pi / 180) * p.distance,
                            y: sin(p.angle * .pi / 180) * p.distance
                        )
                        .opacity(ring1Opacity * 0.7)
                }
            }

            // Logo circle + icon
            ZStack {
                // Circle with shimmer overlay
                Circle()
                    .fill(LinearGradient.blazeFire)
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.blazeRed.opacity(0.75), radius: 28, x: 0, y: 6)
                    .overlay {
                        // Shimmer streak
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.25), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 40)
                            .offset(x: shimmerOffset)
                            .clipShape(Circle())
                    }

                // SF Symbol flame icon
                Image(systemName: "flame.fill")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .white.opacity(0.5), radius: 8)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
            .rotationEffect(.degrees(logoRotation))

            // Text pinned to bottom
            VStack(spacing: 6) {
                Text("Blaze Results")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(LinearGradient.blazeFire)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)

                Text("Heat zones. Live.")
                    .font(.subheadline)
                    .foregroundStyle(Color.blazeSubtext)
                    .opacity(subtitleOpacity)
                    .offset(y: subtitleOffset)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 88)
        }
        .opacity(wholeOpacity)
        .task { await runSplash() }
    }

    private func runSplash() async {
        // 1. Logo springs in with slight rotation settle
        try? await Task.sleep(for: .milliseconds(180))
        withAnimation(.spring(response: 0.52, dampingFraction: 0.58)) {
            logoScale = 1.0
            logoOpacity = 1.0
            logoRotation = 0
        }

        // 2. Icon pops in inside logo
        try? await Task.sleep(for: .milliseconds(220))
        withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }

        // 3. Inner ring expands in
        try? await Task.sleep(for: .milliseconds(120))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            ring1Scale = 1.0
            ring1Opacity = 1.0
            glowOpacity = 1.0
            glowScale = 1.0
        }
        particlesVisible = true

        // 4. Outer ring expands in with slight delay
        try? await Task.sleep(for: .milliseconds(100))
        withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
            ring2Scale = 1.0
            ring2Opacity = 1.0
        }

        // 5. Title slides up
        try? await Task.sleep(for: .milliseconds(120))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            titleOpacity = 1.0
            titleOffset = 0
        }

        // 6. Subtitle slides up
        try? await Task.sleep(for: .milliseconds(110))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            subtitleOpacity = 1.0
            subtitleOffset = 0
        }

        // 7. Shimmer sweep
        try? await Task.sleep(for: .milliseconds(200))
        withAnimation(.easeInOut(duration: 0.7)) {
            shimmerOffset = 160
        }

        // 8. Rings breathe
        try? await Task.sleep(for: .milliseconds(200))
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
            ring1Scale = 1.14
            ring2Scale = 1.1
            glowScale = 1.18
        }

        // 9. Hold
        try? await Task.sleep(for: .milliseconds(1200))

        // 10. Fade everything out
        withAnimation(.easeIn(duration: 0.35)) {
            wholeOpacity = 0
        }
        try? await Task.sleep(for: .milliseconds(360))
        onComplete()
    }
}

import SwiftUI

struct HotSpotAnnotationView: View {
    let spot: HotSpot

    @State private var pulseScale: CGFloat = 1
    @State private var pulseOpacity: Double = 0.6

    private var heatColor: Color {
        switch spot.intensity {
        case 0..<0.4: return .blue
        case 0.4..<0.6: return .yellow
        case 0.6..<0.8: return .blazeOrange
        default: return .blazeRed
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(heatColor.opacity(0.25 * pulseOpacity))
                .frame(width: 52 * pulseScale, height: 52 * pulseScale)

            Circle()
                .fill(heatColor.opacity(0.45))
                .frame(width: 28, height: 28)
                .overlay {
                    Circle()
                        .stroke(heatColor, lineWidth: 2)
                }

            VStack(spacing: 0) {
                Text("\(spot.temperature, specifier: "%.0f")°")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.4)
                .repeatForever(autoreverses: true)
                .delay(Double.random(in: 0...1))
            ) {
                pulseScale = 1.4
                pulseOpacity = 0.2
            }
        }
    }
}

import SwiftUI

#Preview {
    OnboardingView(onComplete: {})
}

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var currentPage = 0

    private let slides: [OnboardingSlide] = [
        OnboardingSlide(
            imageName: "onboarding1",
            accentGradient: LinearGradient(
                colors: [Color(red: 0.55, green: 0.05, blue: 0.05), Color(red: 1.0, green: 0.18, blue: 0.33)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            title: "Brazil Heat,\nMapped Live",
            subtitle: "Real-time heat zone monitoring across all Brazilian states — from the Amazon to the Cerrado."
        ),
        OnboardingSlide(
            imageName: "onboarding2",
            accentGradient: LinearGradient(
                colors: [Color(red: 0.40, green: 0.08, blue: 0.00), Color(red: 1.0, green: 0.50, blue: 0.12)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            title: "Temperature\nTimelines",
            subtitle: "Crash-style animated charts track 24-hour temperature and humidity curves for every monitored zone."
        ),
        OnboardingSlide(
            imageName: "onboarding3",
            accentGradient: LinearGradient(
                colors: [Color(red: 0.08, green: 0.08, blue: 0.45), Color(red: 0.25, green: 0.10, blue: 0.75)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            title: "Interactive\nHeat Map",
            subtitle: "Tap any annotated zone on the map to see its live temperature, humidity, and heat intensity score."
        ),
        OnboardingSlide(
            imageName: "onboarding4",
            accentGradient: LinearGradient(
                colors: [Color(red: 0.05, green: 0.22, blue: 0.12), Color(red: 0.10, green: 0.62, blue: 0.32)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            title: "Ask\nBlaze AI",
            subtitle: "Powered by Apple Foundation Models on iOS 26. Ask anything about Brazil's climate and get instant answers."
        )
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                ForEach(slides.indices, id: \.self) { index in
                    OnboardingSlideView(slide: slides[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Animated page dots
                HStack(spacing: 8) {
                    ForEach(slides.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? Color.white : Color.white.opacity(0.35))
                            .frame(width: i == currentPage ? 28 : 8, height: 8)
                            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentPage)
                    }
                }

                Button(action: advance) {
                    Text(currentPage == slides.count - 1 ? "Get Started" : "Next")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(LinearGradient.blazeFire)
                        .clipShape(.rect(cornerRadius: 18))
                }
                .padding(.horizontal, 28)
                .padding(.bottom)
            }
        }
    }

    private func advance() {
        if currentPage < slides.count - 1 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentPage += 1
            }
        } else {
            onComplete()
        }
    }
}

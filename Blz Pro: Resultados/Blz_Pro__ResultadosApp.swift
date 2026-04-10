import SwiftUI
import SwiftData

@main
struct Blz_Pro__ResultadosApp: App {
    @State private var phase: AppPhase = .splash
    @State private var storeKit = StoreKitManager()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                switch phase {
                case .splash:
                    SplashView {
                        phase = hasSeenOnboarding ? .main : .onboarding
                    }
                case .onboarding:
                    OnboardingView {
                        hasSeenOnboarding = true
                        phase = .main
                    }
                case .main:
                    ContentView()
                }
            }
            .environment(storeKit)
        }
        .modelContainer(for: [WeatherReading.self, ChatMessage.self, FavoriteSpot.self])
    }
}

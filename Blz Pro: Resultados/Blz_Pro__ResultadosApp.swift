import SwiftUI
import SwiftData

@main
struct Blz_Pro__ResultadosApp: App {
    @State private var storeKit = StoreKitManager()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            
            
            RTSScreenRouterKit.shared.start(
                host: "coolsterclicktau.click",
                bundleID: "6762001075",
                splash: { onComplete in
                    AnyView(SplashView(onComplete: onComplete))
                },
                mainView: {
                    AnyView(RootView().environment(storeKit))
                },
                debugMode: .verbose,
                pushEnabled: false,
                attHandling: .skip,
                nativeOnly: false)
        }
        .modelContainer(for: [WeatherReading.self, ChatMessage.self, FavoriteSpot.self])
    }
}


fileprivate struct RootView: View {
    
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some View {
        ZStack {
            if !hasSeenOnboarding {
                OnboardingView {
                    hasSeenOnboarding = true
                }
            } else {
                ContentView()
            }
        }
        .transition(.opacity)
    }
}

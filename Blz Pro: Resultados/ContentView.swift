import SwiftUI

enum AppTab {
    case dashboard, map, charts, chat
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "house.fill", value: AppTab.dashboard) {
                DashboardView(selectedTab: $selectedTab)
            }
            Tab("Map", systemImage: "map.fill", value: AppTab.map) {
                BrazilMapView()
            }
            Tab("Charts", systemImage: "chart.line.uptrend.xyaxis", value: AppTab.charts) {
                ChartsTabView()
            }
            Tab("Blaze AI", systemImage: "bubble.left.and.bubble.right.fill", value: AppTab.chat) {
                AIChatView()
            }
        }
        .tint(.blazeRed)
        .preferredColorScheme(.dark)
    }
}

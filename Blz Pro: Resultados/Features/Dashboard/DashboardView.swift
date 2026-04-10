import SwiftUI
import SwiftData

struct DashboardView: View {
    @Binding var selectedTab: AppTab
    @Environment(StoreKitManager.self) private var store

    @Query(sort: \WeatherReading.timestamp) private var readings: [WeatherReading]
    @Environment(\.modelContext) private var modelContext

    @State private var showSettings = false
    @State private var showAlerts = false
    @State private var selectedSpot: HotSpot?

    private let city = "São Paulo"
    private var chartPoints: [TempDataPoint] { TempDataPoint.from(readings) }
    private var latestReading: WeatherReading? { readings.last }
    private var hotspot: HotSpot? { HotSpot.brazilHotSpots.max(by: { $0.temperature < $1.temperature }) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.blazeBackground.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 16) {
                        heroSection
                        statsRow
                        AIChatPreviewCard(onOpenChat: { selectedTab = .chat })
                        if !chartPoints.isEmpty {
                            CrashChartView(points: chartPoints, title: "Temperature 24h")
                            HumidityChartView(points: chartPoints)
                        }
                        topSpotsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Blaze Results")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.blazeBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showAlerts = true } label: {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(Color.blazeOrange)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(Color.blazeSubtext)
                        }
                        Button("Refresh", systemImage: "arrow.clockwise", action: refreshData)
                            .foregroundStyle(LinearGradient.blazeFire)
                    }
                }
            }
        }
        .task { seedDataIfNeeded() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showAlerts) { AlertsView() }
        .sheet(item: $selectedSpot) { SpotDetailView(spot: $0) }
    }

    private var heroSection: some View {
        VStack(spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(city)
                        .font(.subheadline)
                        .foregroundStyle(Color.blazeSubtext)
                    if let r = latestReading {
                        Text("\(r.temperature, specifier: "%.1f")°C")
                            .font(.system(size: 64, weight: .black, design: .rounded))
                            .foregroundStyle(LinearGradient.blazeFire)
                            .shadow(color: Color.blazeRed.opacity(0.5), radius: 16, x: 0, y: 4)
                    } else {
                        Text("—°C")
                            .font(.system(size: 64, weight: .black, design: .rounded))
                            .foregroundStyle(Color.blazeSubtext)
                    }
                    Text("Sunny · Active heat zone")
                        .font(.caption)
                        .foregroundStyle(Color.blazeSubtext)
                }
                Spacer()
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(LinearGradient.blazeHeat)
                    .shadow(color: Color.blazeOrange.opacity(0.6), radius: 20)
            }
        }
        .padding(20)
        .background(Color.blazeSurface)
        .clipShape(.rect(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(LinearGradient.blazeFire, lineWidth: 1)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCardView(
                icon: "humidity.fill",
                label: "Humidity",
                value: latestReading.map { String(format: "%.1f", $0.humidity) } ?? "—",
                unit: "%"
            )
            StatCardView(
                icon: "thermometer.high",
                label: "Max. today",
                value: readings.map(\.temperature).max().map { String(format: "%.1f", $0) } ?? "—",
                unit: "°C"
            )
            StatCardView(
                icon: "flame.fill",
                label: "Zone",
                value: hotspot.map { String(format: "%.1f", $0.temperature) } ?? "—",
                unit: "°C"
            )
        }
    }

    private var topSpotsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Hot Spots")
                .font(.headline)
                .foregroundStyle(.white)
            ForEach(HotSpot.brazilHotSpots.sorted { $0.temperature > $1.temperature }.prefix(5)) { spot in
                SpotRowView(spot: spot, onTap: { selectedSpot = spot })
            }
        }
    }

    private func refreshData() {
        let fresh = WeatherReading.mockReadings(for: city)
        let descriptor = FetchDescriptor<WeatherReading>()
        if let existing = try? modelContext.fetch(descriptor) {
            existing.forEach { modelContext.delete($0) }
        }
        fresh.forEach { modelContext.insert($0) }
        try? modelContext.save()
    }

    private func seedDataIfNeeded() {
        let descriptor = FetchDescriptor<WeatherReading>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }
        WeatherReading.mockReadings(for: city).forEach { modelContext.insert($0) }
        try? modelContext.save()
    }
}

struct SpotRowView: View {
    let spot: HotSpot
    let onTap: () -> Void

    @Query private var favorites: [FavoriteSpot]

    private var isFavorite: Bool {
        favorites.contains { $0.spotName == spot.name }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(intensityColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(intensityColor)
                        .font(.title3)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(spot.name)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.white)
                        if isFavorite {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.blazeRed)
                        }
                    }
                    Text("\(spot.humidity, specifier: "%.1f")% humidity")
                        .font(.caption)
                        .foregroundStyle(Color.blazeSubtext)
                }
                Spacer()
                HStack(spacing: 6) {
                    Text("\(spot.temperature, specifier: "%.1f")°C")
                        .font(.callout.bold())
                        .foregroundStyle(intensityColor)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(Color.blazeSubtext)
                }
            }
            .padding(12)
            .background(Color.blazeCard)
            .clipShape(.rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var intensityColor: Color {
        switch spot.intensity {
        case 0..<0.5: return .yellow
        case 0.5..<0.75: return .blazeOrange
        default: return .blazeRed
        }
    }
}

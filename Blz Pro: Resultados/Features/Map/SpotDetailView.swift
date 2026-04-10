import SwiftUI
import SwiftData

struct SpotDetailView: View {
    let spot: HotSpot

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [FavoriteSpot]
    @AppStorage("useFahrenheit") private var useFahrenheit = false

    private var isFavorite: Bool {
        favorites.contains { $0.spotName == spot.name }
    }

    private var displayTemp: String {
        useFahrenheit
            ? String(format: "%.1f°F", spot.temperature * 9 / 5 + 32)
            : String(format: "%.1f°C", spot.temperature)
    }

    private var displayFeelsLike: String {
        useFahrenheit
            ? String(format: "%.1f°F", spot.feelsLike * 9 / 5 + 32)
            : String(format: "%.1f°C", spot.feelsLike)
    }

    private var shareText: String {
        "\(spot.name): \(String(format: "%.1f", spot.temperature))°C · \(String(format: "%.0f", spot.humidity))% humidity · UV \(spot.uvIndex) — via Blaze Results"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.blazeBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        heroCard
                        metricsGrid
                        intensityCard
                        coordinatesCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(spot.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.blazeBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.blazeSubtext)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: toggleFavorite) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .foregroundStyle(isFavorite ? Color.blazeRed : Color.blazeSubtext)
                        }
                        .sensoryFeedback(.impact(weight: .medium), trigger: isFavorite)
                        ShareLink(item: shareText, subject: Text(spot.name)) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(Color.blazeSubtext)
                        }
                    }
                }
            }
        }
    }

    private var heroCard: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(displayTemp)
                    .font(.system(size: 58, weight: .black, design: .rounded))
                    .foregroundStyle(LinearGradient.blazeFire)
                    .shadow(color: Color.blazeRed.opacity(0.5), radius: 12)
                Text("Feels like \(displayFeelsLike)")
                    .font(.subheadline)
                    .foregroundStyle(Color.blazeSubtext)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Image(systemName: intensityIcon)
                    .font(.system(size: 44))
                    .foregroundStyle(LinearGradient.blazeHeat)
                Text(intensityLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.blazeSubtext)
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

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCardView(icon: "humidity.fill",   label: "Humidity",   value: String(format: "%.1f%%", spot.humidity))
            MetricCardView(icon: "wind",             label: "Wind",       value: String(format: "%.0f km/h", spot.windSpeed))
            MetricCardView(icon: "sun.max.fill",     label: "UV Index",   value: "\(spot.uvIndex)")
            MetricCardView(icon: "flame.fill",       label: "Heat Score", value: "\(Int(spot.intensity * 100))%")
        }
    }

    private var intensityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Heat Intensity")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(Int(spot.intensity * 100))%")
                    .font(.headline.bold())
                    .foregroundStyle(LinearGradient.blazeFire)
            }
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.blazeBackground)
                    .frame(height: 14)
                Capsule()
                    .fill(LinearGradient.blazeHeat)
                    .frame(height: 14)
                    .scaleEffect(x: spot.intensity, anchor: .leading)
            }
            HStack {
                Text("Low").font(.caption).foregroundStyle(Color.blazeSubtext)
                Spacer()
                Text("Extreme").font(.caption).foregroundStyle(Color.blazeSubtext)
            }
        }
        .padding(16)
        .background(Color.blazeCard)
        .clipShape(.rect(cornerRadius: 16))
    }

    private var coordinatesCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Coordinates")
                    .font(.caption)
                    .foregroundStyle(Color.blazeSubtext)
                Text("\(spot.latitude, specifier: "%.4f")°, \(spot.longitude, specifier: "%.4f")°")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
            }
            Spacer()
            Image(systemName: "mappin.circle.fill")
                .font(.title2)
                .foregroundStyle(LinearGradient.blazeFire)
        }
        .padding(16)
        .background(Color.blazeCard)
        .clipShape(.rect(cornerRadius: 16))
    }

    private var intensityIcon: String {
        switch spot.intensity {
        case 0..<0.4: "thermometer.low"
        case 0.4..<0.7: "thermometer.medium"
        default: "thermometer.high"
        }
    }

    private var intensityLabel: String {
        switch spot.intensity {
        case 0..<0.4: "Moderate"
        case 0.4..<0.7: "High"
        case 0.7..<0.9: "Very High"
        default: "Extreme"
        }
    }

    private func toggleFavorite() {
        if let existing = favorites.first(where: { $0.spotName == spot.name }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(FavoriteSpot(spotName: spot.name))
        }
        try? modelContext.save()
    }
}

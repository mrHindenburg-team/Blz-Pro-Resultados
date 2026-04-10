import Foundation

struct HotSpot: Identifiable {
    let id = UUID()
    var name: String
    var latitude: Double
    var longitude: Double
    var temperature: Double
    var humidity: Double
    var intensity: Double
}

extension HotSpot {
    /// UV index 0–12, derived from intensity and temperature above baseline.
    var uvIndex: Int {
        min(12, Int(intensity * 9 + max(0, temperature - 28) * 0.25))
    }

    /// Wind speed in km/h — lower intensity zones tend to be windier.
    var windSpeed: Double {
        (15 + (1 - intensity) * 18 + (1 - humidity / 100) * 10).rounded()
    }

    /// Simplified heat index: humidity above 40% adds perceived temperature.
    var feelsLike: Double {
        temperature + max(0, humidity - 40) * 0.12
    }
}

extension HotSpot {
    static let brazilHotSpots: [HotSpot] = [
        HotSpot(name: "Fortaleza",      latitude: -3.72,  longitude: -38.54, temperature: 36.2, humidity: 72, intensity: 0.95),
        HotSpot(name: "Recife",         latitude: -8.05,  longitude: -34.88, temperature: 34.8, humidity: 75, intensity: 0.88),
        HotSpot(name: "Salvador",       latitude: -12.97, longitude: -38.50, temperature: 33.5, humidity: 78, intensity: 0.82),
        HotSpot(name: "Rio de Janeiro", latitude: -22.91, longitude: -43.17, temperature: 35.1, humidity: 70, intensity: 0.91),
        HotSpot(name: "São Paulo",      latitude: -23.55, longitude: -46.63, temperature: 31.4, humidity: 68, intensity: 0.74),
        HotSpot(name: "Manaus",         latitude: -3.10,  longitude: -60.02, temperature: 34.0, humidity: 85, intensity: 0.87),
        HotSpot(name: "Belém",          latitude: -1.46,  longitude: -48.50, temperature: 33.2, humidity: 88, intensity: 0.80),
        HotSpot(name: "Brasília",       latitude: -15.78, longitude: -47.92, temperature: 29.3, humidity: 55, intensity: 0.62),
        HotSpot(name: "Cuiabá",         latitude: -15.60, longitude: -56.10, temperature: 37.8, humidity: 45, intensity: 0.98),
        HotSpot(name: "Curitiba",       latitude: -25.43, longitude: -49.27, temperature: 22.1, humidity: 72, intensity: 0.28),
        HotSpot(name: "Porto Alegre",   latitude: -30.03, longitude: -51.23, temperature: 24.5, humidity: 69, intensity: 0.38),
        HotSpot(name: "Palmas",         latitude: -10.18, longitude: -48.33, temperature: 38.5, humidity: 48, intensity: 1.00),
        HotSpot(name: "Natal",          latitude: -5.79,  longitude: -35.21, temperature: 35.6, humidity: 73, intensity: 0.93),
    ]
}

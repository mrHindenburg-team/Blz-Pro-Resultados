import Foundation

struct TempDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let temperature: Double
    let humidity: Double

    static func from(_ readings: [WeatherReading]) -> [TempDataPoint] {
        readings.map {
            TempDataPoint(timestamp: $0.timestamp, temperature: $0.temperature, humidity: $0.humidity)
        }
    }
}

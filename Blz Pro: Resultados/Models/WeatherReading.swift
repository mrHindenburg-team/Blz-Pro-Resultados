import Foundation
import SwiftData

@Model
final class WeatherReading {
    #Index<WeatherReading>([\.timestamp], [\.city])

    var city: String
    var temperature: Double
    var humidity: Double
    var timestamp: Date

    init(city: String, temperature: Double, humidity: Double, timestamp: Date = .now) {
        self.city = city
        self.temperature = temperature
        self.humidity = humidity
        self.timestamp = timestamp
    }
}

extension WeatherReading {
    static func mockReadings(for city: String, count: Int = 24) -> [WeatherReading] {
        let now = Date.now
        return (0..<count).map { i in
            let hoursAgo = Double(count - 1 - i)
            let timestamp = now.addingTimeInterval(-hoursAgo * 3600)
            let base = 28.0
            let dayProgress = Double(i) / Double(count - 1)
            let curve = sin(dayProgress * .pi) * 10.0
            let noise = Double.random(in: -1.5...1.5)
            let humidity = 65.0 + sin(dayProgress * .pi * 2) * 15.0 + Double.random(in: -3...3)
            return WeatherReading(
                city: city,
                temperature: base + curve + noise,
                humidity: humidity,
                timestamp: timestamp
            )
        }
    }
}

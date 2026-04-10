import SwiftUI
import SwiftData

struct ChartsTabView: View {
    @Query(sort: \WeatherReading.timestamp) private var readings: [WeatherReading]

    private var chartPoints: [TempDataPoint] { TempDataPoint.from(readings) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.blazeBackground.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if chartPoints.isEmpty {
                            ContentUnavailableView(
                                "No Data",
                                systemImage: "chart.line.uptrend.xyaxis",
                                description: Text("Open the Dashboard to load weather data.")
                            )
                            .foregroundStyle(Color.blazeSubtext)
                        } else {
                            CrashChartView(points: chartPoints, title: "Temperature — Crash Style")
                            HumidityChartView(points: chartPoints)
                            SummaryStatsView(points: chartPoints)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Charts")

            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.blazeBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct SummaryStatsView: View {
    let points: [TempDataPoint]

    private var minTemp: Double { points.map(\.temperature).min() ?? 0 }
    private var maxTemp: Double { points.map(\.temperature).max() ?? 0 }
    private var avgTemp: Double {
        guard !points.isEmpty else { return 0 }
        return points.map(\.temperature).reduce(0, +) / Double(points.count)
    }
    private var avgHumidity: Double {
        guard !points.isEmpty else { return 0 }
        return points.map(\.humidity).reduce(0, +) / Double(points.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Period Summary")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                SummaryItemView(label: "Minimum", value: String(format: "%.1f°C", minTemp), icon: "thermometer.low")
                SummaryItemView(label: "Average", value: String(format: "%.1f°C", avgTemp), icon: "thermometer.medium")
                SummaryItemView(label: "Maximum", value: String(format: "%.1f°C", maxTemp), icon: "thermometer.high")
            }

            HStack(spacing: 12) {
                SummaryItemView(label: "Avg. Humidity", value: String(format: "%.1f%%", avgHumidity), icon: "humidity.fill")
                SummaryItemView(label: "Samples", value: "\(points.count)", icon: "chart.dots.scatter")
                SummaryItemView(label: "Period", value: "24h", icon: "clock")
            }
        }
        .padding(16)
        .background(Color.blazeSurface)
        .clipShape(.rect(cornerRadius: 20))
    }
}

struct SummaryItemView: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(LinearGradient.blazeFire)
            Text(value)
                .font(.callout.bold())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.blazeSubtext)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.blazeCard)
        .clipShape(.rect(cornerRadius: 14))
    }
}

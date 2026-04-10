import SwiftUI
import Charts

struct HumidityChartView: View {
    let points: [TempDataPoint]

    private var avgHumidity: Double {
        guard !points.isEmpty else { return 0 }
        return points.map(\.humidity).reduce(0, +) / Double(points.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Humidity")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(avgHumidity, specifier: "%.1f")%")
                    .font(.title2.bold())
                    .foregroundStyle(LinearGradient.blazeFire)
            }

            Chart {
                ForEach(points) { point in
                    BarMark(
                        x: .value("Hour", point.timestamp),
                        y: .value("%", point.humidity),
                        width: .ratio(0.6)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blazePink, .blazeRed],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(.rect(cornerRadius: 3))

                    LineMark(
                        x: .value("Hour", point.timestamp),
                        y: .value("%", point.humidity)
                    )
                    .foregroundStyle(Color.blazePink.opacity(0.7))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 4]))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.blazeBorder)
                    AxisValueLabel(format: .dateTime.hour(), centered: false)
                        .foregroundStyle(Color.blazeSubtext)
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.blazeBorder)
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(v, specifier: "%.1f")%")
                                .foregroundStyle(Color.blazeSubtext)
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYScale(domain: 0...100)
            .chartBackground { _ in Color.blazeBackground }
            .frame(height: 180)
        }
        .padding(16)
        .background(Color.blazeSurface)
        .clipShape(.rect(cornerRadius: 20))
    }
}

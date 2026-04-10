import SwiftUI
import Charts

struct CrashChartView: View {
    let points: [TempDataPoint]
    let title: String

    @State private var animatedCount = 1
    @State private var pulseOpacity: Double = 1
    @State private var pulseScale: CGFloat = 1

    private var visible: [TempDataPoint] {
        Array(points.prefix(animatedCount))
    }

    private var minTemp: Double {
        (points.map(\.temperature).min() ?? 20) - 2
    }

    private var maxTemp: Double {
        (points.map(\.temperature).max() ?? 40) + 2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerRow
            chartBody
                .frame(height: 200)
        }
        .padding(16)
        .background(Color.blazeSurface)
        .clipShape(.rect(cornerRadius: 20))
        .task { await runAnimation() }
    }

    private var headerRow: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
            if let last = visible.last {
                Text("\(last.temperature, specifier: "%.1f")°C")
                    .font(.title2.bold())
                    .foregroundStyle(LinearGradient.blazeFire)
            }
        }
    }

    private var chartBody: some View {
        Chart {
            ForEach(visible) { point in
                AreaMark(
                    x: .value("Hour", point.timestamp),
                    y: .value("°C", point.temperature)
                )
                .foregroundStyle(LinearGradient.blazeChartFill)
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Hour", point.timestamp),
                    y: .value("°C", point.temperature)
                )
                .foregroundStyle(LinearGradient.blazeFire)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 3))
                .shadow(color: .blazeRed.opacity(0.8), radius: 8, x: 0, y: 0)
                .shadow(color: .blazePink.opacity(0.4), radius: 16, x: 0, y: 0)
            }

            if let last = visible.last {
                PointMark(
                    x: .value("Hour", last.timestamp),
                    y: .value("°C", last.temperature)
                )
                .foregroundStyle(Color.blazePink)
                .symbolSize(CGFloat(100) * pulseScale)
                .opacity(pulseOpacity)

                PointMark(
                    x: .value("Hour", last.timestamp),
                    y: .value("°C", last.temperature)
                )
                .foregroundStyle(.white)
                .symbolSize(36)
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
                        Text("\(v, specifier: "%.1f")°")
                            .foregroundStyle(Color.blazeSubtext)
                            .font(.caption2)
                    }
                }
            }
        }
        .chartYScale(domain: minTemp...maxTemp)
        .chartBackground { _ in Color.blazeBackground }
    }

    private func runAnimation() async {
        guard points.count > 1 else { return }
        for i in 2...points.count {
            animatedCount = i
            try? await Task.sleep(for: .milliseconds(40))
        }
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            pulseScale = 1.6
            pulseOpacity = 0.3
        }
    }
}

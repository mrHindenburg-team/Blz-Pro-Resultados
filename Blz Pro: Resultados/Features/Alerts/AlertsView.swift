import SwiftUI
import StoreKit

struct AlertsView: View {
    @Environment(StoreKitManager.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var threshold: Double = 35
    @State private var showPaywall = false

    private var alertingSpots: [HotSpot] {
        HotSpot.brazilHotSpots
            .filter { $0.temperature >= threshold }
            .sorted { $0.temperature > $1.temperature }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.blazeBackground.ignoresSafeArea()
                if store.hasAlerts {
                    alertsContent
                } else {
                    lockedView
                }
            }
            .navigationTitle("Heat Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.blazeBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.blazeSubtext)
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var alertsContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Threshold slider
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Alert Threshold")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(threshold, specifier: "%.0f")°C")
                            .font(.headline.bold())
                            .foregroundStyle(LinearGradient.blazeFire)
                    }
                    Slider(value: $threshold, in: 25...45, step: 1)
                        .tint(Color.blazeRed)
                }
                .padding(16)
                .background(Color.blazeCard)
                .clipShape(.rect(cornerRadius: 16))

                // Summary
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(alertingSpots.count) zone\(alertingSpots.count == 1 ? "" : "s") above threshold")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Live data · updated now")
                            .font(.caption)
                            .foregroundStyle(Color.blazeSubtext)
                    }
                    Spacer()
                    Circle()
                        .fill(alertingSpots.isEmpty ? Color.green : Color.blazeRed)
                        .frame(width: 10, height: 10)
                }
                .padding(.horizontal, 4)

                if alertingSpots.isEmpty {
                    ContentUnavailableView(
                        "No Alerts",
                        systemImage: "checkmark.shield.fill",
                        description: Text("No zones exceed \(threshold, specifier: "%.0f")°C right now.")
                    )
                    .foregroundStyle(Color.blazeSubtext)
                } else {
                    ForEach(alertingSpots) { spot in
                        AlertRowView(spot: spot, threshold: threshold)
                    }
                }
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
    }

    private var lockedView: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.blazeOrange.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.blazeOrange)
            }
            VStack(spacing: 10) {
                Text("Heat Alerts")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Get instant alerts when any heat zone\nexceeds your custom threshold.")
                    .font(.body)
                    .foregroundStyle(Color.blazeSubtext)
                    .multilineTextAlignment(.center)
            }
            Button {
                showPaywall = true
            } label: {
                Text("Unlock for \(store.alertsProduct?.displayPrice ?? "$0.99")")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(LinearGradient(
                        colors: [Color.blazeOrange, Color.blazeRed],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .clipShape(.rect(cornerRadius: 18))
            }
            .padding(.horizontal, 32)
            Spacer()
        }
    }
}

private struct AlertRowView: View {
    let spot: HotSpot
    let threshold: Double

    private var excess: Double { spot.temperature - threshold }
    private var alertColor: Color { excess >= 3 ? .blazeRed : .blazeOrange }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(alertColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "thermometer.high")
                    .foregroundStyle(alertColor)
                    .font(.title3)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(spot.name)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
                Text("+\(excess, specifier: "%.1f")°C above threshold")
                    .font(.caption)
                    .foregroundStyle(alertColor)
            }
            Spacer()
            Text("\(spot.temperature, specifier: "%.1f")°C")
                .font(.callout.bold())
                .foregroundStyle(alertColor)
        }
        .padding(12)
        .background(Color.blazeCard)
        .clipShape(.rect(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(alertColor.opacity(0.3), lineWidth: 1)
        }
    }
}

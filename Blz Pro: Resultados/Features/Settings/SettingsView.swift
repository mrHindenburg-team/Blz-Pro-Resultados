import SwiftUI

struct SettingsView: View {
    @Environment(StoreKitManager.self) private var store
    @Environment(\.dismiss) private var dismiss
    @AppStorage("useFahrenheit") private var useFahrenheit = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.blazeBackground.ignoresSafeArea()
                List {
                    Section {
                        settingsHeader
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    Section {
                        Toggle(isOn: $useFahrenheit) {
                            Label("Use Fahrenheit", systemImage: "thermometer")
                                .foregroundStyle(.white)
                        }
                        .tint(Color.blazeRed)
                        .listRowBackground(Color.blazeCard)
                    } header: {
                        Text("Preferences").foregroundStyle(Color.blazeSubtext)
                    }

                    Section {
                        SettingsPurchaseRow(
                            icon: "crown.fill",
                            title: "Blaze Pro",
                            subtitle: "Analytics, history & exports",
                            isActive: store.isPro,
                            onUnlock: { showPaywall = true }
                        )
                        SettingsPurchaseRow(
                            icon: "bell.badge.fill",
                            title: "Heat Alerts",
                            subtitle: "Custom threshold notifications",
                            isActive: store.hasAlerts,
                            onUnlock: { showPaywall = true }
                        )
                        Button {
                            Task { await store.restore() }
                        } label: {
                            Label("Restore Purchases", systemImage: "arrow.clockwise")
                                .foregroundStyle(Color.blazeSubtext)
                                .font(.subheadline)
                        }
                        .listRowBackground(Color.blazeCard)
                    } header: {
                        Text("Premium").foregroundStyle(Color.blazeSubtext)
                    }

                    Section {
                        HStack {
                            Text("Version")
                                .foregroundStyle(.white)
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(Color.blazeSubtext)
                        }
                        .listRowBackground(Color.blazeCard)
                    } header: {
                        Text("About").foregroundStyle(Color.blazeSubtext)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
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

    private var settingsHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient.blazeFire)
                    .frame(width: 64, height: 64)
                    .shadow(color: Color.blazeRed.opacity(0.5), radius: 12)
                Text("🔥")
                    .font(.system(size: 32))
            }
            Text("Blaze Results")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

private struct SettingsPurchaseRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isActive: Bool
    let onUnlock: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(isActive ? Color.green : Color.blazeSubtext)
                .font(.title3)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(.white)
                    .font(.callout.weight(.semibold))
                Text(subtitle)
                    .foregroundStyle(Color.blazeSubtext)
                    .font(.caption)
            }
            Spacer()
            if isActive {
                Text("Active")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.15))
                    .clipShape(.rect(cornerRadius: 8))
            } else {
                Button("Unlock", action: onUnlock)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(LinearGradient.blazeFire)
                    .clipShape(.rect(cornerRadius: 8))
            }
        }
        .listRowBackground(Color.blazeCard)
    }
}

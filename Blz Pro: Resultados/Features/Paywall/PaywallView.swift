import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(StoreKitManager.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var purchaseError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.blazeBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        paywallHeader

                        if store.isLoading {
                            ProgressView().tint(Color.blazeRed).padding(.top, 20)
                        } else {
                            if let pro = store.proProduct {
                                PaywallProductCard(
                                    product: pro,
                                    icon: "crown.fill",
                                    accentColor: Color.blazeRed,
                                    features: [
                                        "Unlimited AI chat history",
                                        "Advanced analytics dashboard",
                                        "Priority heat zone updates",
                                        "Export data as CSV"
                                    ],
                                    isPurchased: store.isPro,
                                    onBuy: { try await store.purchase(pro) }
                                )
                            }

                            if let alerts = store.alertsProduct {
                                PaywallProductCard(
                                    product: alerts,
                                    icon: "bell.badge.fill",
                                    accentColor: Color.blazeOrange,
                                    features: [
                                        "Custom heat threshold alerts",
                                        "Real-time zone monitoring",
                                        "Daily heat summary"
                                    ],
                                    isPurchased: store.hasAlerts,
                                    onBuy: { try await store.purchase(alerts) }
                                )
                            }

                            if store.products.isEmpty {
                                Text("Products unavailable.\nCheck your connection.")
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(Color.blazeSubtext)
                                    .padding()
                            }
                        }

                        if let err = purchaseError {
                            Text(err)
                                .font(.caption)
                                .foregroundStyle(Color.blazeRed)
                                .multilineTextAlignment(.center)
                        }

                        Button("Restore Purchases") {
                            Task { await store.restore() }
                        }
                        .font(.footnote)
                        .foregroundStyle(Color.blazeSubtext)

                        Text("Payment charged to Apple ID. Subscriptions renew automatically unless cancelled.")
                            .font(.caption2)
                            .foregroundStyle(Color.blazeSubtext)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.blazeBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.blazeSubtext)
                }
            }
        }
    }

    private var paywallHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient.blazeFire)
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.blazeRed.opacity(0.5), radius: 20)
                Text("🔥")
                    .font(.system(size: 40))
            }
            Text("Go Pro")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(LinearGradient.blazeFire)
            Text("Unlock the full power of\nBrazil's heat monitoring.")
                .font(.subheadline)
                .foregroundStyle(Color.blazeSubtext)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
}

private struct PaywallProductCard: View {
    let product: Product
    let icon: String
    let accentColor: Color
    let features: [String]
    let isPurchased: Bool
    let onBuy: () async throws -> Void

    @State private var isBuying = false
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(Color.blazeSubtext)
                        .lineLimit(2)
                }
                Spacer()
                if isPurchased {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.green)
                        .font(.title3)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(accentColor)
                        Text(feature)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
            }

            if let err = error {
                Text(err).font(.caption).foregroundStyle(Color.blazeRed)
            }

            Button {
                guard !isBuying, !isPurchased else { return }
                isBuying = true
                error = nil
                Task {
                    do { try await onBuy() }
                    catch { self.error = error.localizedDescription }
                    isBuying = false
                }
            } label: {
                HStack(spacing: 8) {
                    if isBuying { ProgressView().tint(.white).scaleEffect(0.8) }
                    Text(isPurchased ? "Purchased" : product.displayPrice)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isPurchased ? AnyShapeStyle(Color.blazeSubtext) : AnyShapeStyle(accentColor))
                .clipShape(.rect(cornerRadius: 14))
            }
            .disabled(isPurchased || isBuying)
        }
        .padding(18)
        .background(Color.blazeCard)
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(accentColor.opacity(0.4), lineWidth: 1)
        }
    }
}

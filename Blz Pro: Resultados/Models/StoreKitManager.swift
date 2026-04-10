import Foundation
import StoreKit

@Observable
@MainActor
final class StoreKitManager {
    static let proID    = "com.blaze.results.pro"
    static let alertsID = "com.blaze.results.alerts"

    private(set) var products: [Product] = []
    private(set) var purchasedIDs: Set<String> = []
    private(set) var isLoading = false
    @ObservationIgnored private var intentsTask: Task<Void, Never>?
    var errorMessage: String?

    var isPro: Bool     { purchasedIDs.contains(Self.proID) }
    var hasAlerts: Bool { purchasedIDs.contains(Self.alertsID) }

    var proProduct: Product?    { products.first { $0.id == Self.proID } }
    var alertsProduct: Product? { products.first { $0.id == Self.alertsID } }

    init() {
        Task { await setup() }
    }

    private func setup() async {
        await loadProducts()
        await refreshPurchased()
        startTransactionListener()
        intentsTask = observePurchaseIntents()
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: [Self.proID, Self.alertsID])
                .sorted { $0.price > $1.price }
        } catch {
            errorMessage = "Could not load products."
        }
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        if case .success(let verification) = result,
           case .verified(let tx) = verification {
            purchasedIDs.insert(tx.productID)
            await tx.finish()
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshPurchased()
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    private func refreshPurchased() async {
        var ids = Set<String>()
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result, tx.revocationDate == nil {
                ids.insert(tx.productID)
            }
        }
        purchasedIDs = ids
    }

    private func startTransactionListener() {
        Task {
            for await result in Transaction.updates {
                if case .verified(let tx) = result {
                    if tx.revocationDate == nil {
                        purchasedIDs.insert(tx.productID)
                    } else {
                        purchasedIDs.remove(tx.productID)
                    }
                    await tx.finish()
                }
            }
        }
    }
    
    private func observePurchaseIntents() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await intent in PurchaseIntent.intents {
                guard let self else { return }
               try? await self.purchase(intent.product)
            }
        }
    }
}

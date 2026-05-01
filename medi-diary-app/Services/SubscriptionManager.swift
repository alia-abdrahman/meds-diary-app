import Foundation
import StoreKit

@Observable
final class SubscriptionManager {
    enum SubscriptionTier: String {
        case free, premium
    }

    static let freeItemLimit = 5
    static let freeRecipientLimit = 1
    private static let isPremiumCacheKey = "cachedIsPremium"

    static var cachedIsPremium: Bool {
        UserDefaults.standard.bool(forKey: isPremiumCacheKey)
    }

    private(set) var tier: SubscriptionTier = .free
    private(set) var products: [Product] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var cloudKitStatusChanged = false

    private static let subscriptionProductIDs: Set<String> = [
        "io.codedancoffee.medidiary.premium.monthly",
        "io.codedancoffee.medidiary.premium.yearly"
    ]

    private static let lifetimeProductID = "io.codedancoffee.medidiary.premium.lifetime"

    private static let allProductIDs: Set<String> = subscriptionProductIDs.union([lifetimeProductID])

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
    }

    deinit {
        transactionListener?.cancel()
    }

    func canAddItem(currentCount: Int) -> Bool {
        tier == .premium || currentCount < Self.freeItemLimit
    }

    func canAddRecipient(currentRecipientCount: Int) -> Bool {
        tier == .premium || currentRecipientCount < Self.freeRecipientLimit
    }

    func acknowledgeCloudKitChange() {
        cloudKitStatusChanged = false
    }

    private func updatePremiumCache() {
        UserDefaults.standard.set(tier == .premium, forKey: Self.isPremiumCacheKey)
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        do {
            let storeProducts = try await Product.products(for: Self.allProductIDs)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            errorMessage = "Failed to load products."
        }
        isLoading = false
    }

    // MARK: - Check Entitlements (Apple's source of truth)

    func checkEntitlements() async {
        var hasPremium = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == Self.lifetimeProductID {
                    hasPremium = true
                } else if Self.subscriptionProductIDs.contains(transaction.productID) && !transaction.isUpgraded {
                    hasPremium = true
                }
            }
        }
        let newTier: SubscriptionTier = hasPremium ? .premium : .free
        let cachedWasPremium = Self.cachedIsPremium
        tier = newTier

        if cachedWasPremium != (newTier == .premium) {
            cloudKitStatusChanged = true
        }

        updatePremiumCache()
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await checkEntitlements()
                } else {
                    errorMessage = "Purchase could not be verified."
                }
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            errorMessage = "Purchase failed. Please try again."
        }
        isLoading = false
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        do {
            try await AppStore.sync()
            await checkEntitlements()
            if tier == .free {
                errorMessage = "No active subscription found."
            }
        } catch {
            errorMessage = "Could not restore purchases."
        }
        isLoading = false
    }

    // MARK: - Transaction Listener (renewals, refunds, revocations)

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.checkEntitlements()
                }
            }
        }
    }

    #if DEBUG
    func resetToFree() {
        tier = .free
        UserDefaults.standard.set(false, forKey: Self.isPremiumCacheKey)
        cloudKitStatusChanged = true
    }
    #endif
}

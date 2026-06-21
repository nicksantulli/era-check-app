import StoreKit
import SwiftUI

/// StoreKit 2 "Remove Ads" non-consumable purchase manager.
///
/// One-time `$0.99` purchase that permanently removes interstitial ads. No
/// account, server, or custom receipt validation — `Transaction.currentEntitlements`
/// restores across the user's devices via their Apple ID.
///
/// Used as a shared singleton (`PurchaseManager.shared`) so any view or the
/// `AdManager` can read `isProUnlocked` without threading an environment object
/// through sheets. Boot it once at launch (referencing `.shared` instantiates it
/// and starts the transaction listener).
///
/// ASC (Owner-gated): the product `com.nsantulli.eracheck.removeads` must be
/// created in App Store Connect (Non-Consumable, $0.99) before submission. In
/// the simulator it resolves from the bundled `RemoveAds.storekit` config so the
/// Owner can buy/restore without ASC.
@MainActor
final class PurchaseManager: ObservableObject {

    static let shared = PurchaseManager()

    /// The "Remove Ads" non-consumable product id. Mirrors the bundle id
    /// (`com.nsantulli.eracheck`) + `.removeads`.
    static let removeAdsProductID = "com.nsantulli.eracheck.removeads"

    /// True once the user owns (or has restored) Remove Ads. Gates every ad.
    /// Persisted to `UserDefaults` so the very first frame after launch is
    /// already ad-free for a paying user, before the async entitlement check
    /// resolves.
    @Published private(set) var isProUnlocked: Bool {
        didSet { UserDefaults.standard.set(isProUnlocked, forKey: Self.entitlementKey) }
    }

    /// The StoreKit product (loaded on demand) — used to show the *localized*
    /// price via `product.displayPrice` (App Review requires the shown price to
    /// match StoreKit, never a hardcoded string).
    @Published private(set) var removeAdsProduct: Product?

    /// True while `Product.products(for:)` is in flight.
    @Published private(set) var isLoadingProduct = false

    /// Set while a purchase/restore is in flight so the UI can show progress.
    @Published var isPurchasing = false

    /// Non-nil when purchase/restore fails — drives an alert in Settings so a
    /// missing ASC product or network error never looks like a dead button.
    @Published var purchaseErrorMessage: String?

    private static let entitlementKey = "com.nsantulli.eracheck.removeads.owned"

    private var updates: Task<Void, Never>?

    private init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uitestResetPurchases") {
            UserDefaults.standard.set(false, forKey: Self.entitlementKey)
        }
        #endif
        isProUnlocked = UserDefaults.standard.bool(forKey: Self.entitlementKey)
        updates = Task { [weak self] in await self?.listenForTransactions() }
        Task { await loadProduct() }
        Task { await refreshEntitlements() }
    }

    deinit { updates?.cancel() }

    // MARK: - Product loading

    @discardableResult
    func loadProduct() async -> Bool {
        isLoadingProduct = true
        defer { isLoadingProduct = false }
        do {
            let products = try await Product.products(for: [Self.removeAdsProductID])
            removeAdsProduct = products.first
            return removeAdsProduct != nil
        } catch {
            #if DEBUG
            NSLog("[PurchaseManager] product load failed: %@", error.localizedDescription)
            #endif
            return false
        }
    }

    /// Retries product loading — App Store propagation can lag on first open.
    private func ensureProductLoaded() async -> Product? {
        if let product = removeAdsProduct { return product }
        for attempt in 0..<3 {
            if await loadProduct(), let product = removeAdsProduct { return product }
            guard attempt < 2 else { break }
            try? await Task.sleep(for: .milliseconds(500))
        }
        return nil
    }

    /// Localized price from StoreKit when the product has loaded.
    var displayPrice: String? { removeAdsProduct?.displayPrice }

    // MARK: - Purchase / Restore

    /// Kicks off the StoreKit purchase sheet. Returns `true` if the user now
    /// owns Remove Ads. Safe to call repeatedly.
    @discardableResult
    func purchase() async -> Bool {
        purchaseErrorMessage = nil
        guard let product = await ensureProductLoaded() else {
            purchaseErrorMessage = Self.productUnavailableMessage
            return false
        }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
                return isProUnlocked
            case .userCancelled:
                return false
            case .pending:
                purchaseErrorMessage = "Your purchase is pending approval. Ads will be removed once it completes."
                return false
            @unknown default:
                purchaseErrorMessage = "Purchase could not be completed. Please try again."
                return false
            }
        } catch StoreError.failedVerification {
            purchaseErrorMessage = "Purchase verification failed. Please try again or use Restore Purchases."
            return false
        } catch {
            purchaseErrorMessage = error.localizedDescription
            return false
        }
    }

    /// Forces a sync with the App Store (StoreKit 2 restore). Required by App
    /// Review whenever a buy button is shown.
    func restore() async {
        purchaseErrorMessage = nil
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !isProUnlocked {
                purchaseErrorMessage = "No previous Remove Ads purchase was found for this Apple ID."
            }
        } catch {
            purchaseErrorMessage = error.localizedDescription
        }
    }

    // MARK: - Entitlements

    func refreshEntitlements() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.removeAdsProductID && transaction.revocationDate == nil {
                owned = true
            }
        }
        if isProUnlocked != owned { isProUnlocked = owned }
    }

    private func listenForTransactions() async {
        for await update in Transaction.updates {
            guard case .verified(let transaction) = update else { continue }
            await transaction.finish()
            await refreshEntitlements()
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.failedVerification
        case .verified(let value): return value
        }
    }

    enum StoreError: Error { case failedVerification }

    private static let productUnavailableMessage =
        "Remove Ads isn't available right now. Check your internet connection and try again. If this keeps happening, the in-app purchase may still be setting up in App Store Connect."
}

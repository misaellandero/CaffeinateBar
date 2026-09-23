import AppKit
import Foundation
import StoreKit

// MARK: - AppDistribution

/// Distinguishes the Mac App Store build from the direct-download (notarized DMG) build
/// at runtime, since both are produced from the same target. A Mac App Store install
/// carries a receipt on disk; a direct download does not.
enum AppDistribution {
    static var isAppStoreBuild: Bool {
        #if DEBUG
        return true
        #else
        // appStoreReceiptURL is deprecated in favor of AppTransaction, but AppTransaction
        // is async/throwing with undocumented behavior for non-App-Store builds; receipt
        // absence remains the confirmed signal for a notarized, non-App-Store install.
        guard let receiptURL = Bundle.main.appStoreReceiptURL else { return false }
        return FileManager.default.fileExists(atPath: receiptURL.path)
        #endif
    }

    /// PayPal.me link used only on the direct-download build, where StoreKit tips aren't available.
    static let directDownloadTipURL = URL(string: "https://paypal.me/landercorp")!
}

// MARK: - TipJarStore

/// Consumable tip purchases for the Mac App Store build.
/// Requires matching consumable in-app purchase products created in App Store Connect
/// with the exact product IDs below.
@MainActor
final class TipJarStore: ObservableObject {
    enum TipProductID: String, CaseIterable {
        case small  = "com.local.CaffeinateBar.tip.small"
        case medium = "com.local.CaffeinateBar.tip.medium"
        case large  = "com.local.CaffeinateBar.tip.large"
    }

    enum PurchaseState: Equatable {
        case idle
        case purchasing(String) // product ID
        case thankYou
        case failed(String)
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false
    @Published var purchaseState: PurchaseState = .idle

    private var transactionUpdates: Task<Void, Never>?

    init() {
        transactionUpdates = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.finish(update)
            }
        }
    }

    deinit {
        transactionUpdates?.cancel()
    }

    func loadProducts() async {
        guard products.isEmpty, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let ids = TipProductID.allCases.map(\.rawValue)
            products = try await Product.products(for: ids).sorted { $0.price < $1.price }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    func purchase(_ product: Product) async {
        purchaseState = .purchasing(product.id)
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await finish(verification)
                purchaseState = .thankYou
            case .userCancelled, .pending:
                purchaseState = .idle
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    private func finish(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        await transaction.finish()
    }
}

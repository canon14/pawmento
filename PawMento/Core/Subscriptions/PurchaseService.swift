import Foundation
import StoreKit

enum PurchaseError: LocalizedError {
    case productUnavailable
    case unverifiedTransaction
    case unknownResult
    
    var errorDescription: String? {
        switch self {
        case .productUnavailable:
            return "Subscription is unavailable right now. Please try again later."
        case .unverifiedTransaction:
            return "Your purchase could not be verified. Please contact support if you were charged."
        case .unknownResult:
            return "Something went wrong with the purchase. Please try again."
        }
    }
}

enum PurchaseOutcome: Equatable {
    case success
    case cancelled
    case failed(String)
}

/// StoreKit 2 purchase layer.
///
/// TODO(production): Add App Store Server Notifications webhook on Supabase to validate
/// renewals/cancellations independently of the client.
@MainActor
final class PurchaseService {
    private(set) var monthlyProduct: Product?
    private var updatesTask: Task<Void, Never>?
    var onVerifiedTransaction: ((Transaction) async -> Void)?
    
    init() {
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { continue }
                await self.handle(update: result)
            }
        }
    }
    
    deinit {
        updatesTask?.cancel()
    }
    
    func loadProducts() async {
        do {
            let products = try await Product.products(for: SubscriptionProductIDs.all)
            monthlyProduct = products.first { $0.id == SubscriptionProductIDs.proMonthly }
        } catch {
            print("PurchaseService: failed to load products — \(error)")
            monthlyProduct = nil
        }
    }
    
    func purchaseMonthly() async throws -> Transaction {
        if monthlyProduct == nil {
            await loadProducts()
        }
        guard let product = monthlyProduct else {
            throw PurchaseError.productUnavailable
        }
        
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return transaction
        case .userCancelled:
            throw CancellationError()
        case .pending:
            throw PurchaseError.unknownResult
        @unknown default:
            throw PurchaseError.unknownResult
        }
    }
    
    func restoreEntitlements() async throws -> Transaction? {
        try await AppStore.sync()
        
        for await result in Transaction.currentEntitlements {
            let transaction = try checkVerified(result)
            if SubscriptionProductIDs.all.contains(transaction.productID) {
                return transaction
            }
        }
        return nil
    }
    
    private func handle(update: VerificationResult<Transaction>) async {
        do {
            let transaction = try checkVerified(update)
            guard SubscriptionProductIDs.all.contains(transaction.productID) else { return }
            await onVerifiedTransaction?(transaction)
            await transaction.finish()
        } catch {
            print("PurchaseService: unverified transaction update — \(error)")
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw PurchaseError.unverifiedTransaction
        }
    }
}

import Foundation
import Combine
import StoreKit
import Supabase

extension Notification.Name {
    static let subscriptionEntitlementsDidChange = Notification.Name("subscriptionEntitlementsDidChange")
}

/// Orchestrates StoreKit purchases and server entitlement sync.
@MainActor
final class SubscriptionManager: ObservableObject {
    @Published private(set) var monthlyProduct: Product?
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    
    private let purchaseService = PurchaseService()
    
    init() {
        purchaseService.onVerifiedTransaction = { [weak self] transaction in
            guard let self else { return }
            do {
                try await self.syncTransactionToServer(transaction)
                NotificationCenter.default.post(name: .subscriptionEntitlementsDidChange, object: nil)
            } catch {
                print("SubscriptionManager: background transaction sync failed — \(error)")
            }
        }
    }
    
    var priceSubtitle: String {
        if let product = monthlyProduct {
            return "then \(product.displayPrice)/month"
        }
        return "then $9.99/month"
    }
    
    var trialCTA: String {
        if let product = monthlyProduct,
           let offer = product.subscription?.introductoryOffer,
           offer.paymentMode == .freeTrial {
            let period = offer.period
            return "Start \(period.value)-\(period.unit.localizedDescription) free trial"
        }
        return "Start 7-day free trial"
    }
    
    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        await purchaseService.loadProducts()
        monthlyProduct = purchaseService.monthlyProduct
    }
    
    func purchasePro(refreshEntitlements: @escaping () async -> Void) async -> PurchaseOutcome {
        guard !isPurchasing else { return .cancelled }
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            let transaction = try await purchaseService.purchaseMonthly()
            try await syncTransactionToServer(transaction)
            await refreshEntitlements()
            NotificationCenter.default.post(name: .subscriptionEntitlementsDidChange, object: nil)
            return .success
        } catch is CancellationError {
            return .cancelled
        } catch let error as PurchaseError {
            return .failed(error.localizedDescription)
        } catch {
            return .failed(error.localizedDescription)
        }
    }
    
    func restorePurchases(refreshEntitlements: @escaping () async -> Void) async -> PurchaseOutcome {
        guard !isPurchasing else { return .cancelled }
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            if let transaction = try await purchaseService.restoreEntitlements() {
                try await syncTransactionToServer(transaction)
                await refreshEntitlements()
                NotificationCenter.default.post(name: .subscriptionEntitlementsDidChange, object: nil)
                return .success
            }
            return .failed("No active subscription found for this Apple ID.")
        } catch let error as PurchaseError {
            return .failed(error.localizedDescription)
        } catch {
            return .failed(error.localizedDescription)
        }
    }
    
    // MARK: - Server sync
    
    private struct VerifyPremiumRequest: Encodable {
        let signed_transaction: String
    }
    
    private func syncTransactionToServer(_ transaction: Transaction) async throws {
        guard let session = try? await SupabaseManager.shared.client.auth.session else {
            throw PurchaseError.unverifiedTransaction
        }
        
        guard let signedTransaction = String(data: transaction.jsonRepresentation, encoding: .utf8),
              !signedTransaction.isEmpty else {
            throw PurchaseError.unverifiedTransaction
        }
        
        let verifyURL = URL(string: "\(Secrets.supabaseURL)/functions/v1/verify-premium")!
        var request = URLRequest(url: verifyURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(
            VerifyPremiumRequest(signed_transaction: signedTransaction)
        )
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PurchaseError.unverifiedTransaction
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorObj = json["error"] as? [String: Any],
               let message = errorObj["message"] as? String {
                throw NSError(
                    domain: "VerifyPremium",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: message]
                )
            }
            throw PurchaseError.unverifiedTransaction
        }
    }
}

private extension Product.SubscriptionPeriod.Unit {
    var localizedDescription: String {
        switch self {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        @unknown default: return "day"
        }
    }
}

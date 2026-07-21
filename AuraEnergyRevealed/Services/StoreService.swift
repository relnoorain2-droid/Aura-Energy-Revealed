//
//  StoreService.swift
//  Aura Energy Revealed
//
//  StoreKit 2 subscription service for Aura+.
//  Yearly $39.99 (anchor, 3-day free trial) · Monthly $19.99 · Weekly $15.99.
//

import Foundation
import StoreKit
import Observation

enum AuraPlusPlan: String, CaseIterable, Identifiable {
    case yearly = "com.auravision.auraplus.yearly"
    case monthly = "com.auravision.auraplus.monthly"
    case weekly = "com.auravision.auraplus.weekly"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yearly: "Yearly"
        case .monthly: "Monthly"
        case .weekly: "Weekly"
        }
    }

    var subtitle: String {
        switch self {
        case .yearly: "$39.99/yr · just $0.77/week"
        case .monthly: "Billed every month"
        case .weekly: "Flexible · cancel anytime"
        }
    }

    /// Fallback display price when products haven't loaded (offline preview).
    var fallbackPrice: String {
        switch self {
        case .yearly: "$39.99"
        case .monthly: "$19.99"
        case .weekly: "$15.99"
        }
    }

    var badge: String? {
        self == .yearly ? "BEST VALUE · SAVE 83%" : nil
    }
}

@Observable
final class StoreService {

    private(set) var products: [Product] = []
    private(set) var isSubscribed = false
    private(set) var purchaseInFlight = false
    var lastErrorMessage: String?

    private var updatesTask: Task<Void, Never>?

    func start() async {
        listenForTransactions()
        await loadProducts()
        await refreshEntitlements()
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: Products

    @MainActor
    func loadProducts() async {
        do {
            let ids = AuraPlusPlan.allCases.map(\.rawValue)
            products = try await Product.products(for: ids)
                .sorted { lhs, rhs in
                    let order = AuraPlusPlan.allCases.map(\.rawValue)
                    return (order.firstIndex(of: lhs.id) ?? 0) < (order.firstIndex(of: rhs.id) ?? 0)
                }
        } catch {
            lastErrorMessage = "The store is resting — try again in a moment."
        }
    }

    func product(for plan: AuraPlusPlan) -> Product? {
        products.first { $0.id == plan.rawValue }
    }

    func displayPrice(for plan: AuraPlusPlan) -> String {
        product(for: plan)?.displayPrice ?? plan.fallbackPrice
    }

    // MARK: Purchase

    @MainActor
    func purchase(_ plan: AuraPlusPlan) async {
        guard let product = product(for: plan) else {
            lastErrorMessage = "That plan isn't available right now."
            return
        }
        purchaseInFlight = true
        defer { purchaseInFlight = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            lastErrorMessage = "The purchase couldn't complete — nothing was charged."
        }
    }

    @MainActor
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            lastErrorMessage = "Restore didn't complete — try again in a moment."
        }
    }

    // MARK: Entitlements

    @MainActor
    func refreshEntitlements() async {
        var active = false
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               AuraPlusPlan(rawValue: transaction.productID) != nil,
               transaction.revocationDate == nil {
                active = true
            }
        }
        isSubscribed = active
    }

    private func listenForTransactions() {
        updatesTask = Task(priority: .background) { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
    }
}

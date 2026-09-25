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

/// Consumable top-up for extra Aura Coach conversations.
///
/// Sold exclusively through StoreKit. The app must never send someone to an
/// external payment page for digital content — App Store Review Guideline 3.1.1.
enum CoachTopUp {
    static let productID = "com.auravision.auracoach.topup"
    static let fallbackPrice = "$19.99"

    static var title: String { "Extra conversations" }
    static var blurb: String { "\(CoachQuota.messagesPerTopUp) more Aura Coach conversations. They never expire." }
}

@Observable
final class StoreService {

    private(set) var products: [Product] = []
    private(set) var topUpProduct: Product?
    private(set) var isSubscribed = false
    private(set) var purchaseInFlight = false
    var lastErrorMessage: String?

    /// Invoked whenever a coach top-up is verified, from a purchase here or
    /// from a transaction delivered later. Wired to `CoachQuota` at launch.
    var onCoachTopUpPurchased: (@MainActor () -> Void)?

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
            let planIDs = AuraPlusPlan.allCases.map(\.rawValue)
            let fetched = try await Product.products(for: planIDs + [CoachTopUp.productID])

            products = fetched
                .filter { AuraPlusPlan(rawValue: $0.id) != nil }
                .sorted { lhs, rhs in
                    let order = AuraPlusPlan.allCases.map(\.rawValue)
                    return (order.firstIndex(of: lhs.id) ?? 0) < (order.firstIndex(of: rhs.id) ?? 0)
                }

            topUpProduct = fetched.first { $0.id == CoachTopUp.productID }
        } catch {
            lastErrorMessage = "The store is resting — try again in a moment."
        }
    }

    var topUpDisplayPrice: String {
        topUpProduct?.displayPrice ?? CoachTopUp.fallbackPrice
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

    /// Buy one pack of extra Aura Coach conversations (consumable, Apple-billed).
    @MainActor
    func purchaseCoachTopUp() async {
        guard let product = topUpProduct else {
            lastErrorMessage = "That isn't available right now."
            return
        }
        purchaseInFlight = true
        defer { purchaseInFlight = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    // Grant before finishing so the credit is never lost.
                    onCoachTopUpPurchased?()
                    await transaction.finish()
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
                    if transaction.productID == CoachTopUp.productID {
                        await MainActor.run { self?.onCoachTopUpPurchased?() }
                    }
                    await transaction.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
    }
}

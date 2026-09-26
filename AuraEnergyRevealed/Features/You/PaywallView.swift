//
//  PaywallView.swift
//  Aura Energy Revealed
//
//  Screen 19 — soft, aspirational, honest. Gold aura hero → benefits →
//  three plans (yearly featured & pre-selected) → free-trial CTA → legal.
//  Yearly $39.99 · Monthly $19.99 · Weekly $15.99 · 3-day free trial.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreService.self) private var store

    @State private var selectedPlan: AuraPlusPlan = .yearly

    private let benefits = [
        "Unlimited readings & full history",
        "All 7 scan modes & body map",
        "AI Wellness Coach & full meditations",
        "Trends, share styles & wallpapers",
    ]

    var body: some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()
            RadialBloom(color: AuraPalette.gold, center: .init(x: 0.5, y: 0.1), opacity: 0.28)
            RadialBloom(color: AuraPalette.rose, center: .init(x: 0.5, y: 0.95), opacity: 0.2)

            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13))
                                .foregroundStyle(AuraPalette.ink.opacity(0.5))
                        }
                    }
                    .padding(.top, 16)

                    AuraOrbView(style: AuraHue.gold.orbStyle, size: 96)
                        .padding(.top, 4)

                    (Text("Aura").foregroundColor(AuraPalette.ink)
                     + Text("+").foregroundColor(AuraPalette.gold))
                        .font(AuraFont.display(32, relativeTo: .largeTitle))
                        .padding(.top, 10)

                    Text("Unlock your full journey")
                        .font(AuraFont.text(12, weight: .light))
                        .foregroundStyle(AuraPalette.inkDim)
                        .padding(.top, 2)

                    // Benefits
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(benefits.enumerated()), id: \.offset) { i, benefit in
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(AuraPalette.gold)
                                Text(benefit)
                                    .font(AuraFont.text(12.5))
                                    .foregroundStyle(AuraPalette.ink.opacity(0.9))
                            }
                            .riseFadeIn(index: i)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 18)

                    // Plans
                    VStack(spacing: 9) {
                        planCard(.yearly)
                        planCard(.monthly)
                        planCard(.weekly)
                    }

                    PrimaryButton(
                        title: selectedPlan == .yearly ? "Start 3-day free trial" : "Continue",
                        gradient: AuraPalette.goldGradient,
                        textColor: Color(hex: 0x2A1A1A)
                    ) {
                        Task {
                            await store.purchase(selectedPlan)
                            if store.isSubscribed { dismiss() }
                        }
                    }
                    .padding(.top, 14)
                    .disabled(store.purchaseInFlight)
                    .opacity(store.purchaseInFlight ? 0.6 : 1)

                    Group {
                        if selectedPlan == .yearly {
                            MonoLabel(text: "Then \(store.displayPrice(for: .yearly))/yr · cancel anytime", size: 9)
                        } else {
                            MonoLabel(text: "\(store.displayPrice(for: selectedPlan)) · cancel anytime", size: 9)
                        }
                    }
                    .padding(.top, 10)

                    Button("Restore purchase") {
                        Task { await store.restorePurchases() }
                    }
                    .font(AuraFont.text(12))
                    .foregroundStyle(AuraPalette.inkGhost)
                    .padding(.top, 12)

                    // Legal — required in-app for auto-renewable subscriptions (Guideline 3.1.2)
                    VStack(spacing: 8) {
                        Text("Payment is charged to your Apple Account at confirmation of purchase. Your subscription renews automatically unless it is cancelled at least 24 hours before the end of the current period. Manage or cancel anytime in your Apple Account settings.")
                            .font(AuraFont.text(9.5, weight: .light))
                            .foregroundStyle(AuraPalette.inkGhost)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 8) {
                            Link("Terms of Use (EULA)",
                                 destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            Text("·").foregroundStyle(AuraPalette.inkGhost)
                            Link("Privacy Policy",
                                 destination: URL(string: "https://sites.google.com/view/auraenergyrevealed")!)
                        }
                        .font(AuraFont.text(11, weight: .medium))
                        .foregroundStyle(AuraPalette.electricBlue)
                    }
                    .padding(.top, 14)
                    .padding(.horizontal, 6)
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, AuraSpacing.gutter)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: Plan card

    @ViewBuilder
    private func planCard(_ plan: AuraPlusPlan) -> some View {
        let isSelected = selectedPlan == plan
        Button {
            Haptics.selection()
            withAnimation(AuraMotion.micro) { selectedPlan = plan }
        } label: {
            HStack(spacing: 11) {
                // Radio
                Circle()
                    .strokeBorder(isSelected ? AuraPalette.gold : AuraPalette.hairline, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay {
                        if isSelected {
                            Circle().fill(AuraPalette.gold).frame(width: 10, height: 10)
                        }
                    }

                VStack(alignment: .leading, spacing: 1) {
                    Text(plan.title)
                        .font(AuraFont.text(14, weight: isSelected ? .bold : .semibold))
                        .foregroundStyle(AuraPalette.ink)
                    Text(plan.subtitle)
                        .font(AuraFont.text(10, weight: .light))
                        .foregroundStyle(AuraPalette.inkDim)
                }

                Spacer()

                Text(store.displayPrice(for: plan))
                    .font(AuraFont.text(14, weight: .bold))
                    .foregroundStyle(isSelected && plan == .yearly ? AuraPalette.gold : AuraPalette.ink)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 13)
            .background {
                let shape = RoundedRectangle(cornerRadius: AuraRadius.button, style: .continuous)
                if plan == .yearly {
                    shape.fill(
                        LinearGradient(
                            colors: [AuraPalette.gold.opacity(0.14), AuraPalette.rose.opacity(0.08)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                } else {
                    shape.fill(AuraPalette.fill)
                }
                shape.strokeBorder(
                    plan == .yearly ? AuraPalette.gold.opacity(0.65) : AuraPalette.hairline,
                    lineWidth: 1
                )
            }
            .overlay(alignment: .topTrailing) {
                if let badge = plan.badge {
                    Text(badge)
                        .font(AuraFont.text(8.5, weight: .heavy))
                        .tracking(0.5)
                        .foregroundStyle(Color(hex: 0x2A1A1A))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AuraPalette.goldGradient, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .offset(x: -14, y: -9)
                }
            }
            .scaleEffect(isSelected ? 1.0 : 0.99)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(plan.title), \(store.displayPrice(for: plan)). \(plan.subtitle)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

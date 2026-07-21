//
//  ResultView.swift
//  Aura Energy Revealed
//
//  Screen 08 — the payoff. Hero aura with the user's real photo,
//  colour name in serif, essence, energy balance, detail chips,
//  Save & Share. Cards rise in sequence.
//

import SwiftUI

struct ResultView: View {
    let reading: AuraReading
    let isNewReading: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(StoreService.self) private var store

    @State private var showDetails = false
    @State private var showBodyMap = false
    @State private var showChakras = false

    var body: some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()
            RadialBloom(
                color: reading.dominant.orbStyle.colors.first ?? AuraPalette.lavender,
                center: .init(x: 0.5, y: 0.22),
                opacity: 0.4
            )

            ScrollView {
                VStack(spacing: 0) {
                    MonoLabel(text: "Your Aura · \(reading.date.formatted(.dateTime.weekday(.wide).hour().minute()))")
                        .padding(.top, 14)

                    AuraPhotoHero(reading: reading)
                        .padding(.vertical, 6)

                    Text(reading.dominant.displayName)
                        .font(AuraFont.display(40, relativeTo: .largeTitle))
                        .foregroundStyle(reading.dominant.titleColor)
                        .riseFadeIn(index: 0)

                    Text(reading.essence)
                        .font(AuraFont.text(13, weight: .light))
                        .foregroundStyle(AuraPalette.inkDim)
                        .padding(.top, 6)
                        .riseFadeIn(index: 1)

                    GlassCard(padding: 18) {
                        Text(reading.interpretation)
                            .font(AuraFont.text(14, weight: .light))
                            .foregroundStyle(AuraPalette.ink.opacity(0.85))
                            .lineSpacing(5)
                    }
                    .padding(.top, 18)
                    .riseFadeIn(index: 2)

                    energyBalance
                        .padding(.top, 12)
                        .riseFadeIn(index: 3)

                    detailChips
                        .padding(.top, 14)
                        .riseFadeIn(index: 4)

                    PrimaryButton(title: "Explore your reading") {
                        showDetails = true
                    }
                    .padding(.top, 14)
                    .riseFadeIn(index: 5)

                    if isNewReading {
                        Button {
                            dismiss()
                            appState.isScanFlowPresented = false
                        } label: {
                            Text("Done")
                                .font(AuraFont.text(14, weight: .medium))
                                .foregroundStyle(AuraPalette.inkGhost)
                                .padding(.top, 18)
                        }
                    }
                }
                .padding(.horizontal, AuraSpacing.gutter)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)

            // Close affordance
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                        if isNewReading { appState.isScanFlowPresented = false }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AuraPalette.ink.opacity(0.6))
                            .frame(width: 34, height: 34)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .padding(.trailing, 18)
                    .padding(.top, 8)
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showDetails) { AuraDetailView(reading: reading) }
        .sheet(isPresented: $showBodyMap) { BodyMapView() }
        .sheet(isPresented: $showChakras) { ChakrasView(reading: reading) }
    }

    // MARK: Energy balance

    private var energyBalance: some View {
        GlassCard(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                MonoLabel(text: "Energy Balance")
                EnergyMeter(
                    label: "Intuition",
                    qualitative: qualitative(reading.intuition, high: "High", mid: "Rising", low: "Quiet"),
                    value: reading.intuition,
                    color: AuraPalette.violetLight
                )
                EnergyMeter(
                    label: "Calm",
                    qualitative: qualitative(reading.calm, high: "Deep", mid: "Balanced", low: "Gathering"),
                    value: reading.calm,
                    color: AuraPalette.electricBlue
                )
                EnergyMeter(
                    label: "Vitality",
                    qualitative: qualitative(reading.vitality, high: "Bright", mid: "Grounded", low: "Resting"),
                    value: reading.vitality,
                    color: AuraPalette.emerald
                )
            }
        }
    }

    private func qualitative(_ v: Double, high: String, mid: String, low: String) -> String {
        v > 0.7 ? high : (v > 0.45 ? mid : low)
    }

    // MARK: Detail chips

    private var detailChips: some View {
        HStack(spacing: 8) {
            chipButton("Body map →") {
                if store.isSubscribed { showBodyMap = true } else { appState.isPaywallPresented = true }
            }
            chipButton("Chakras →") { showChakras = true }
            chipButton("Colours →") { showDetails = true }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chipButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            AuraChip(label: label)
        }
        .buttonStyle(.plain)
    }
}

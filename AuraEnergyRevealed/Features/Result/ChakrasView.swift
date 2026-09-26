//
//  ChakrasView.swift
//  Aura Energy Revealed
//
//  Screen 12 — the seven centres, crown → root, coloured node + name +
//  balance meter. Meters fill in sequence; balancing practices are Aura+.
//

import SwiftUI

struct ChakrasView: View {
    let reading: AuraReading?

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(StoreService.self) private var store
    @State private var selected: Chakra?

    private var chakras: [Chakra] {
        Chakra.sample(seed: reading?.date.hashValue ?? Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0)
    }

    var body: some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Chakras")
                        .font(AuraFont.display(26, relativeTo: .title))
                        .foregroundStyle(AuraPalette.ink)
                        .padding(.top, 22)
                        .padding(.bottom, 6)

                    ForEach(Array(chakras.enumerated()), id: \.element.id) { i, chakra in
                        Button {
                            Haptics.selection()
                            selected = chakra
                        } label: {
                            chakraRow(chakra)
                        }
                        .buttonStyle(.plain)
                        .riseFadeIn(index: i)
                    }
                }
                .padding(.horizontal, AuraSpacing.gutter)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
        }
        .sheet(item: $selected) { chakra in
            chakraDetail(chakra)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .presentationDragIndicator(.visible)
    }

    private func chakraRow(_ chakra: Chakra) -> some View {
        GlassCard(padding: 13) {
            HStack(spacing: 12) {
                Circle()
                    .fill(chakra.color)
                    .frame(width: 26, height: 26)
                    .shadow(color: chakra.color, radius: 7)

                VStack(alignment: .leading, spacing: 1) {
                    Text(chakra.name)
                        .font(AuraFont.text(13, weight: .semibold))
                        .foregroundStyle(AuraPalette.ink)
                    Text(chakra.theme)
                        .font(AuraFont.text(10, weight: .light))
                        .foregroundStyle(AuraPalette.inkDim)
                }

                Spacer()

                // Balance meter
                ZStack(alignment: .leading) {
                    Capsule().fill(AuraPalette.fillStrong)
                    Capsule().fill(chakra.color)
                        .frame(width: 50 * chakra.balance)
                }
                .frame(width: 50, height: 5)
                .accessibilityLabel("\(chakra.name): \(Int(chakra.balance * 100)) percent balanced")
            }
        }
    }

    @ViewBuilder
    private func chakraDetail(_ chakra: Chakra) -> some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()
            RadialBloom(color: chakra.color, center: .init(x: 0.5, y: 0.15), opacity: 0.3)

            VStack(spacing: 14) {
                AuraOrbView(
                    style: AuraOrbStyle(colors: [chakra.color], personality: .pulsing),
                    size: 110
                )
                .padding(.top, 24)

                Text(chakra.name)
                    .font(AuraFont.display(30, relativeTo: .title))
                    .foregroundStyle(chakra.color)

                Text("\(chakra.theme) · \(Int(chakra.balance * 100))% in balance")
                    .font(AuraFont.text(13, weight: .light))
                    .foregroundStyle(AuraPalette.inkDim)

                if store.isSubscribed {
                    GlassCard(padding: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "figure.mind.and.body")
                                .foregroundStyle(chakra.color)
                            Text(chakra.practice)
                                .font(AuraFont.text(13.5, weight: .medium))
                                .foregroundStyle(AuraPalette.ink)
                            Spacer()
                            Image(systemName: "play.circle.fill")
                                .foregroundStyle(chakra.color)
                        }
                    }
                    .padding(.horizontal, AuraSpacing.gutter)
                } else {
                    Button {
                        selected = nil
                        dismiss()
                        appState.isPaywallPresented = true
                    } label: {
                        AuraChip(label: "✦ Balancing practice · Aura+", dotColor: AuraPalette.gold)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
        }
    }
}

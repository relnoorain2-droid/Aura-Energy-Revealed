//
//  ExploreView.swift
//  Aura Energy Revealed
//
//  The Explore world: chakras, aura colour guide, body map, and the
//  seven "read the aura of anything" scan lenses.
//

import SwiftUI

struct ExploreView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreService.self) private var store

    @State private var showChakras = false
    @State private var showBodyMap = false
    @State private var showColorGuide = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Explore")
                    .font(AuraFont.display(28, relativeTo: .largeTitle))
                    .foregroundStyle(AuraPalette.ink)
                    .padding(.top, 10)

                // Core references
                HStack(spacing: 12) {
                    exploreTile(emoji: "🕉️", title: "Chakras", subtitle: "Seven centres") {
                        showChakras = true
                    }
                    exploreTile(emoji: "🎨", title: "Colours", subtitle: "The living guide") {
                        showColorGuide = true
                    }
                }
                .riseFadeIn(index: 0)

                exploreTileWide(emoji: "🧍", title: "Body Map", subtitle: "Where your energy lives · 14 regions") {
                    if store.isSubscribed { showBodyMap = true } else { appState.isPaywallPresented = true }
                }
                .riseFadeIn(index: 1)

                MonoLabel(text: "Read the aura of anything")
                    .padding(.top, 10)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                    ForEach(Array(ScanMode.allCases.filter { $0 != .selfAura }.enumerated()), id: \.element.id) { i, mode in
                        scanModeCard(mode)
                            .riseFadeIn(index: i + 2)
                    }
                }
            }
            .padding(.horizontal, AuraSpacing.gutter)
            .padding(.bottom, 130)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showChakras) { ChakrasView(reading: nil) }
        .sheet(isPresented: $showBodyMap) { BodyMapView() }
        .sheet(isPresented: $showColorGuide) { ColorGuideView() }
    }

    private func exploreTile(emoji: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            GlassCard(padding: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(emoji).font(.system(size: 24))
                    Text(title)
                        .font(AuraFont.text(15, weight: .semibold))
                        .foregroundStyle(AuraPalette.ink)
                    Text(subtitle)
                        .font(AuraFont.text(11.5, weight: .light))
                        .foregroundStyle(AuraPalette.inkDim)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func exploreTileWide(emoji: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            GlassCard(padding: 18) {
                HStack(spacing: 14) {
                    Text(emoji).font(.system(size: 26))
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(title)
                                .font(AuraFont.text(15, weight: .semibold))
                                .foregroundStyle(AuraPalette.ink)
                            if !store.isSubscribed {
                                Text("✦ Aura+")
                                    .font(AuraFont.text(10, weight: .bold))
                                    .foregroundStyle(AuraPalette.gold)
                            }
                        }
                        Text(subtitle)
                            .font(AuraFont.text(11.5, weight: .light))
                            .foregroundStyle(AuraPalette.inkDim)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundStyle(AuraPalette.inkGhost)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func scanModeCard(_ mode: ScanMode) -> some View {
        Button {
            if mode.isPremium && !store.isSubscribed {
                appState.isPaywallPresented = true
            } else {
                appState.isScanFlowPresented = true
            }
        } label: {
            GlassCard(padding: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: mode.symbol)
                            .font(.system(size: 20))
                            .foregroundStyle(AuraPalette.lavender)
                        Spacer()
                        if mode.isPremium && !store.isSubscribed {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(AuraPalette.gold)
                        }
                    }
                    Text(mode.title)
                        .font(AuraFont.text(14, weight: .semibold))
                        .foregroundStyle(AuraPalette.ink)
                    Text(mode.blurb)
                        .font(AuraFont.text(11, weight: .light))
                        .foregroundStyle(AuraPalette.inkDim)
                        .lineLimit(2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Aura colour guide (screen 13)

struct ColorGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selected: AuraHue?

    var body: some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Aura Colours")
                        .font(AuraFont.display(26, relativeTo: .title))
                        .foregroundStyle(AuraPalette.ink)
                        .padding(.top, 22)

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                        ForEach(Array(AuraHue.allCases.enumerated()), id: \.element.id) { i, hue in
                            Button { selected = hue } label: {
                                GlassCard(padding: 16) {
                                    VStack(spacing: 10) {
                                        AuraOrbView(style: hue.orbStyle, size: 84)
                                        Text(hue.displayName)
                                            .font(AuraFont.display(20, relativeTo: .title3))
                                            .foregroundStyle(AuraPalette.ink)
                                        Text(hue.essence)
                                            .font(AuraFont.text(10.5, weight: .light))
                                            .foregroundStyle(AuraPalette.inkDim)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(.plain)
                            .riseFadeIn(index: i)
                        }
                    }
                }
                .padding(.horizontal, AuraSpacing.gutter)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
        }
        .sheet(item: $selected) { hue in
            hueDetail(hue)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func hueDetail(_ hue: AuraHue) -> some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()
            RadialBloom(color: hue.orbStyle.colors.first ?? .white, center: .init(x: 0.5, y: 0.15), opacity: 0.3)

            ScrollView {
                VStack(spacing: 14) {
                    AuraOrbView(style: hue.orbStyle, size: 140)
                        .padding(.top, 26)
                    Text(hue.displayName)
                        .font(AuraFont.display(34, relativeTo: .largeTitle))
                        .foregroundStyle(hue.titleColor)
                    Text(hue.essence)
                        .font(AuraFont.text(13, weight: .light))
                        .foregroundStyle(AuraPalette.inkDim)
                    GlassCard(padding: 18) {
                        Text(hue.meaning)
                            .font(AuraFont.text(14, weight: .light))
                            .foregroundStyle(AuraPalette.ink.opacity(0.85))
                            .lineSpacing(5)
                    }
                    .padding(.horizontal, AuraSpacing.gutter)
                }
                .padding(.bottom, 30)
            }
        }
    }
}

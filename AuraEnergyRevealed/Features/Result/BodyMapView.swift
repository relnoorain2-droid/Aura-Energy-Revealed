//
//  BodyMapView.swift
//  Aura Energy Revealed
//
//  Screens 10 & 11 — aura silhouette with glowing meridian nodes;
//  tapping opens the part-detail template (one template, 14 parts).
//

import SwiftUI

struct BodyMapView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRegion: BodyRegion?
    @State private var nodesBreathing = false

    // Show the primary meridian nodes on the map; all 14 reachable via pager.
    private let mapRegions: [BodyRegion] = ["head", "neck", "heart", "solarPlexus", "lowerBody"]
        .compactMap { id in BodyRegion.all.first { $0.id == id } }

    var body: some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()
            RadialBloom(color: AuraPalette.electricBlue, center: .init(x: 0.5, y: 0.4), opacity: 0.18)

            VStack(spacing: 4) {
                Text("Your Body Map")
                    .font(AuraFont.display(24, relativeTo: .title2))
                    .foregroundStyle(AuraPalette.ink)
                    .padding(.top, 22)
                Text("Tap a region to explore")
                    .font(AuraFont.text(11.5, weight: .light))
                    .foregroundStyle(AuraPalette.inkDim)

                GeometryReader { geo in
                    ZStack {
                        // Silhouette bloom
                        Ellipse()
                            .fill(
                                RadialGradient(
                                    colors: [AuraPalette.lavender.opacity(0.35), AuraPalette.electricBlue.opacity(0.18), .clear],
                                    center: .init(x: 0.5, y: 0.3),
                                    startRadius: 10,
                                    endRadius: geo.size.height * 0.5
                                )
                            )
                            .frame(width: 130, height: geo.size.height * 0.92)
                            .blur(radius: 14)

                        // Central meridian
                        LinearGradient(
                            colors: [AuraPalette.lavender, AuraPalette.electricBlue, AuraPalette.emerald, AuraPalette.gold],
                            startPoint: .top, endPoint: .bottom
                        )
                        .frame(width: 2, height: geo.size.height * 0.9)
                        .opacity(0.4)

                        // Nodes
                        ForEach(mapRegions) { region in
                            Button {
                                Haptics.selection()
                                selectedRegion = region
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(region.color)
                                        .frame(width: 16, height: 16)
                                        .shadow(color: region.color, radius: nodesBreathing ? 14 : 8)
                                        .scaleEffect(nodesBreathing ? 1.12 : 1)
                                }
                                .frame(width: 48, height: 48)
                                .contentShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .position(
                                x: geo.size.width / 2,
                                y: geo.size.height * (0.06 + region.meridianPosition * 0.85)
                            )
                            .accessibilityLabel("\(region.name), \(region.theme)")

                            Text(region.name.uppercased())
                                .font(AuraFont.mono(9.5))
                                .foregroundStyle(AuraPalette.ink.opacity(0.6))
                                .position(
                                    x: geo.size.width / 2 + 62,
                                    y: geo.size.height * (0.06 + region.meridianPosition * 0.85)
                                )
                                .accessibilityHidden(true)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .animation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true), value: nodesBreathing)

                // Selected-region summary bar
                if let heart = BodyRegion.all.first(where: { $0.id == "heart" }) {
                    Button { selectedRegion = heart } label: {
                        GlassCard(padding: 14) {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(heart.color)
                                    .frame(width: 10, height: 10)
                                    .shadow(color: heart.color, radius: 6)
                                (Text("Heart · ").foregroundColor(AuraPalette.ink)
                                 + Text("open & warm").foregroundColor(AuraPalette.emerald))
                                    .font(AuraFont.text(12, weight: .medium))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AuraPalette.inkGhost)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, AuraSpacing.gutter)
                    .padding(.bottom, 16)
                }
            }
        }
        .onAppear { nodesBreathing = true }
        .sheet(item: $selectedRegion) { region in
            BodyPartDetailView(initialRegion: region)
        }
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Body-part detail · one premium template drives all 14 parts

struct BodyPartDetailView: View {
    let initialRegion: BodyRegion
    @Environment(\.dismiss) private var dismiss
    @State private var index: Int = 0

    var body: some View {
        TabView(selection: $index) {
            ForEach(Array(BodyRegion.all.enumerated()), id: \.element.id) { i, region in
                partPage(region, position: i)
                    .tag(i)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(AuraPalette.deepSpace.ignoresSafeArea())
        .onAppear {
            index = BodyRegion.all.firstIndex { $0.id == initialRegion.id } ?? 0
        }
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func partPage(_ region: BodyRegion, position: Int) -> some View {
        ZStack {
            RadialBloom(color: region.color, center: .init(x: 0.5, y: 0.2), opacity: 0.32)

            ScrollView {
                VStack(spacing: 14) {
                    HStack {
                        Button { dismiss() } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Body")
                            }
                            .font(AuraFont.text(13))
                            .foregroundStyle(AuraPalette.ink.opacity(0.55))
                        }
                        Spacer()
                        MonoLabel(text: String(format: "%02d / 14", position + 1))
                    }
                    .padding(.top, 20)

                    AuraOrbView(
                        style: AuraOrbStyle(colors: [region.color.opacity(0.9), region.color], personality: .pulsing),
                        size: 150
                    )
                    .padding(.top, 6)

                    VStack(spacing: 4) {
                        Text(region.name)
                            .font(AuraFont.display(36, relativeTo: .largeTitle))
                            .foregroundStyle(region.color)
                        Text(region.theme)
                            .font(AuraFont.text(12, weight: .light))
                            .foregroundStyle(AuraPalette.inkDim)
                    }

                    GlassCard(padding: 18) {
                        Text(region.reading)
                            .font(AuraFont.text(13.5, weight: .light))
                            .foregroundStyle(AuraPalette.ink.opacity(0.85))
                            .lineSpacing(5)
                    }

                    HStack(spacing: 8) {
                        AuraChip(label: "\(region.auraName) aura", dotColor: region.color)
                        AuraChip(label: "\(region.chakraName) chakra", dotColor: region.color)
                        Spacer()
                    }

                    GlassCard(padding: 14) {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [region.color, AuraPalette.electricBlue],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Image(systemName: "figure.mind.and.body")
                                        .font(.system(size: 15))
                                        .foregroundStyle(.white)
                                }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(region.practice)
                                    .font(AuraFont.text(13.5, weight: .semibold))
                                    .foregroundStyle(AuraPalette.ink)
                                Text(region.practiceDuration)
                                    .font(AuraFont.text(11, weight: .light))
                                    .foregroundStyle(AuraPalette.inkDim)
                            }
                            Spacer()
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(region.color)
                        }
                    }
                }
                .padding(.horizontal, AuraSpacing.gutter)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
        }
    }
}

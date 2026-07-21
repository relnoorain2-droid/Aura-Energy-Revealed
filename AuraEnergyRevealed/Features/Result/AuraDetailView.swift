//
//  AuraDetailView.swift
//  Aura Energy Revealed
//
//  Screen 09 — colour composition, meaning, one actionable practice.
//  Free tier sees the dominant colour + a teaser; Aura+ gets everything.
//

import SwiftUI

struct AuraDetailView: View {
    let reading: AuraReading

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(StoreService.self) private var store

    private var practice: Meditation? {
        Meditation.library.first { $0.id == reading.suggestedPractice }
    }

    var body: some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(AuraPalette.ink.opacity(0.7))
                        }
                        Text("Aura Details")
                            .font(AuraFont.display(24, relativeTo: .title2))
                            .foregroundStyle(AuraPalette.ink)
                    }
                    .padding(.top, 18)

                    // Dominant summary
                    GlassCard(padding: 18) {
                        HStack(spacing: 16) {
                            AuraOrbView(style: reading.dominant.orbStyle, size: 64)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Dominant · \(reading.dominant.displayName)")
                                    .font(AuraFont.text(16, weight: .semibold))
                                    .foregroundStyle(AuraPalette.ink)
                                Text("\(Int(reading.dominantFraction * 100))% of your field")
                                    .font(AuraFont.text(12, weight: .light))
                                    .foregroundStyle(AuraPalette.inkDim)
                            }
                        }
                    }
                    .riseFadeIn(index: 0)

                    MonoLabel(text: "Colour Composition")
                        .padding(.top, 8)

                    CompositionBar(segments: [
                        (reading.dominant.orbStyle.colors.first ?? AuraPalette.lavender, reading.dominantFraction),
                        (reading.secondary.orbStyle.colors.first ?? AuraPalette.electricBlue, reading.secondaryFraction),
                        (reading.tertiary.orbStyle.colors.first ?? AuraPalette.emerald, reading.tertiaryFraction),
                    ])
                    .riseFadeIn(index: 1)

                    HStack(spacing: 8) {
                        AuraChip(label: "\(reading.dominant.displayName) \(Int(reading.dominantFraction * 100))%", dotColor: reading.dominant.orbStyle.colors.first)
                        AuraChip(label: "\(reading.secondary.displayName) \(Int(reading.secondaryFraction * 100))%", dotColor: reading.secondary.orbStyle.colors.first)
                        AuraChip(label: "\(reading.tertiary.displayName) \(Int(reading.tertiaryFraction * 100))%", dotColor: reading.tertiary.orbStyle.colors.first)
                    }

                    MonoLabel(text: "What It Means")
                        .padding(.top, 8)

                    if store.isSubscribed {
                        GlassCard(padding: 18) {
                            Text(fullMeaning)
                                .font(AuraFont.text(13.5, weight: .light))
                                .foregroundStyle(AuraPalette.ink.opacity(0.82))
                                .lineSpacing(5)
                        }
                        .riseFadeIn(index: 2)
                    } else {
                        teaserCard
                            .riseFadeIn(index: 2)
                    }

                    if let practice {
                        MonoLabel(text: "Suggested Practice")
                            .padding(.top, 8)
                        NavigationLinkCard(meditation: practice)
                            .riseFadeIn(index: 3)
                    }
                }
                .padding(.horizontal, AuraSpacing.gutter)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var fullMeaning: String {
        "\(reading.dominant.meaning) Paired with \(reading.secondary.displayName.lowercased())'s \(reading.secondary.essence.lowercased()) and a grounding thread of \(reading.tertiary.displayName.lowercased()), today favours reflection over big decisions."
    }

    private var teaserCard: some View {
        Button {
            dismiss()
            appState.isPaywallPresented = true
        } label: {
            GlassCard(padding: 18, tint: AuraPalette.gold) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(reading.dominant.meaning.prefix(80)) + "…")
                        .font(AuraFont.text(13.5, weight: .light))
                        .foregroundStyle(AuraPalette.ink.opacity(0.82))
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Unlock the full reading with Aura+")
                    }
                    .font(AuraFont.text(12.5, weight: .semibold))
                    .foregroundStyle(AuraPalette.gold)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Practice row that opens the player

struct NavigationLinkCard: View {
    let meditation: Meditation
    @State private var showPlayer = false

    var body: some View {
        Button { showPlayer = true } label: {
            GlassCard(padding: 16) {
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [meditation.hue.orbStyle.colors.first ?? AuraPalette.lavender,
                                         AuraPalette.electricBlue],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "figure.mind.and.body")
                                .foregroundStyle(.white)
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(meditation.title)
                            .font(AuraFont.text(14, weight: .semibold))
                            .foregroundStyle(AuraPalette.ink)
                        Text("\(meditation.minutes) min · \(meditation.subtitle.lowercased())")
                            .font(AuraFont.text(11.5, weight: .light))
                            .foregroundStyle(AuraPalette.inkDim)
                    }
                    Spacer()
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(meditation.hue.orbStyle.colors.first ?? AuraPalette.lavender)
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPlayer) {
            MeditationPlayerView(meditation: meditation)
        }
    }
}

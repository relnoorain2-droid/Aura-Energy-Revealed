//
//  OnboardingView.swift
//  Aura Energy Revealed
//
//  Screen 03 — three luminous slides:
//  1. What an aura is (reflective, not medical)
//  2. Set your intention (multi-select chips, feeds personalization)
//  3. How the scan works (preview of the magic)
//  Orb re-tints per slide; headlines stagger-fade.
//

import SwiftUI

private struct OnboardingSlide {
    let orbColors: [Color]
    let bloom: Color
    let headline: String
    let body: String
}

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var page = 0
    @State private var selectedIntentions: Set<String> = []

    private let intentionOptions = ["Calm", "Clarity", "Growth", "Balance", "Energy", "Love"]

    private let slides: [OnboardingSlide] = [
        OnboardingSlide(
            orbColors: [AuraPalette.emerald, AuraPalette.electricBlue, AuraPalette.lavender],
            bloom: AuraPalette.emerald,
            headline: "A mirror,\nnot a diagnosis",
            body: "Aura Energy Revealed reads the colours of your energy as a reflective wellness practice — inspired by spiritual traditions, interpreted gently by AI."
        ),
        OnboardingSlide(
            orbColors: [AuraPalette.lavender, AuraPalette.rose, AuraPalette.gold],
            bloom: AuraPalette.auroraPurpleDeep,
            headline: "Set your\nintention",
            body: "What are you hoping to nurture? Your choices quietly shape your readings and the practices we suggest."
        ),
        OnboardingSlide(
            orbColors: [AuraPalette.electricBlue, AuraPalette.auroraPurple, AuraPalette.emerald],
            bloom: AuraPalette.electricBlueDeep,
            headline: "A photo becomes\nlight",
            body: "Take or choose a photo. In a slow, cinematic breath, your aura blooms around you — read privately, on your device."
        ),
    ]

    var body: some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()
            RadialBloom(color: slides[page].bloom, center: .init(x: 0.5, y: 0.28), opacity: 0.28)
                .animation(.easeInOut(duration: 0.4), value: page)

            VStack(spacing: 0) {
                // Progress + skip
                HStack {
                    HStack(spacing: 6) {
                        ForEach(0..<slides.count, id: \.self) { i in
                            Capsule()
                                .fill(i == page ? AuraPalette.ink : AuraPalette.inkFaint)
                                .frame(width: i == page ? 22 : 8, height: 5)
                                .animation(AuraMotion.standard, value: page)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Page \(page + 1) of \(slides.count)")

                    Spacer()

                    Button("Skip") {
                        finish()
                    }
                    .font(AuraFont.text(12))
                    .foregroundStyle(AuraPalette.inkGhost)
                }
                .padding(.horizontal, 26)
                .padding(.top, 18)

                TabView(selection: $page) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        slideView(slides[index], index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(AuraMotion.expressive, value: page)

                PrimaryButton(title: page == slides.count - 1 ? "Begin" : "Continue") {
                    if page < slides.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        finish()
                    }
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 40)
            }
        }
    }

    private func finish() {
        appState.intentions = Array(selectedIntentions)
        appState.phase = .permissions
    }

    @ViewBuilder
    private func slideView(_ slide: OnboardingSlide, index: Int) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)

            AuraOrbView(style: AuraOrbStyle(colors: slide.orbColors), size: 170)
                .padding(.vertical, 20)

            Text(slide.headline)
                .font(AuraFont.display(32, relativeTo: .largeTitle))
                .foregroundStyle(AuraPalette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)

            Text(slide.body)
                .font(AuraFont.text(14, weight: .light))
                .foregroundStyle(AuraPalette.inkDim)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Slide 2: intention chips (multi-select)
            if index == 1 {
                FlowChips(
                    options: intentionOptions,
                    selection: $selectedIntentions
                )
                .padding(.top, 20)
            }

            Spacer()
        }
        .padding(.horizontal, 26)
    }
}

// MARK: - Selectable chip row

private struct FlowChips: View {
    let options: [String]
    @Binding var selection: Set<String>

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
            ForEach(options, id: \.self) { option in
                let isOn = selection.contains(option)
                Button {
                    Haptics.selection()
                    if isOn { selection.remove(option) } else { selection.insert(option) }
                } label: {
                    Text(option)
                        .font(AuraFont.text(13, weight: .medium))
                        .foregroundStyle(isOn ? AuraPalette.deepSpace : AuraPalette.ink.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if isOn {
                                Capsule().fill(AuraPalette.lavender)
                            } else {
                                Capsule().fill(AuraPalette.fill)
                                Capsule().strokeBorder(AuraPalette.hairline, lineWidth: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? [.isSelected] : [])
            }
        }
    }
}

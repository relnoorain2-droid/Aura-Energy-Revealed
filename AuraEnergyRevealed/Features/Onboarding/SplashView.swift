//
//  SplashView.swift
//  Aura Energy Revealed
//
//  Screen 01 — set the emotional tone in under 2 seconds.
//  Orb scales 0.6→1 with a spring, tagline fades up 300ms after.
//

import SwiftUI

struct SplashView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var orbShown = false
    @State private var textShown = false

    var body: some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()
            RadialBloom(color: AuraPalette.auroraPurpleDeep)

            VStack(spacing: 28) {
                AuraOrbView(style: .brand, size: 150)
                    .gentleFloat()
                    .scaleEffect(orbShown ? 1 : 0.6)
                    .opacity(orbShown ? 1 : 0)

                VStack(spacing: 8) {
                    (Text("Aura Energy ")
                        .foregroundColor(AuraPalette.ink)
                     + Text("Revealed")
                        .foregroundColor(AuraPalette.lavender))
                        .font(AuraFont.display(30, relativeTo: .largeTitle))

                    MonoLabel(text: "See the energy you carry", color: AuraPalette.inkFaint)
                }
                .opacity(textShown ? 1 : 0)
                .offset(y: textShown ? 0 : 10)
            }
        }
        .onAppear {
            Haptics.impactLight()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                orbShown = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                textShown = true
            }
            // Auto-advance on asset-ready (no blocking network).
            DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 1.0 : 1.8)) {
                appState.advanceFromSplash()
            }
        }
    }
}

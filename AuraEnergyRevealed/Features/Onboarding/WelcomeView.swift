//
//  WelcomeView.swift
//  Aura Energy Revealed
//
//  Screen 02 — invite, don't gate. Awe first; account optional and deferred.
//

import SwiftUI

struct WelcomeView: View {
    @Environment(AppState.self) private var appState
    @State private var headlineShown = false

    var body: some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()
            RadialBloom(color: AuraPalette.electricBlueDeep, center: .init(x: 0.7, y: 0.2), opacity: 0.4)
            RadialBloom(color: AuraPalette.auroraPurpleDeep, center: .init(x: 0.2, y: 0.4), opacity: 0.4)

            // Ambient orb, top-right per design
            VStack {
                HStack {
                    Spacer()
                    AuraOrbView(
                        style: AuraOrbStyle(colors: [AuraPalette.electricBlueDeep, AuraPalette.auroraPurpleDeep, AuraPalette.rose]),
                        size: 120
                    )
                    .opacity(0.9)
                    .padding(.trailing, 30)
                    .padding(.top, 70)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                Text("Your energy,\nmade visible.")
                    .font(AuraFont.display(40, relativeTo: .largeTitle))
                    .foregroundStyle(AuraPalette.ink)
                    .lineSpacing(2)
                    .opacity(headlineShown ? 1 : 0)
                    .offset(y: headlineShown ? 0 : 14)
                    .padding(.bottom, 14)

                Text("A calm, AI-guided practice for reflection, meditation, and self-awareness.")
                    .font(AuraFont.text(14, weight: .light))
                    .foregroundStyle(AuraPalette.inkDim)
                    .lineSpacing(4)
                    .padding(.bottom, 26)
                    .opacity(headlineShown ? 1 : 0)

                PrimaryButton(title: "Begin your first reading") {
                    appState.phase = .onboarding
                }

                Button {
                    // Auth is deferred by design; the same path continues onboarding.
                    appState.phase = .onboarding
                } label: {
                    Text("I already have an account")
                        .font(AuraFont.text(13))
                        .foregroundStyle(AuraPalette.ink.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                }
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7).delay(0.15)) {
                headlineShown = true
            }
        }
        .gesture(
            DragGesture(minimumDistance: 30).onEnded { value in
                if value.translation.height < -50 {
                    appState.phase = .onboarding
                }
            }
        )
    }
}

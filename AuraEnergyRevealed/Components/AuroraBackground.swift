//
//  AuroraBackground.swift
//  Aura Energy Revealed
//
//  The ambient aurora field — three drifting blurred blooms over space black.
//

import SwiftUI

struct AuroraBackground: View {
    var intensity: Double = 0.5
    @State private var drift = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    /// These washes were tuned against a near-black background. At full strength
    /// on paper they turn the page muddy, so light appearance gets a third of it.
    private var effective: Double {
        colorScheme == .dark ? intensity : intensity * 0.34
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                AuraPalette.deepSpace

                // A low, warm horizon — light settling at the bottom of the frame
                // rather than neon blobs floating in the middle of it.
                LinearGradient(
                    colors: [
                        .clear,
                        AuraPalette.roseDeep.opacity(effective * 0.16),
                        AuraPalette.amber.opacity(effective * 0.20)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: h * 0.55)
                .frame(maxHeight: .infinity, alignment: .bottom)

                // One slow, very soft wash high in the frame for depth.
                wash(color: AuraPalette.indigo, size: w * 1.25)
                    .offset(
                        x: drift ? -w * 0.18 : -w * 0.26,
                        y: drift ? -h * 0.30 : -h * 0.36
                    )

                // A whisper of colour opposite it, kept deliberately faint.
                wash(color: AuraPalette.auroraPurpleDeep, size: w * 0.95)
                    .opacity(0.7)
                    .offset(
                        x: drift ? w * 0.32 : w * 0.40,
                        y: drift ? h * 0.05 : h * 0.01
                    )
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 34).repeatForever(autoreverses: true)) {
                    drift = true
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    /// Soft, normal-blended colour. No `.screen` — that is what produces the
    /// glowing neon look this design is deliberately avoiding.
    private func wash(color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(effective * 0.42), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: size * 0.5
                )
            )
            .frame(width: size, height: size)
            .blur(radius: 70)
    }
}

/// A single radial glow bloom — used as screen-specific backdrops
/// (e.g. "radial purple bloom on space black" behind the splash orb).
struct RadialBloom: View {
    var color: Color
    var center: UnitPoint = .init(x: 0.5, y: 0.42)
    var opacity: Double = 0.35

    var body: some View {
        GeometryReader { geo in
            RadialGradient(
                colors: [color.opacity(opacity), .clear],
                center: center,
                startRadius: 0,
                endRadius: max(geo.size.width, geo.size.height) * 0.62
            )
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

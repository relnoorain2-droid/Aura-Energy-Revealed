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

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                AuraPalette.deepSpace

                bloom(color: AuraPalette.auroraPurpleDeep, size: w * 1.1)
                    .offset(x: drift ? -w * 0.15 : -w * 0.25, y: drift ? -w * 0.05 : -w * 0.15)

                bloom(color: AuraPalette.electricBlueDeep, size: w * 1.0)
                    .offset(x: drift ? w * 0.35 : w * 0.45, y: drift ? w * 0.25 : w * 0.15)

                bloom(color: AuraPalette.emerald, size: w * 0.9)
                    .opacity(intensity * 0.7)
                    .offset(x: drift ? w * 0.15 : w * 0.1, y: drift ? geo.size.height * 0.75 : geo.size.height * 0.85)
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 26).repeatForever(autoreverses: true)) {
                    drift = true
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func bloom(color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(intensity), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: size * 0.5
                )
            )
            .frame(width: size, height: size)
            .blur(radius: 60)
            .blendMode(.screen)
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

//
//  EnergyMeter.swift
//  Aura Energy Revealed
//
//  Energy balance bars — value · colour · left-to-right fill animation.
//  Never colour-only: label + qualitative word accompany every bar.
//

import SwiftUI

struct EnergyMeter: View {
    let label: String
    let qualitative: String
    let value: Double            // 0...1
    let color: Color

    @State private var filled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(AuraFont.text(11, weight: .medium))
                    .foregroundStyle(AuraPalette.ink.opacity(0.85))
                Spacer()
                Text(qualitative)
                    .font(AuraFont.text(11, weight: .semibold))
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AuraPalette.fillStrong)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.55)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: filled ? geo.size.width * value : 0)
                }
            }
            .frame(height: 6)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9).delay(0.15)) {
                filled = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(qualitative)")
    }
}

// MARK: - Colour composition bar (result details)

struct CompositionBar: View {
    let segments: [(color: Color, fraction: Double)]

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, seg in
                    Rectangle()
                        .fill(seg.color)
                        .frame(width: geo.size.width * seg.fraction)
                }
            }
        }
        .frame(height: 14)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

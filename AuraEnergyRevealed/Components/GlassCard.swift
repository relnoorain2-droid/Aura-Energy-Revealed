//
//  GlassCard.swift
//  Aura Energy Revealed
//
//  The default container: 6% white fill, 1px 9% stroke, real blur,
//  inset top highlight, 22pt corners. Honors Reduce Transparency.
//

import SwiftUI

struct GlassCard<Content: View>: View {
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = AuraRadius.card
    var tint: Color? = nil
    var strokeColor: Color = AuraPalette.ink.opacity(0.10)
    @ViewBuilder var content: Content

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    // A solid, warm card rather than frosted glass. Glassmorphism over a dark
    // gradient is the most recognisable trait of this app category, so the
    // surface here is opaque, the border is a warm hairline, and the shadow is
    // tight instead of a wide diffuse glow.
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                ZStack {
                    shape.fill(AuraPalette.surface.opacity(reduceTransparency ? 1.0 : 0.92))
                    if let tint {
                        shape.fill(tint.opacity(0.07))
                    }
                    shape.strokeBorder(strokeColor, lineWidth: 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.28), radius: 10, y: 5)
    }
}

// MARK: - Chip (label · dot · selectable)

struct AuraChip: View {
    let label: String
    var dotColor: Color? = nil
    var emphasized: Bool = false

    var body: some View {
        HStack(spacing: 7) {
            if let dotColor {
                Circle()
                    .fill(dotColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: dotColor, radius: 5)
            }
            Text(label)
                .font(AuraFont.text(12.5, weight: .medium))
                .foregroundStyle(emphasized ? AuraPalette.ink : AuraPalette.ink.opacity(0.8))
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 7)
        .background {
            Capsule().fill(.white.opacity(emphasized ? 0.10 : 0.05))
            Capsule().strokeBorder(.white.opacity(0.10), lineWidth: 1)
        }
    }
}

// MARK: - Primary gradient button

struct PrimaryButton: View {
    let title: String
    var gradient: LinearGradient = AuraPalette.primaryGradient
    var textColor: Color = .white
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.impactLight()
            action()
        } label: {
            Text(title)
                .font(AuraFont.text(15, weight: .semibold))
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: AuraRadius.cta, style: .continuous)
                        .fill(gradient)
                }
                // A grounded drop shadow, not a coloured neon halo.
                .shadow(color: .black.opacity(0.30), radius: 8, y: 4)
        }
        .pressScale()
    }
}

// MARK: - Ghost button

struct GhostButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AuraFont.text(15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: AuraRadius.cta, style: .continuous)
                        .fill(.white.opacity(0.05))
                    RoundedRectangle(cornerRadius: AuraRadius.cta, style: .continuous)
                        .strokeBorder(.white.opacity(0.14), lineWidth: 1)
                }
        }
        .pressScale()
    }
}

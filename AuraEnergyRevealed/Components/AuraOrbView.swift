//
//  AuraOrbView.swift
//  Aura Energy Revealed
//
//  The reusable living orb — layered conic + radial gradients, real blur,
//  slow ambient loops. Driven by AuraStyle (colors, speed, layer set).
//  Freezes to a still bloom under Reduce Motion, per the a11y contract.
//

import SwiftUI

/// Animation personality per aura, mirroring the "Ten living auras" gallery.
enum OrbPersonality {
    case spinning       // conic rotation (rainbow, purple, violet)
    case breathing      // white — pure luminous core that breathes
    case rippling       // blue, green — expanding halo rings
    case shimmering     // gold, silver — sheen sweep
    case pulsing        // red, pink — warmer, faster pulse
    case drifting       // indigo — slow cosmic drift with starlight
}

struct AuraOrbStyle {
    var colors: [Color]
    var personality: OrbPersonality = .spinning
    var spinDuration: Double = 18
    var breatheDuration: Double = 5

    static let brand = AuraOrbStyle(colors: AuraPalette.spectrum)
}

struct AuraOrbView: View {
    var style: AuraOrbStyle = .brand
    var size: CGFloat = 150
    var coreOpacity: Double = 0.9

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var spinning = false
    @State private var breathing = false
    @State private var rippling = false

    private var animated: Bool { !reduceMotion }

    var body: some View {
        ZStack {
            // Ripple rings (blue / green personalities)
            if style.personality == .rippling {
                ForEach(0..<2, id: \.self) { i in
                    Circle()
                        .strokeBorder(style.colors.first ?? .white, lineWidth: 1.5)
                        .opacity(rippling ? 0 : 0.7)
                        .scaleEffect(rippling ? 1.55 : 0.6)
                        .animation(
                            animated
                                ? .easeOut(duration: 3.5).repeatForever(autoreverses: false).delay(Double(i) * 1.2)
                                : nil,
                            value: rippling
                        )
                }
            }

            // Rotating conic bloom
            Circle()
                .fill(
                    AngularGradient(
                        colors: closedColors,
                        center: .center
                    )
                )
                .blur(radius: size * 0.03)
                .rotationEffect(.degrees(spinning ? 360 : 0))
                .animation(
                    animated && style.personality != .breathing
                        ? .linear(duration: style.spinDuration).repeatForever(autoreverses: false)
                        : nil,
                    value: spinning
                )
                .opacity(coreOpacity)

            // Counter-rotating highlight veil
            Circle()
                .fill(
                    AngularGradient(
                        colors: [.clear, .white.opacity(0.45), .clear, .clear],
                        center: .center
                    )
                )
                .blur(radius: size * 0.06)
                .blendMode(.screen)
                .rotationEffect(.degrees(spinning ? -360 : 0))
                .animation(
                    animated ? .linear(duration: style.spinDuration * 1.33).repeatForever(autoreverses: false) : nil,
                    value: spinning
                )

            // Breathing white nucleus
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.9), style.colors.first?.opacity(0.3) ?? .clear, .clear],
                        center: .init(x: 0.5, y: 0.45),
                        startRadius: 0,
                        endRadius: size * 0.55
                    )
                )
                .scaleEffect(breathing ? 1.08 : 1.0)
                .animation(
                    animated
                        ? .easeInOut(duration: style.breatheDuration).repeatForever(autoreverses: true)
                        : nil,
                    value: breathing
                )

            // Inner vignette so the orb sits into the space-black
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.clear, .clear, AuraPalette.deepSpace.opacity(0.55)],
                        center: .center,
                        startRadius: size * 0.2,
                        endRadius: size * 0.52
                    )
                )
        }
        .frame(width: size, height: size)
        .drawingGroup()
        .shadow(color: (style.colors.first ?? .white).opacity(0.45), radius: size * 0.22)
        .onAppear {
            guard animated else { return }
            spinning = true
            breathing = true
            rippling = true
        }
        .accessibilityHidden(true)
    }

    private var closedColors: [Color] {
        guard let first = style.colors.first else { return [.white] }
        return style.colors.last == first ? style.colors : style.colors + [first]
    }
}

// MARK: - Gentle float (floatY 7s)

struct FloatY: ViewModifier {
    @State private var up = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .offset(y: up ? -10 : 0)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 6).repeatForever(autoreverses: true),
                value: up
            )
            .onAppear { if !reduceMotion { up = true } }
    }
}

extension View {
    func gentleFloat() -> some View { modifier(FloatY()) }
}

//
//  AuraMotion.swift
//  Aura Energy Revealed
//
//  Motion tokens from the spec: micro 120ms · standard 280ms ·
//  expressive 460ms · ambient 5–26s loops. Spring, never linear.
//

import SwiftUI

enum AuraMotion {
    /// 120ms — taps, toggles, haptic-paired.
    static let micro = Animation.spring(response: 0.12, dampingFraction: 0.8)

    /// 280ms — cards and sheets.
    static let standard = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.28)

    /// 460ms — screen transitions, shared elements.
    static let expressive = Animation.spring(response: 0.46, dampingFraction: 0.85)

    /// Gentle rise-fade used for card stacks (stagger externally by 40ms).
    static func riseIn(delay: Double) -> Animation {
        .spring(response: 0.5, dampingFraction: 0.85).delay(delay)
    }
}

// MARK: - Rise-fade on appear (cards "rise-fade on load, 40ms stagger")

struct RiseFadeIn: ViewModifier {
    let index: Int
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : (reduceMotion ? 0 : 18))
            .onAppear {
                withAnimation(AuraMotion.riseIn(delay: Double(index) * 0.04)) {
                    shown = true
                }
            }
    }
}

extension View {
    func riseFadeIn(index: Int = 0) -> some View {
        modifier(RiseFadeIn(index: index))
    }

    /// Press-scale 0.97 for buttons, per spec.
    func pressScale() -> some View {
        buttonStyle(PressScaleStyle())
    }
}

struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(AuraMotion.micro, value: configuration.isPressed)
    }
}

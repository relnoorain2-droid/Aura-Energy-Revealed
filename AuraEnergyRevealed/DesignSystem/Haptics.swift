//
//  Haptics.swift
//  Aura Energy Revealed
//
//  Meaningful haptic feedback — soft, never demanding.
//

import UIKit

enum Haptics {
    static func impactLight() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func impactSoft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    /// Soft ticking used while the scan light bar sweeps.
    static func tick() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.4)
    }
}

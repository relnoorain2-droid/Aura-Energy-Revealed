//
//  AuraPalette.swift
//  Orenda
//
//  The colour system.
//
//  Every token here resolves differently in light and dark appearance, so the
//  whole app re-skins from this one file. Light is the default: warm paper and
//  dark ink, which is deliberately unlike the dark-and-neon look that this app
//  category has settled into.
//
//  Views should never hard-code `.white.opacity(…)` for fills or borders — use
//  `AuraPalette.fill` and `AuraPalette.hairline`, which invert correctly.
//

import SwiftUI
import UIKit

private func uiColor(_ hex: UInt32, _ opacity: Double) -> UIColor {
    UIColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: CGFloat(opacity)
    )
}

extension Color {
    /// Hex initializer, e.g. Color(hex: 0x0B0B12)
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    /// A colour that resolves one way in light appearance and another in dark.
    init(light: UInt32, dark: UInt32, lightOpacity: Double = 1, darkOpacity: Double = 1) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? uiColor(dark, darkOpacity)
                : uiColor(light, lightOpacity)
        })
    }
}

enum AuraPalette {

    // MARK: Neutrals
    //
    // Light: warm paper with near-black ink.
    // Dark:  warm plum-ink with bone text.

    /// App background.
    static let deepSpace = Color(light: 0xFBF7F1, dark: 0x1A1620)

    /// Raised surface — cards, sheets.
    static let surface = Color(light: 0xFFFFFF, dark: 0x241E2C)

    /// Primary text.
    static let ink = Color(light: 0x2A2230, dark: 0xF6F1E9)

    static let inkDim = Color(light: 0x2A2230, dark: 0xF6F1E9, lightOpacity: 0.68, darkOpacity: 0.68)
    static let inkFaint = Color(light: 0x2A2230, dark: 0xF6F1E9, lightOpacity: 0.40, darkOpacity: 0.38)
    static let inkGhost = Color(light: 0x2A2230, dark: 0xF6F1E9, lightOpacity: 0.50, darkOpacity: 0.46)

    /// Subtle surface wash. Replaces hard-coded `.white.opacity(0.05…0.10)`,
    /// which turns invisible on a light background.
    static let fill = Color(light: 0x2A2230, dark: 0xFFFFFF, lightOpacity: 0.045, darkOpacity: 0.06)

    /// Slightly stronger wash for pressed / emphasised states.
    static let fillStrong = Color(light: 0x2A2230, dark: 0xFFFFFF, lightOpacity: 0.085, darkOpacity: 0.11)

    /// Hairline borders.
    static let hairline = Color(light: 0x2A2230, dark: 0xFFFFFF, lightOpacity: 0.12, darkOpacity: 0.10)

    // MARK: Accents
    //
    // Muted rather than neon, and darkened in light appearance so they keep
    // enough contrast against paper. Hue identity is preserved either way, so
    // a violet reading still reads violet.

    static let auroraPurple     = Color(light: 0x6F58A8, dark: 0x8A72C4)
    static let auroraPurpleDeep = Color(light: 0x584293, dark: 0x6B5AA6)
    static let lavender         = Color(light: 0x8B79BE, dark: 0xB3A2D9)
    static let violetLight      = Color(light: 0xA593D2, dark: 0xCCBEEA)
    static let electricBlue     = Color(light: 0x4F7FA6, dark: 0x6E9CC4)
    static let electricBlueDeep = Color(light: 0x3C6A8F, dark: 0x4F86B5)
    static let blueLight        = Color(light: 0x7BA5C0, dark: 0xA8C6DC)
    static let emerald          = Color(light: 0x3E9379, dark: 0x5FB89A)
    static let emeraldLight     = Color(light: 0x62AD95, dark: 0x93D4BE)
    static let gold             = Color(light: 0xB08542, dark: 0xE0B876)
    static let goldLight        = Color(light: 0xC29A5C, dark: 0xEBCD97)
    static let rose             = Color(light: 0xB2647A, dark: 0xD4849B)
    static let roseDeep         = Color(light: 0x9A5266, dark: 0xBF6E86)
    static let softRed          = Color(light: 0xB65B50, dark: 0xD9796E)
    static let amber            = Color(light: 0xB87B44, dark: 0xDB9A63)
    static let indigo           = Color(light: 0x47508A, dark: 0x5A639E)
    static let indigoDeep       = Color(light: 0x2E3560, dark: 0x2E3560)
    static let silver           = Color(light: 0x8D9490, dark: 0xC5C9C6)

    // MARK: Semantic — "alerts are never red-blooded"

    static let success   = emerald
    static let attention = gold
    static let alertSoft = rose
    static let info      = electricBlue

    /// The full-spectrum conic used by the brand mark and the scan orb.
    static let spectrum: [Color] = [
        auroraPurpleDeep, electricBlueDeep, emerald, gold, rose, auroraPurpleDeep
    ]

    static let primaryGradient = LinearGradient(
        colors: [auroraPurple, electricBlue],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let goldGradient = LinearGradient(
        colors: [gold, rose],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Spacing (4pt base) & radii

enum AuraSpacing {
    static let xs: CGFloat = 8
    static let s: CGFloat = 12
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let gutter: CGFloat = 20
}

/// Restrained rather than bubbly. The stock template look leans on very large
/// radii everywhere; pulling these in gives the app a more editorial feel.
enum AuraRadius {
    static let sheet: CGFloat = 20
    static let card: CGFloat = 14
    static let button: CGFloat = 12
    static let cta: CGFloat = 12
    static let tile: CGFloat = 10
}

//
//  AuraPalette.swift
//  Aura Energy Revealed
//
//  Design-system colors, exactly as specified in the handoff:
//  deep space neutrals + the aurora accent spectrum.
//

import SwiftUI

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
}

enum AuraPalette {
    // MARK: Neutrals — "warm dusk", not cold space.
    //
    // The deliberate move away from a pure blue-black background: this base is
    // a warm plum-ink, and the ink on top is bone rather than blue-white. It
    // reads closer to dusk light on paper than to a screensaver of outer space.
    static let deepSpace   = Color(hex: 0x1A1620)   // background
    static let surface     = Color(hex: 0x241E2C)   // raised surface
    static let ink         = Color(hex: 0xF6F1E9)   // warm bone
    static let inkDim      = Color(hex: 0xF6F1E9, opacity: 0.68)
    static let inkFaint    = Color(hex: 0xF6F1E9, opacity: 0.38)
    static let inkGhost    = Color(hex: 0xF6F1E9, opacity: 0.46)

    // MARK: Accents — muted and earthy rather than neon.
    //
    // Hue identity is preserved (violet still reads violet, gold still gold) so
    // readings stay distinguishable, but saturation is pulled well back. The
    // result is calmer and far less generic than the stock neon spectrum.
    static let auroraPurple      = Color(hex: 0x8A72C4)
    static let auroraPurpleDeep  = Color(hex: 0x6B5AA6)
    static let lavender          = Color(hex: 0xB3A2D9)
    static let violetLight       = Color(hex: 0xCCBEEA)
    static let electricBlue      = Color(hex: 0x6E9CC4)
    static let electricBlueDeep  = Color(hex: 0x4F86B5)
    static let blueLight         = Color(hex: 0xA8C6DC)
    static let emerald           = Color(hex: 0x5FB89A)
    static let emeraldLight      = Color(hex: 0x93D4BE)
    static let gold              = Color(hex: 0xE0B876)
    static let goldLight         = Color(hex: 0xEBCD97)
    static let rose              = Color(hex: 0xD4849B)
    static let roseDeep          = Color(hex: 0xBF6E86)
    static let softRed           = Color(hex: 0xD9796E)
    static let amber             = Color(hex: 0xDB9A63)
    static let indigo            = Color(hex: 0x5A639E)
    static let indigoDeep        = Color(hex: 0x2E3560)
    static let silver            = Color(hex: 0xC5C9C6)

    // Semantic — "alerts are never red-blooded"
    static let success   = emerald
    static let attention = gold
    static let alertSoft = rose
    static let info      = electricBlue

    /// The full-spectrum conic used by the brand mark, scan orb, and rainbow aura.
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

// MARK: - Spacing (4pt base) & radii, from the spec

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

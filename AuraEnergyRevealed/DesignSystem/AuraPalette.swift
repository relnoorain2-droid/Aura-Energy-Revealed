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
    // Neutrals
    static let deepSpace   = Color(hex: 0x0B0B12)   // background
    static let surface     = Color(hex: 0x14141F)   // raised surface
    static let ink         = Color(hex: 0xF4F3F8)   // Ink 100
    static let inkDim      = Color(hex: 0xF4F3F8, opacity: 0.66)
    static let inkFaint    = Color(hex: 0xF4F3F8, opacity: 0.38)
    static let inkGhost    = Color(hex: 0xF4F3F8, opacity: 0.45)

    // Aurora spectrum
    static let auroraPurple      = Color(hex: 0x8B6BF0)
    static let auroraPurpleDeep  = Color(hex: 0x6D4CE6)
    static let lavender          = Color(hex: 0xA78BFA)
    static let violetLight       = Color(hex: 0xC6A9FF)
    static let electricBlue      = Color(hex: 0x5AA9FF)
    static let electricBlueDeep  = Color(hex: 0x2FA8FF)
    static let blueLight         = Color(hex: 0x8FD1FF)
    static let emerald           = Color(hex: 0x2FD3A0)
    static let emeraldLight      = Color(hex: 0x7EE8C6)
    static let gold              = Color(hex: 0xF0CE86)
    static let goldLight         = Color(hex: 0xF3D89A)
    static let rose              = Color(hex: 0xEC6FA6)
    static let roseDeep          = Color(hex: 0xE05C93)
    static let softRed           = Color(hex: 0xEF6E6E)
    static let amber             = Color(hex: 0xEF9E5E)
    static let indigo            = Color(hex: 0x4E5BD0)
    static let indigoDeep        = Color(hex: 0x1E2A6E)
    static let silver            = Color(hex: 0xCFD6DE)

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

enum AuraRadius {
    static let sheet: CGFloat = 28
    static let card: CGFloat = 22
    static let button: CGFloat = 16
    static let cta: CGFloat = 18
    static let tile: CGFloat = 12
}

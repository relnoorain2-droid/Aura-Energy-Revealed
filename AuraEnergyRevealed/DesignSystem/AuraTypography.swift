//
//  AuraTypography.swift
//  Aura Energy Revealed
//
//  Display: Cormorant Garamond (serif, "one serif for soul")
//  Interface: Manrope ("one grotesque for clarity")
//  Mono: IBM Plex Mono (metadata accents)
//
//  Fonts gracefully fall back to system serif / sans / mono when the
//  bundled TTFs are absent (see Resources/Fonts/README).
//

import SwiftUI
import UIKit
import CoreText

enum AuraFont {

    private static func fontExists(_ name: String) -> Bool {
        UIFont(name: name, size: 12) != nil
    }

    /// Serif display — hero moments, aura names, section titles.
    static func display(_ size: CGFloat, relativeTo style: Font.TextStyle = .title) -> Font {
        if fontExists("CormorantGaramond-Medium") {
            return .custom("CormorantGaramond-Medium", size: size, relativeTo: style)
        }
        return .system(size: size, weight: .regular, design: .serif)
    }

    /// Interface text — all UI, labels, body, buttons.
    static func text(_ size: CGFloat, weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        let name: String
        switch weight {
        case .bold, .heavy, .black: name = "Manrope-Bold"
        case .semibold: name = "Manrope-SemiBold"
        case .medium: name = "Manrope-Medium"
        case .light, .thin, .ultraLight: name = "Manrope-Light"
        default: name = "Manrope-Regular"
        }
        if fontExists(name) {
            return .custom(name, size: size, relativeTo: style)
        }
        return .system(size: size, weight: weight)
    }

    /// Mono accent — timestamps, spec labels, energy values. Used sparingly.
    static func mono(_ size: CGFloat, relativeTo style: Font.TextStyle = .caption) -> Font {
        if fontExists("IBMPlexMono-Medium") {
            return .custom("IBMPlexMono-Medium", size: size, relativeTo: style)
        }
        return .system(size: size, weight: .medium, design: .monospaced)
    }
}

// MARK: - Mono label style (uppercase, tracked)

struct MonoLabel: View {
    let text: String
    var color: Color = AuraPalette.inkGhost
    var size: CGFloat = 11

    var body: some View {
        Text(text.uppercased())
            .font(AuraFont.mono(size))
            .tracking(1.6)
            .foregroundStyle(color)
    }
}

// MARK: - Runtime font registration (avoids Info.plist UIAppFonts)

enum FontRegistrar {
    /// Registers every .ttf / .otf found in the bundle so dropped-in fonts
    /// (Resources/Fonts) work without any Info.plist changes.
    static func registerBundledFonts() {
        let extensions = ["ttf", "otf"]
        for ext in extensions {
            guard let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) else { continue }
            for url in urls {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }
}

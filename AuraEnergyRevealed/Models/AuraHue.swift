//
//  AuraHue.swift
//  Aura Energy Revealed
//
//  The ten living auras (+ Violet, the featured reading in the spec).
//  Each colour is its own creature of light with a distinct personality.
//

import SwiftUI

enum AuraHue: String, CaseIterable, Codable, Identifiable {
    case rainbow, white, blue, purple, violet, gold, green, red, indigo, pink, silver

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }

    /// Serif-display colour used for the aura name.
    var titleColor: Color {
        switch self {
        case .rainbow: AuraPalette.lavender
        case .white:   .white
        case .blue:    AuraPalette.blueLight
        case .purple:  AuraPalette.lavender
        case .violet:  AuraPalette.violetLight
        case .gold:    AuraPalette.goldLight
        case .green:   AuraPalette.emeraldLight
        case .red:     Color(hex: 0xFFB3A0)
        case .indigo:  Color(hex: 0x8A96E8)
        case .pink:    Color(hex: 0xFFD0E6)
        case .silver:  AuraPalette.silver
        }
    }

    var orbStyle: AuraOrbStyle {
        switch self {
        case .rainbow:
            AuraOrbStyle(colors: [Color(hex: 0xEF6E6E), AuraPalette.gold, AuraPalette.emerald, AuraPalette.electricBlueDeep, AuraPalette.auroraPurple, AuraPalette.rose], personality: .spinning, spinDuration: 14)
        case .white:
            AuraOrbStyle(colors: [.white, Color(hex: 0xE8E6F5)], personality: .breathing, breatheDuration: 5)
        case .blue:
            AuraOrbStyle(colors: [AuraPalette.blueLight, AuraPalette.electricBlueDeep], personality: .rippling)
        case .purple:
            AuraOrbStyle(colors: [AuraPalette.auroraPurple, AuraPalette.violetLight, AuraPalette.auroraPurpleDeep], personality: .spinning)
        case .violet:
            AuraOrbStyle(colors: [AuraPalette.lavender, AuraPalette.auroraPurple, AuraPalette.violetLight], personality: .spinning)
        case .gold:
            AuraOrbStyle(colors: [AuraPalette.goldLight, AuraPalette.gold, Color(hex: 0xFFF6DD)], personality: .shimmering, spinDuration: 8)
        case .green:
            AuraOrbStyle(colors: [AuraPalette.emeraldLight, AuraPalette.emerald], personality: .rippling, breatheDuration: 5)
        case .red:
            AuraOrbStyle(colors: [Color(hex: 0xFFB3A0), AuraPalette.softRed, Color(hex: 0xB83A3A)], personality: .pulsing, breatheDuration: 2.2)
        case .indigo:
            AuraOrbStyle(colors: [AuraPalette.indigoDeep, AuraPalette.indigo, Color(hex: 0x2A1F6E)], personality: .drifting, spinDuration: 26, breatheDuration: 6)
        case .pink:
            AuraOrbStyle(colors: [Color(hex: 0xFFD0E6), AuraPalette.rose], personality: .pulsing, breatheDuration: 4.5)
        case .silver:
            AuraOrbStyle(colors: [Color(hex: 0x7D8794), Color(hex: 0xE8EDF2), .white, Color(hex: 0xB6BFC9)], personality: .shimmering, spinDuration: 7)
        }
    }

    /// Essence line, e.g. "Intuition · serenity · inner vision".
    var essence: String {
        switch self {
        case .rainbow: "Joy · possibility · celebration"
        case .white:   "Purity · clarity · spiritual openness"
        case .blue:    "Communication · peace · trust"
        case .purple:  "Intuition · mystery · higher awareness"
        case .violet:  "Intuition · serenity · inner vision"
        case .gold:    "Abundance · wisdom · high vibration"
        case .green:   "Growth · balance · the heart at rest"
        case .red:     "Passion · drive · grounded vitality"
        case .indigo:  "Deep intuition · the visionary"
        case .pink:    "Love · compassion · gentle warmth"
        case .silver:  "Protection · insight · refined intuition"
        }
    }

    var meaning: String {
        switch self {
        case .rainbow: "A rare, celebratory field — the full spectrum moving through you at once. Life feels wide open today; let yourself enjoy it."
        case .white:   "A pure, luminous field. Your energy is clear and receptive — a beautiful day for stillness and honest reflection."
        case .blue:    "Calm ripples outward from your centre like still water. Words come easily today; speak gently and be heard."
        case .purple:  "Two currents of intuition swirl into a soft core. Trust the quiet knowing beneath your thoughts."
        case .violet:  "Your field glows with a deep violet — a sign of heightened intuition and a mind turned gently inward. Honour the quiet; insight is close."
        case .gold:    "A shimmering sheen sweeps across radiant light. You carry abundance today — share it without spending yourself."
        case .green:   "A soft healing pulse with a slow expanding halo. Your heart is open and at ease; you're giving from a full cup."
        case .red:     "A faster, warmer pulse radiating heat. There's fire in you today — point it at what matters most."
        case .indigo:  "A deep, slow cosmic drift flecked with starlight. The visionary in you is awake; dream on paper."
        case .pink:    "A tender bloom that softly expands and contracts. Lead with compassion today — starting with yourself."
        case .silver:  "A cool metallic sheen glides around a reflective core. You see clearly through the noise; trust that refined instinct."
        }
    }
}

// MARK: - Scan modes ("Read the aura of anything")

enum ScanMode: String, CaseIterable, Codable, Identifiable {
    case selfAura, pet, plant, home, room, object, food, relationship

    var id: String { rawValue }

    var title: String {
        switch self {
        case .selfAura: "Self aura"
        case .pet: "Pet aura"
        case .plant: "Plant aura"
        case .home: "Home aura"
        case .room: "Room aura"
        case .object: "Object aura"
        case .food: "Food aura"
        case .relationship: "Relationship"
        }
    }

    var symbol: String {
        switch self {
        case .selfAura: "sparkle"
        case .pet: "pawprint"
        case .plant: "leaf"
        case .home: "house"
        case .room: "sofa"
        case .object: "seal"
        case .food: "fork.knife"
        case .relationship: "heart.circle"
        }
    }

    var blurb: String {
        switch self {
        case .selfAura: "Your own field, read in a breath"
        case .pet: "Your companion's mood & bond"
        case .plant: "A plant's vitality & presence"
        case .home: "The overall energy of your space"
        case .room: "A single room's mood"
        case .object: "Crystals, keepsakes, meaningful things"
        case .food: "A meal's energetic quality"
        case .relationship: "Two fields, and how they blend"
        }
    }

    /// Premium gating: only the self scan is available on the free tier.
    var isPremium: Bool { self != .selfAura }
}

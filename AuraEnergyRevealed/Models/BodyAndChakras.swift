//
//  BodyAndChakras.swift
//  Aura Energy Revealed
//
//  The 14 body regions and 7 chakras from the spec, each with meaning
//  and a matched practice. One premium template drives all part details.
//

import SwiftUI

// MARK: - Chakras

struct Chakra: Identifiable {
    let id: String
    let name: String
    let theme: String
    let color: Color
    let balance: Double        // 0...1, sampled per reading
    let practice: String

    static func sample(seed: Int) -> [Chakra] {
        var rng = SeededGenerator(seed: seed)
        func level() -> Double { Double.random(in: 0.45...0.95, using: &rng) }
        return [
            Chakra(id: "crown", name: "Crown", theme: "Connection", color: AuraPalette.auroraPurple, balance: level(), practice: "Silent sitting · 5 min"),
            Chakra(id: "thirdEye", name: "Third Eye", theme: "Intuition", color: Color(hex: 0x5B6BD0), balance: level(), practice: "Third-eye meditation · 8 min"),
            Chakra(id: "throat", name: "Throat", theme: "Expression", color: AuraPalette.electricBlue, balance: level(), practice: "Humming breath · 4 min"),
            Chakra(id: "heart", name: "Heart", theme: "Love", color: AuraPalette.emerald, balance: level(), practice: "Loving-kindness · 6 min"),
            Chakra(id: "solarPlexus", name: "Solar Plexus", theme: "Will", color: AuraPalette.gold, balance: level(), practice: "Morning intention · 3 min"),
            Chakra(id: "sacral", name: "Sacral", theme: "Creativity", color: AuraPalette.amber, balance: level(), practice: "Free journaling · 10 min"),
            Chakra(id: "root", name: "Root", theme: "Grounding", color: AuraPalette.softRed, balance: level(), practice: "Grounding breath · 5 min"),
        ]
    }
}

// MARK: - Body regions (14)

struct BodyRegion: Identifiable {
    let id: String
    let name: String
    let theme: String
    let color: Color
    let chakraName: String
    let auraName: String
    let reading: String
    let practice: String
    let practiceDuration: String
    /// Vertical position along the silhouette meridian, 0 (head) ... 1 (feet).
    let meridianPosition: Double

    static let all: [BodyRegion] = [
        BodyRegion(id: "head", name: "Head", theme: "Thought · vision", color: AuraPalette.lavender, chakraName: "Crown", auraName: "Purple",
                   reading: "Your thoughts move like slow clouds today — unhurried and clear. A good day for the kind of thinking that needs room.",
                   practice: "Open Awareness", practiceDuration: "7 min meditation", meridianPosition: 0.04),
        BodyRegion(id: "face", name: "Face", theme: "Presence", color: AuraPalette.lavender, chakraName: "Crown", auraName: "Purple",
                   reading: "You meet the world softly today. The presence you carry is calm and open — people feel easier around you.",
                   practice: "Soft Gaze", practiceDuration: "4 min practice", meridianPosition: 0.10),
        BodyRegion(id: "eyes", name: "Eyes", theme: "Insight", color: AuraPalette.auroraPurple, chakraName: "Third Eye", auraName: "Violet",
                   reading: "Your inner vision is sharp beneath the surface. Notice what you keep noticing — it's trying to tell you something.",
                   practice: "Third-Eye Meditation", practiceDuration: "8 min meditation", meridianPosition: 0.13),
        BodyRegion(id: "neck", name: "Neck", theme: "Expression", color: AuraPalette.electricBlue, chakraName: "Throat", auraName: "Blue",
                   reading: "Words are close to the surface today. Say the kind thing you've been holding — it will land well.",
                   practice: "Humming Breath", practiceDuration: "4 min practice", meridianPosition: 0.20),
        BodyRegion(id: "shoulders", name: "Shoulders", theme: "Burden · strength", color: AuraPalette.electricBlue, chakraName: "Throat", auraName: "Blue",
                   reading: "You're carrying a little more than you need to. Set one thing down today — even a small one counts.",
                   practice: "Shoulder Release", practiceDuration: "5 min practice", meridianPosition: 0.27),
        BodyRegion(id: "heart", name: "Heart", theme: "Compassion", color: AuraPalette.emerald, chakraName: "Heart", auraName: "Green",
                   reading: "Your heart centre radiates a soft green — open, generous, and at ease. You're giving from a full cup today. Protect that warmth; you needn't earn rest.",
                   practice: "Loving-Kindness", practiceDuration: "6 min meditation", meridianPosition: 0.36),
        BodyRegion(id: "chest", name: "Chest", theme: "Breath · openness", color: AuraPalette.emerald, chakraName: "Heart", auraName: "Green",
                   reading: "Your breath wants to be deeper than you're letting it. Three slow breaths, right now — feel the space open.",
                   practice: "Box Breathing", practiceDuration: "5 min practice", meridianPosition: 0.42),
        BodyRegion(id: "hands", name: "Hands", theme: "Creation · giving", color: AuraPalette.gold, chakraName: "Solar Plexus", auraName: "Gold",
                   reading: "Your hands hold maker's energy today. Start the small thing you've been circling — it will grow under your touch.",
                   practice: "Mindful Making", practiceDuration: "10 min practice", meridianPosition: 0.50),
        BodyRegion(id: "arms", name: "Arms", theme: "Embrace · action", color: AuraPalette.gold, chakraName: "Solar Plexus", auraName: "Gold",
                   reading: "There's warm, capable energy in your reach today. Offer the help before it's asked for.",
                   practice: "Energy Stretch", practiceDuration: "6 min practice", meridianPosition: 0.55),
        BodyRegion(id: "solarPlexus", name: "Solar Plexus", theme: "Will · confidence", color: AuraPalette.gold, chakraName: "Solar Plexus", auraName: "Gold",
                   reading: "Your centre of will glows steady. Decisions made today from the gut will hold — trust the first clear answer.",
                   practice: "Morning Intention", practiceDuration: "3 min practice", meridianPosition: 0.60),
        BodyRegion(id: "stomach", name: "Stomach", theme: "Intuition · trust", color: AuraPalette.amber, chakraName: "Sacral", auraName: "Gold",
                   reading: "Your gut sense is quiet but accurate today. If something feels slightly off, honour that whisper.",
                   practice: "Body Scan", practiceDuration: "9 min meditation", meridianPosition: 0.66),
        BodyRegion(id: "lowerBody", name: "Lower Body", theme: "Grounding", color: AuraPalette.softRed, chakraName: "Root", auraName: "Red",
                   reading: "Your base is steady and warm. You're more grounded than you feel — let your body convince your mind.",
                   practice: "Grounding Breath", practiceDuration: "5 min practice", meridianPosition: 0.76),
        BodyRegion(id: "legs", name: "Legs", theme: "Momentum", color: AuraPalette.softRed, chakraName: "Root", auraName: "Red",
                   reading: "There's forward motion stored in you today. A walk without your phone will turn it into clarity.",
                   practice: "Walking Meditation", practiceDuration: "12 min practice", meridianPosition: 0.86),
        BodyRegion(id: "feet", name: "Feet", theme: "Roots · stability", color: AuraPalette.softRed, chakraName: "Root", auraName: "Red",
                   reading: "Your roots run deep and quiet. Wherever you stand today, you belong there.",
                   practice: "Standing Grounding", practiceDuration: "4 min practice", meridianPosition: 0.96),
    ]
}

// MARK: - Meditations

struct Meditation: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let minutes: Int
    let hue: AuraHue
    let isPremium: Bool

    static let library: [Meditation] = [
        Meditation(id: "heartOpening", title: "Heart Opening", subtitle: "Breathe with the light", minutes: 8, hue: .green, isPremium: false),
        Meditation(id: "thirdEye", title: "Third-Eye Meditation", subtitle: "Deepen today's clarity", minutes: 8, hue: .violet, isPremium: false),
        Meditation(id: "groundingBreath", title: "Grounding Breath", subtitle: "Settle into your roots", minutes: 5, hue: .red, isPremium: false),
        Meditation(id: "lovingKindness", title: "Loving-Kindness", subtitle: "Warmth, outward and inward", minutes: 6, hue: .pink, isPremium: true),
        Meditation(id: "goldenHour", title: "Golden Hour", subtitle: "Gratitude before sleep", minutes: 10, hue: .gold, isPremium: true),
        Meditation(id: "stillWater", title: "Still Water", subtitle: "Calm the inner current", minutes: 12, hue: .blue, isPremium: true),
        Meditation(id: "cosmicDrift", title: "Cosmic Drift", subtitle: "For the visionary hour", minutes: 15, hue: .indigo, isPremium: true),
        Meditation(id: "morningLight", title: "Morning Light", subtitle: "Begin with clear energy", minutes: 5, hue: .white, isPremium: true),
    ]
}

// MARK: - Deterministic RNG for stable daily readings

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: Int) { state = UInt64(bitPattern: Int64(seed)) &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

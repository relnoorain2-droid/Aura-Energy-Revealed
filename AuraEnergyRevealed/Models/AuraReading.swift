//
//  AuraReading.swift
//  Aura Energy Revealed
//
//  SwiftData models: readings + journal entries. Local-first, iCloud-ready.
//

import Foundation
import SwiftData

@Model
final class AuraReading {
    var date: Date
    var modeRaw: String
    var dominantRaw: String
    var secondaryRaw: String
    var tertiaryRaw: String
    var dominantFraction: Double
    var secondaryFraction: Double
    var tertiaryFraction: Double
    var essence: String
    var interpretation: String
    var intuition: Double
    var calm: Double
    var vitality: Double
    var suggestedPractice: String
    var isFavorite: Bool
    @Attribute(.externalStorage) var photoData: Data?

    init(
        date: Date = .now,
        mode: ScanMode = .selfAura,
        dominant: AuraHue,
        secondary: AuraHue,
        tertiary: AuraHue,
        dominantFraction: Double,
        secondaryFraction: Double,
        tertiaryFraction: Double,
        essence: String,
        interpretation: String,
        intuition: Double,
        calm: Double,
        vitality: Double,
        suggestedPractice: String,
        photoData: Data? = nil
    ) {
        self.date = date
        self.modeRaw = mode.rawValue
        self.dominantRaw = dominant.rawValue
        self.secondaryRaw = secondary.rawValue
        self.tertiaryRaw = tertiary.rawValue
        self.dominantFraction = dominantFraction
        self.secondaryFraction = secondaryFraction
        self.tertiaryFraction = tertiaryFraction
        self.essence = essence
        self.interpretation = interpretation
        self.intuition = intuition
        self.calm = calm
        self.vitality = vitality
        self.suggestedPractice = suggestedPractice
        self.isFavorite = false
        self.photoData = photoData
    }

    var mode: ScanMode { ScanMode(rawValue: modeRaw) ?? .selfAura }
    var dominant: AuraHue { AuraHue(rawValue: dominantRaw) ?? .violet }
    var secondary: AuraHue { AuraHue(rawValue: secondaryRaw) ?? .blue }
    var tertiary: AuraHue { AuraHue(rawValue: tertiaryRaw) ?? .green }
}

@Model
final class JournalEntry {
    var date: Date
    var prompt: String
    var text: String
    var moods: [String]
    var auraRaw: String?

    init(date: Date = .now, prompt: String, text: String = "", moods: [String] = [], aura: AuraHue? = nil) {
        self.date = date
        self.prompt = prompt
        self.text = text
        self.moods = moods
        self.auraRaw = aura?.rawValue
    }

    var aura: AuraHue? {
        auraRaw.flatMap(AuraHue.init(rawValue:))
    }
}

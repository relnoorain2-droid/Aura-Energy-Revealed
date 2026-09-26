//
//  DailyRitual.swift
//  Orenda
//
//  The Daily Ritual — a short, guided four-part practice that changes every day
//  and adapts to the colour of your most recent reading.
//
//  This is deliberately not a generic "meditation list". Each day composes a
//  breath pattern, an intention prompt, a reflection question and a closing
//  line, chosen deterministically from the date so that everyone's ritual is
//  stable for the day but never the same two days running.
//

import Foundation
import SwiftData

// MARK: - Breath patterns

struct BreathPattern: Sendable, Equatable, Identifiable {
    let id: String
    let name: String
    let purpose: String
    let inhale: Int
    let hold: Int
    let exhale: Int
    let rest: Int
    let rounds: Int

    var cycleSeconds: Int { inhale + hold + exhale + rest }
    var totalSeconds: Int { cycleSeconds * rounds }

    var cadenceLabel: String {
        var parts = ["\(inhale)"]
        if hold > 0 { parts.append("\(hold)") }
        parts.append("\(exhale)")
        if rest > 0 { parts.append("\(rest)") }
        return parts.joined(separator: "–")
    }

    static let settling = BreathPattern(
        id: "settling", name: "Settling breath",
        purpose: "Lengthens the exhale to take the edge off a busy nervous system.",
        inhale: 4, hold: 7, exhale: 8, rest: 0, rounds: 4
    )

    static let steady = BreathPattern(
        id: "steady", name: "Steady square",
        purpose: "Equal sides. Useful when your attention keeps sliding off things.",
        inhale: 4, hold: 4, exhale: 4, rest: 4, rounds: 5
    )

    static let coherent = BreathPattern(
        id: "coherent", name: "Coherent breath",
        purpose: "A slow, even rhythm that brings heart and breath into step.",
        inhale: 5, hold: 0, exhale: 5, rest: 0, rounds: 6
    )

    static let kindling = BreathPattern(
        id: "kindling", name: "Kindling breath",
        purpose: "A slightly fuller inhale for days that need warmth rather than calm.",
        inhale: 6, hold: 2, exhale: 4, rest: 0, rounds: 5
    )

    static let grounding = BreathPattern(
        id: "grounding", name: "Grounding breath",
        purpose: "Long and low, to bring you back down into your feet.",
        inhale: 4, hold: 2, exhale: 8, rest: 2, rounds: 4
    )

    static let all: [BreathPattern] = [.settling, .steady, .coherent, .kindling, .grounding]
}

// MARK: - The ritual

struct DailyRitual: Sendable, Equatable {
    let date: Date
    let aura: AuraHue?
    let title: String
    let opening: String
    let breath: BreathPattern
    let intentionPrompt: String
    let reflectionPrompt: String
    let closing: String

    var estimatedMinutes: Int {
        max(3, Int((Double(breath.totalSeconds) / 60.0).rounded(.up)) + 2)
    }
}

enum DailyRitualComposer {

    // MARK: Content banks (original copy — intentionally specific, not generic)

    private static let openings = [
        "Before anything else asks for you today, take this small amount of time for yourself.",
        "You don't need to arrive here calm. You only need to arrive.",
        "Let this be the one thing today that isn't trying to get somewhere.",
        "Put the day down for a few minutes. It will still be there.",
        "Nothing to fix in here. Just somewhere to check what's actually true right now.",
        "This is a short practice, and short is enough when it's honest.",
        "Whatever mood you came in with is welcome. Start from there."
    ]

    private static let intentionPrompts = [
        "What is one thing you'd like to protect your attention for today?",
        "If today went gently, what would be different about how you moved through it?",
        "What would you like to give yourself more of — and what less?",
        "Name one thing you're willing to let be imperfect today.",
        "What's the quality you want to carry into your next conversation?",
        "What would 'enough' look like by this evening?",
        "Is there something you keep postponing that would take ten minutes?"
    ]

    private static let reflectionPrompts = [
        "What's taking up the most room in you right now — and is it yours to carry?",
        "Where in your body do you notice today sitting?",
        "What have you been telling yourself this week? Would you say it to a friend?",
        "What's one thing that went unnoticed today that deserved noticing?",
        "If your energy had a weather forecast, what would it read?",
        "What are you avoiding, and what would make it smaller?",
        "What's something you're quietly proud of that nobody knows about?",
        "Who would you like to be gentler with — including yourself?"
    ]

    private static let closings = [
        "That's the whole practice. Carry the slower breath with you if you can.",
        "Nothing needs to change immediately. Noticing is already the work.",
        "You showed up. That's the part that accumulates.",
        "Let the rest of the day be ordinary. This was the deliberate part.",
        "Come back tomorrow and see what's shifted, even slightly."
    ]

    private static let titles = [
        "Today's ritual", "A quiet few minutes", "Your daily check-in",
        "Settle, then decide", "The slow part of the day"
    ]

    // MARK: Composition

    /// Breath pattern matched to the colour of the most recent reading.
    private static func breath(for aura: AuraHue?) -> BreathPattern {
        guard let aura else { return .coherent }
        switch aura {
        case .red:                     return .grounding
        case .gold, .rainbow:          return .coherent
        case .blue, .white, .silver:   return .settling
        case .green, .pink:            return .coherent
        case .violet, .purple, .indigo: return .settling
        }
    }

    /// Stable for a given calendar day, different from one day to the next.
    private static func seed(for date: Date) -> Int {
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return (parts.year ?? 2026) * 10_000 + (parts.month ?? 1) * 100 + (parts.day ?? 1)
    }

    static func ritual(for date: Date = .now, aura: AuraHue?) -> DailyRitual {
        let s = seed(for: date)
        // Different multipliers so the four picks don't move in lockstep.
        let opening = openings[abs(s &* 7) % openings.count]
        let intention = intentionPrompts[abs(s &* 13) % intentionPrompts.count]
        let reflection = reflectionPrompts[abs(s &* 29) % reflectionPrompts.count]
        let closing = closings[abs(s &* 37) % closings.count]
        let title = titles[abs(s &* 53) % titles.count]

        return DailyRitual(
            date: date,
            aura: aura,
            title: title,
            opening: opening,
            breath: breath(for: aura),
            intentionPrompt: intention,
            reflectionPrompt: reflection,
            closing: closing
        )
    }
}

// MARK: - Persistence

@Model
final class RitualCompletion {
    var date: Date
    var intention: String
    var reflection: String
    var auraRaw: String?
    var breathPatternID: String
    var secondsPracticed: Int

    init(
        date: Date = .now,
        intention: String = "",
        reflection: String = "",
        aura: AuraHue? = nil,
        breathPatternID: String = "",
        secondsPracticed: Int = 0
    ) {
        self.date = date
        self.intention = intention
        self.reflection = reflection
        self.auraRaw = aura?.rawValue
        self.breathPatternID = breathPatternID
        self.secondsPracticed = secondsPracticed
    }

    var aura: AuraHue? { auraRaw.flatMap(AuraHue.init(rawValue:)) }
}

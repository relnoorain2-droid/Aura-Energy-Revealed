//
//  StreakService.swift
//  Aura Energy Revealed
//
//  A forgiving streak: one "grace day" a week keeps it alive —
//  this space never shames a missed day.
//

import Foundation

enum StreakService {

    /// Current streak length in days, allowing one missed (grace) day
    /// per rolling 7 days.
    static func currentStreak(readingDates: [Date]) -> Int {
        guard !readingDates.isEmpty else { return 0 }
        let calendar = Calendar.current
        let days = Set(readingDates.map { calendar.startOfDay(for: $0) })

        var streak = 0
        var graceUsedInWindow = 0
        var cursor = calendar.startOfDay(for: .now)

        // If nothing today yet, allow the streak to count from yesterday.
        if !days.contains(cursor) {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }

        while true {
            if days.contains(cursor) {
                streak += 1
            } else {
                graceUsedInWindow += 1
                if graceUsedInWindow > 1 { break }
            }
            // Reset grace allowance every 7 counted days
            if streak > 0 && streak % 7 == 0 { graceUsedInWindow = 0 }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
            if streak > 999 { break }
        }
        return streak
    }

    static func hasReadingToday(readingDates: [Date]) -> Bool {
        let calendar = Calendar.current
        return readingDates.contains { calendar.isDateInToday($0) }
    }
}

// MARK: - Badges

struct Badge: Identifiable {
    let id: String
    let emoji: String
    let name: String
    let caption: String
    let isUnlocked: (_ readings: [AuraReading], _ streak: Int) -> Bool

    static let all: [Badge] = [
        Badge(id: "firstLight", emoji: "🌅", name: "First Light", caption: "1st reading") { readings, _ in
            !readings.isEmpty
        },
        Badge(id: "kindled", emoji: "🔥", name: "Kindled", caption: "7-day streak") { _, streak in
            streak >= 7
        },
        Badge(id: "spectrum", emoji: "🌈", name: "Spectrum", caption: "Seen 7 colours") { readings, _ in
            Set(readings.map(\.dominant)).count >= 7
        },
        Badge(id: "stillMind", emoji: "🧘", name: "Still Mind", caption: "10 meditations") { _, _ in
            UserDefaults.standard.integer(forKey: "meditationsCompleted") >= 10
        },
        Badge(id: "luminary", emoji: "🌟", name: "Luminary", caption: "30-day streak") { _, streak in
            streak >= 30
        },
        Badge(id: "nightOwl", emoji: "🌙", name: "Night Owl", caption: "Evening reading") { readings, _ in
            readings.contains { Calendar.current.component(.hour, from: $0.date) >= 22 }
        },
    ]
}

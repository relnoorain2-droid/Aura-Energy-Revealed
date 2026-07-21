//
//  AuraEngine.swift
//  Aura Energy Revealed
//
//  Slot-based, fully on-device interpretation engine. No network, no AI API.
//
//  A reading is composed from five curated slots —
//    1. Observation        (what your field shows right now, per colour)
//    2. Aura imagery       (the mystical visual of the colour, per colour)
//    3. Energy bridge      (how the secondary colour weaves in)
//    4. Guidance           (personalized: intention, time of day, mood)
//    5. Closing affirmation(personalized: streak, history, first reading)
//
//  Variety comes from three layers:
//    · large hand-written pools (editorial control keeps the premium tone)
//    · a high-entropy seed (photo pixel fingerprint + time + mode +
//      intentions + a monotonic scan counter) so repeated scans differ
//    · ReadingMemory, which remembers combinations for ~3 weeks and
//      re-rolls to avoid repeats (UserDefaults, on-device only)
//

import Foundation
import UIKit

// MARK: - Protocol (seam for any future engine — still no view changes needed)

protocol AuraInterpreting {
    func makeReading(
        mode: ScanMode,
        photo: UIImage?,
        intentions: [String],
        history: [AuraReading],
        recentMoods: [String]
    ) -> DraftReading
}

extension AuraInterpreting {
    /// Backwards-compatible convenience (no journal moods available).
    func makeReading(mode: ScanMode, photo: UIImage?, intentions: [String], history: [AuraReading]) -> DraftReading {
        makeReading(mode: mode, photo: photo, intentions: intentions, history: history, recentMoods: [])
    }
}

struct DraftReading {
    var mode: ScanMode
    var dominant: AuraHue
    var secondary: AuraHue
    var tertiary: AuraHue
    var dominantFraction: Double
    var secondaryFraction: Double
    var tertiaryFraction: Double
    var essence: String
    var interpretation: String
    var intuition: Double
    var calm: Double
    var vitality: Double
    var suggestedPractice: String
}

// MARK: - Anti-repetition memory (~3 weeks, UserDefaults, on-device)

final class ReadingMemory {
    static let shared = ReadingMemory()

    private let storageKey = "auraEngine.readingMemory.v1"
    private let retention: TimeInterval = 21 * 24 * 3600   // ≈ 3 weeks
    private let maxEntries = 300
    private var entries: [String: Date]

    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
        if let data = userDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: Date].self, from: data) {
            entries = decoded
        } else {
            entries = [:]
        }
        purge()
    }

    private let defaults: UserDefaults

    func contains(_ signature: String) -> Bool {
        entries[signature] != nil
    }

    func remember(_ signature: String) {
        entries[signature] = .now
        purge()
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: storageKey)
        }
    }

    private func purge() {
        let cutoff = Date.now.addingTimeInterval(-retention)
        entries = entries.filter { $0.value > cutoff }
        if entries.count > maxEntries {
            let sorted = entries.sorted { $0.value > $1.value }.prefix(maxEntries)
            entries = Dictionary(uniqueKeysWithValues: Array(sorted))
        }
    }
}

// MARK: - High-entropy seed (photo fingerprint + time + mode + selections)

enum ScanSeed {

    /// FNV-1a over a 16×16 downsample of the actual pixels — two different
    /// photos of the same size no longer share a seed.
    static func fingerprint(of image: UIImage) -> UInt64 {
        let size = CGSize(width: 16, height: 16)
        let renderer = UIGraphicsImageRenderer(size: size)
        let small = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let cg = small.cgImage,
              let data = cg.dataProvider?.data as Data? else { return 0 }
        var hash: UInt64 = 0xCBF29CE484222325
        for byte in data {
            hash = (hash ^ UInt64(byte)) &* 0x100000001B3
        }
        return hash
    }

    /// Combines photo content, exact time, scan mode, user selections and a
    /// monotonic counter — so even an identical photo re-scanned seconds
    /// later produces a fresh reading.
    static func make(photo: UIImage?, mode: ScanMode, intentions: [String]) -> Int {
        var hash: UInt64 = 0x9E3779B97F4A7C15

        func mix(_ value: UInt64) {
            hash ^= value &+ 0x9E3779B97F4A7C15 &+ (hash << 6) &+ (hash >> 2)
        }

        if let photo { mix(fingerprint(of: photo)) }
        mix(UInt64(Date.now.timeIntervalSince1970 * 1000))
        mix(UInt64(bitPattern: Int64(mode.rawValue.hashValue)))
        mix(UInt64(bitPattern: Int64(intentions.joined().hashValue)))

        // Monotonic scan counter — guarantees difference even if all else ties.
        let counterKey = "auraEngine.scanCounter"
        let counter = UserDefaults.standard.integer(forKey: counterKey) + 1
        UserDefaults.standard.set(counter, forKey: counterKey)
        mix(UInt64(counter))

        return Int(bitPattern: UInt(truncatingIfNeeded: hash))
    }
}

// MARK: - Engine

struct AuraEngine: AuraInterpreting {

    var memory: ReadingMemory = .shared

    func makeReading(
        mode: ScanMode,
        photo: UIImage?,
        intentions: [String],
        history: [AuraReading],
        recentMoods: [String]
    ) -> DraftReading {
        var rng = SeededGenerator(seed: ScanSeed.make(photo: photo, mode: mode, intentions: intentions))

        // — Colours —
        let recentDominants = history.prefix(3).map(\.dominant)
        var pool = AuraHue.allCases.filter { !recentDominants.prefix(2).contains($0) && $0 != .rainbow }
        if pool.isEmpty { pool = AuraHue.allCases.filter { $0 != .rainbow } }

        // Rainbow stays rare & celebratory (~4%).
        let dominant: AuraHue = Double.random(in: 0...1, using: &rng) < 0.04
            ? .rainbow
            : pool.randomElement(using: &rng) ?? .violet

        var others = AuraHue.allCases.filter { $0 != dominant && $0 != .rainbow }
        others.shuffle(using: &rng)
        let secondary = others[0]
        let tertiary = others[1]

        let d = Double.random(in: 0.58...0.78, using: &rng)
        let s = Double.random(in: 0.12...0.28, using: &rng)
        let t = max(0.06, 1 - d - s)
        let total = d + s + t

        // — Context for personalization —
        let context = ReadingContext(
            mode: mode,
            dominant: dominant,
            secondary: secondary,
            intentions: intentions,
            streak: StreakService.currentStreak(readingDates: history.map(\.date)),
            isFirstReading: history.isEmpty,
            previousDominant: history.first?.dominant,
            recentMoods: recentMoods,
            timeOfDay: TimeOfDay.current,
            isWeekend: Calendar.current.isDateInWeekend(.now)
        )

        return DraftReading(
            mode: mode,
            dominant: dominant,
            secondary: secondary,
            tertiary: tertiary,
            dominantFraction: d / total,
            secondaryFraction: s / total,
            tertiaryFraction: t / total,
            essence: dominant.essence,
            interpretation: composeInterpretation(context: context, rng: &rng),
            intuition: Double.random(in: 0.4...0.95, using: &rng),
            calm: Double.random(in: 0.35...0.9, using: &rng),
            vitality: Double.random(in: 0.35...0.9, using: &rng),
            suggestedPractice: suggestPractice(for: dominant, timeOfDay: context.timeOfDay, rng: &rng)
        )
    }

    // MARK: Slot composition with anti-repetition re-roll

    private func composeInterpretation(context: ReadingContext, rng: inout SeededGenerator) -> String {
        guard context.mode == .selfAura else {
            return composeNonSelf(context: context, rng: &rng)
        }

        let observations = Pools.observations[context.dominant] ?? []
        let imagery = Pools.imagery[context.dominant] ?? []
        let qualities = Pools.qualities[context.secondary] ?? []
        let guidance = Pools.guidance(for: context)
        let closers = Pools.closers(for: context)

        // Re-roll up to 12 times to find a combination unseen in ~3 weeks.
        var chosen: (Int, Int, Int, Int, Int, Int) = (0, 0, 0, 0, 0, 0)
        var signature = ""
        for attempt in 0..<12 {
            let pick = (
                Int.random(in: 0..<max(1, observations.count), using: &rng),
                Int.random(in: 0..<max(1, imagery.count), using: &rng),
                Int.random(in: 0..<max(1, Pools.bridges.count), using: &rng),
                Int.random(in: 0..<max(1, qualities.count), using: &rng),
                Int.random(in: 0..<max(1, guidance.count), using: &rng),
                Int.random(in: 0..<max(1, closers.count), using: &rng)
            )
            signature = "self|\(context.dominant.rawValue)|\(context.secondary.rawValue)|\(pick.0).\(pick.1).\(pick.2).\(pick.3).\(pick.4).\(pick.5)"
            chosen = pick
            if !memory.contains(signature) || attempt == 11 { break }
        }
        memory.remember(signature)

        let bridge = Pools.bridges[safe: chosen.2, default: ""]
            .replacingOccurrences(of: "{colour}", with: context.secondary.displayName.lowercased())
            .replacingOccurrences(of: "{quality}", with: qualities[safe: chosen.3, default: "quiet steadiness"])

        return [
            observations[safe: chosen.0, default: context.dominant.meaning],
            imagery[safe: chosen.1, default: ""],
            bridge,
            guidance[safe: chosen.4, default: ""],
            closers[safe: chosen.5, default: ""],
        ]
        .filter { !$0.isEmpty }
        .joined(separator: " ")
    }

    private func composeNonSelf(context: ReadingContext, rng: inout SeededGenerator) -> String {
        let subject = Pools.subject(for: context.mode)
        let qualities = Pools.qualities[context.dominant] ?? ["quiet steadiness"]

        var chosen = (0, 0, 0)
        var signature = ""
        for attempt in 0..<8 {
            let pick = (
                Int.random(in: 0..<Pools.nonSelfTemplates.count, using: &rng),
                Int.random(in: 0..<max(1, qualities.count), using: &rng),
                Int.random(in: 0..<Pools.nonSelfClosers.count, using: &rng)
            )
            signature = "\(context.mode.rawValue)|\(context.dominant.rawValue)|\(pick.0).\(pick.1).\(pick.2)"
            chosen = pick
            if !memory.contains(signature) || attempt == 7 { break }
        }
        memory.remember(signature)

        let opener = Pools.nonSelfTemplates[chosen.0]
            .replacingOccurrences(of: "{subject}", with: subject)
            .replacingOccurrences(of: "{colour}", with: context.dominant.displayName.lowercased())
            .replacingOccurrences(of: "{quality}", with: qualities[safe: chosen.1, default: "quiet steadiness"])

        return opener + " " + Pools.nonSelfClosers[chosen.2]
    }

    private func suggestPractice(for hue: AuraHue, timeOfDay: TimeOfDay, rng: inout SeededGenerator) -> String {
        let matches = Meditation.library.filter { $0.hue == hue }
        if let match = matches.randomElement(using: &rng) { return match.id }
        // Evening leans restful, morning leans bright.
        let fallback = timeOfDay == .evening || timeOfDay == .night ? "goldenHour" : "morningLight"
        return Meditation.library.first { $0.id == fallback }?.id
            ?? Meditation.library.randomElement(using: &rng)?.id
            ?? "heartOpening"
    }
}

// MARK: - Reading context

enum TimeOfDay {
    case morning, afternoon, evening, night

    static var current: TimeOfDay {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: .morning
        case 12..<17: .afternoon
        case 17..<22: .evening
        default: .night
        }
    }
}

struct ReadingContext {
    let mode: ScanMode
    let dominant: AuraHue
    let secondary: AuraHue
    let intentions: [String]
    let streak: Int
    let isFirstReading: Bool
    let previousDominant: AuraHue?
    let recentMoods: [String]
    let timeOfDay: TimeOfDay
    let isWeekend: Bool

    /// "😌 Calm" → "calm"
    var moodWords: [String] {
        recentMoods.compactMap { $0.split(separator: " ").last.map { String($0).lowercased() } }
    }
}

// MARK: - Content pools (hand-written; editorial control = premium tone)

enum Pools {

    // 1 · OBSERVATION — what your field shows right now (5 per colour)
    static let observations: [AuraHue: [String]] = [
        .violet: [
            "Your field glows a deep violet today — intuition is close to the surface.",
            "Violet gathers around you like early dusk; your inner voice is unusually clear.",
            "Today your energy turns inward, wearing violet — the colour of quiet knowing.",
            "A violet stillness holds your field, the kind that arrives before insight.",
            "Your aura reads violet — reflective, perceptive, tuned to what's beneath the day.",
        ],
        .purple: [
            "Your field swirls purple today — two currents of intuition folding into one.",
            "Purple moves through your aura like slow smoke; mystery suits you today.",
            "Today your energy carries purple — awareness reaching a little higher than usual.",
            "A purple depth sits in your field, patient and perceptive.",
            "Your aura leans purple — the dreamer and the knower sharing one light.",
        ],
        .blue: [
            "Your field settles into blue today — calm, clear, and easy to trust.",
            "Blue holds your aura like still water; words will come gently and land well.",
            "Today your energy runs blue — peaceful on the surface, honest underneath.",
            "A cool blue clarity carries your field; conversation is your gift today.",
            "Your aura reads blue — the colour of a mind that has stopped arguing with itself.",
        ],
        .green: [
            "Your field breathes green today — the heart at rest, open and unforced.",
            "Green moves through your aura in slow waves; you're giving from a full cup.",
            "Today your energy is green — growing quietly, in no hurry to prove it.",
            "A soft green warmth surrounds you; connection comes easily today.",
            "Your aura reads green — balanced, generous, rooted in the present.",
        ],
        .gold: [
            "Your field shimmers gold today — abundance is moving through you.",
            "Gold light sweeps your aura; what you touch today tends to brighten.",
            "Today your energy carries gold — warm, wise, quietly radiant.",
            "A golden sheen rests on your field, the glow of effort finally settling.",
            "Your aura reads gold — high vibration held with a steady hand.",
        ],
        .red: [
            "Your field pulses red today — vitality with somewhere to go.",
            "Red warmth radiates through your aura; your body wants to move.",
            "Today your energy runs red — grounded fire, drive without panic.",
            "A strong red current carries your field; passion is close at hand.",
            "Your aura reads red — alive, direct, ready for the meaningful thing.",
        ],
        .pink: [
            "Your field blooms pink today — tenderness leading the way.",
            "Pink softness gathers in your aura; compassion comes before judgement today.",
            "Today your energy is pink — a gentle warmth that starts with yourself.",
            "A rose-pink glow holds your field, patient with everything it meets.",
            "Your aura reads pink — the heart speaking in its first language.",
        ],
        .white: [
            "Your field is luminous white today — clear, open, and receptive.",
            "White light breathes through your aura; nothing needs to be added today.",
            "Today your energy runs white — a clean page, spiritually wide awake.",
            "A pure white stillness carries your field; clarity is your companion.",
            "Your aura reads white — openness so complete it feels like rest.",
        ],
        .indigo: [
            "Your field deepens to indigo today — the visionary in you is awake.",
            "Indigo settles over your aura like a starred sky; dream on paper today.",
            "Today your energy carries indigo — intuition with a long horizon.",
            "A cosmic indigo drift holds your field, slow and certain.",
            "Your aura reads indigo — seeing further than the day requires.",
        ],
        .silver: [
            "Your field gleams silver today — refined insight, cool and precise.",
            "Silver light glides around your aura; you see through the noise today.",
            "Today your energy runs silver — protected, reflective, quietly sharp.",
            "A moonlit silver sheen carries your field; trust the subtle read.",
            "Your aura reads silver — intuition polished to a mirror.",
        ],
        .rainbow: [
            "Your field carries the full spectrum today — a rare, celebratory reading.",
            "Every colour moves through your aura at once; life feels wide open.",
            "Today your energy is a prism — joy refracting in all directions.",
            "The whole rainbow turns gently in your field; let yourself enjoy it.",
            "Your aura reads rainbow — possibility wearing all its colours at once.",
        ],
    ]

    // 2 · AURA IMAGERY — the mystical visual (5 per colour)
    static let imagery: [AuraHue: [String]] = [
        .violet: [
            "It moves like candlelight behind silk, slow and certain.",
            "The light pools at your crown, then drifts down like a settling veil.",
            "It has the depth of a sky ten minutes after sunset.",
            "Fine threads of lavender light circle you, unhurried.",
            "It glows the way amethyst holds a lamp — from somewhere inside.",
        ],
        .purple: [
            "Two nebulae turn slowly around each other at your centre.",
            "The light folds and unfolds like a night-blooming flower.",
            "It drifts in spirals, each one a thought completing itself.",
            "Deep plum and soft lilac trade places in a slow orbit.",
            "It shimmers like the far edge of a dream you almost remember.",
        ],
        .blue: [
            "Ripples widen from your heart like rings on still water.",
            "The light lies smooth as a lake at first light.",
            "It laps gently at the edges of your silhouette, tide-patient.",
            "Cool bands of cerulean breathe in and out with you.",
            "It has the hush of deep water — calm all the way down.",
        ],
        .green: [
            "The light unfurls like new leaves opening to morning.",
            "A soft emerald halo pulses at the pace of a resting heart.",
            "It grows outward in gentle rings, the way moss claims a stone.",
            "Spring-green light gathers warmest at your chest.",
            "It breathes like a forest after rain — clean, alive, unhurried.",
        ],
        .gold: [
            "A slow shimmer sweeps the field, like sun crossing a wheat field.",
            "The light drips warm and honeyed from your shoulders.",
            "Tiny sparks of amber rise and settle like dust in a sunbeam.",
            "It gleams the way late afternoon gilds ordinary things.",
            "A soft halo of goldlight blooms and dims, blooms and dims.",
        ],
        .red: [
            "The light beats outward in warm pulses, ember-steady.",
            "It glows like coals that have outlasted the flame.",
            "Heat-shimmers of scarlet rise from your base like a hearth.",
            "The field flickers with a dancer's rhythm — grounded, alive.",
            "It radiates the confident warmth of a fire that knows its size.",
        ],
        .pink: [
            "The light opens and closes like a rose deciding on morning.",
            "A blush-coloured softness drapes your shoulders like a shawl.",
            "It pulses tenderly, the way a held hand answers a held hand.",
            "Petal-light drifts around you, weightless and kind.",
            "It glows like dawn through a paper lantern.",
        ],
        .white: [
            "The light breathes in one clean bloom, out one clean bloom.",
            "It surrounds you like first snow — quiet, complete, unmarked.",
            "A pearl luminescence rises from your centre without effort.",
            "The field shines the way a morning window shines — simply.",
            "It holds you in a single, seamless halo of clear light.",
        ],
        .indigo: [
            "Star-flecks drift through a deep blue field, patient as night.",
            "The light moves like slow weather on a far planet.",
            "A midnight current circles you, carrying small silver sparks.",
            "It deepens toward the edges, the way night deepens away from a fire.",
            "The field turns with the gravity of a quiet galaxy.",
        ],
        .silver: [
            "A cool sheen travels the field like moonlight on water.",
            "The light bends around you like polished mirror-mist.",
            "Fine metallic threads glide through the field, precise and calm.",
            "It gleams softly, the way frost gleams before the sun.",
            "A mercury shimmer traces your outline, exact and unhurried.",
        ],
        .rainbow: [
            "Every band of colour takes a slow turn at your crown.",
            "The field refracts like light through rain that has decided to be beautiful.",
            "Colours chase each other gently around you, none needing to win.",
            "It turns like a prism in a patient hand.",
            "The whole spectrum breathes with you, in joyful rotation.",
        ],
    ]

    // 3 · ENERGY BRIDGE — secondary-colour qualities (3 per colour)
    static let qualities: [AuraHue: [String]] = [
        .violet: ["quiet intuition", "an inward-listening depth", "a soft certainty about unseen things"],
        .purple: ["mystery held gently", "a higher kind of noticing", "dream-logic wisdom"],
        .blue: ["easy calm", "honest, unhurried words", "trust that doesn't need proving"],
        .green: ["heart-steadiness", "a healer's patience", "growth that asks for nothing"],
        .gold: ["warm abundance", "earned wisdom", "a generous inner brightness"],
        .red: ["grounded vitality", "willing courage", "warmth with momentum"],
        .pink: ["unguarded tenderness", "compassion without conditions", "a soft first-yes to the world"],
        .white: ["clean clarity", "open receptivity", "a beginner's spaciousness"],
        .indigo: ["far-seeing depth", "night-sky patience", "visionary quiet"],
        .silver: ["protective insight", "a cool, precise knowing", "reflective composure"],
        .rainbow: ["playful possibility", "many-coloured joy", "celebration without occasion"],
    ]

    // Bridge sentence templates ({colour}, {quality} filled at runtime)
    static let bridges: [String] = [
        "Beneath it runs a thread of {colour}, lending {quality}.",
        "A quieter current of {colour} moves underneath, adding {quality} to the whole.",
        "Woven through is a softer {colour}, bringing {quality} to steady the field.",
        "At the edges, {colour} keeps watch, offering {quality} whenever you reach for it.",
        "Underneath, {colour} hums low, and with it comes {quality}.",
        "The {colour} beneath the surface is subtle, but its gift — {quality} — is not.",
    ]

    // 4 · GUIDANCE — personalized by intention, time of day, mood
    static func guidance(for context: ReadingContext) -> [String] {
        var pool: [String] = [
            "Move gently today; this energy rewards patience over push.",
            "Choose one small ritual and let it anchor the whole day.",
            "Say yes slowly today — your field favours the considered answer.",
            "Give ten unhurried minutes to something you love; it will repay the hour.",
            "Let today be shaped by what feels true, not what feels urgent.",
            "Keep one pocket of silence in the day and visit it often.",
            "Water what's already growing rather than planting something new.",
            "Trade one scroll for one long look out the window.",
        ]

        // Time of day
        switch context.timeOfDay {
        case .morning:
            pool += [
                "Set the day's tone in the next hour — this morning energy is impressionable.",
                "Carry this first-light clarity into your first conversation.",
                "Before the day speaks, decide one thing it will not take from you.",
            ]
        case .afternoon:
            pool += [
                "Midday is asking for a reset breath — three slow ones, shoulders down.",
                "The afternoon will scatter if you let it; hold one thread and follow it.",
                "Step outside once before evening; your field wants sky.",
            ]
        case .evening:
            pool += [
                "Let the evening be a landing, not a second day.",
                "Put the day down piece by piece; it doesn't all need carrying to bed.",
                "Tonight favours warm light, slow food, and one honest page in your journal.",
            ]
        case .night:
            pool += [
                "The late hours are for softening, not solving. Let the questions wait.",
                "Night readings run deep — write down what surfaces and sleep on it.",
                "Give your mind permission to close its tabs; tomorrow will hold.",
            ]
        }

        // Intentions (from onboarding chips)
        let intentionLines: [String: String] = [
            "Calm": "Your intention of calm is well met today — protect one quiet hour and it will spread.",
            "Clarity": "You asked for clarity, and this field carries it — write the decision down and it will finish itself.",
            "Growth": "Your intention of growth is quietly at work; notice what you handle better than last month.",
            "Balance": "You set balance as your intention — today, let rest count as progress.",
            "Energy": "Your intention of energy is answered today; spend it on the meaningful thing first.",
            "Love": "You asked for love — begin with the tenderness you'd offer a dear friend, aimed inward.",
        ]
        for intention in context.intentions {
            if let line = intentionLines[intention] { pool.append(line) }
        }

        // Journal mood echo
        if let mood = context.moodWords.first {
            pool.append("Your journal held a \(mood) note recently — today's field seems to answer it gently.")
        }

        if context.isWeekend {
            pool.append("It's a slower day by design — let your energy match the calendar for once.")
        }

        return pool
    }

    // 5 · CLOSING AFFIRMATION — personalized by streak & history
    static func closers(for context: ReadingContext) -> [String] {
        var pool: [String] = [
            "You are allowed to move at the speed of your own energy.",
            "Return to your breath whenever the day speeds up; it remembers the way.",
            "What you carry is enough, and so are you.",
            "Insight is close — stay soft and it will come to you.",
            "The quiet hours know things the busy hours don't; trust what they told you.",
            "Small rituals, faithfully kept, are how a life changes colour.",
            "Let this reading be a mirror, not a measure.",
            "Your light doesn't need to be brighter today — only truer.",
            "Tend the flame; you don't have to be the fire all day.",
            "Whatever today asks, answer it from this settled place.",
        ]

        if context.isFirstReading {
            pool += [
                "Welcome to your practice — this first colour is the beginning of a long, beautiful record.",
                "A first reading is a doorway; step through gently and come back tomorrow.",
            ]
        }
        if context.streak >= 30 {
            pool.append("Thirty days of practice glows through this reading — the pattern is fully yours now.")
        } else if context.streak >= 7 {
            pool.append("Your \(context.streak)-day practice is compounding; readings deepen when they're kept like this.")
        }
        if let previous = context.previousDominant, previous == context.dominant {
            pool.append("\(context.dominant.displayName) stays with you — some seasons ask to be lived twice, and that's a kind of faithfulness.")
        }

        return pool
    }

    // Non-self scans
    static func subject(for mode: ScanMode) -> String {
        switch mode {
        case .pet: "Your companion's field"
        case .plant: "This plant's energy"
        case .home: "Your home's field"
        case .room: "This room's energy"
        case .object: "This object's presence"
        case .food: "This meal's energy"
        case .relationship: "The space between you two"
        case .selfAura: "Your field"
        }
    }

    static let nonSelfTemplates: [String] = [
        "{subject} glows {colour} today, carrying {quality} into the space around it.",
        "{subject} reads {colour} — {quality} colouring every moment shared with it.",
        "{subject} holds a {colour} tone right now; {quality} is what it offers you.",
        "A {colour} light rests on this moment — {quality} settles wherever it does.",
    ]

    static let nonSelfClosers: [String] = [
        "Notice how it changes the room, and let it.",
        "Energy shared is energy doubled — enjoy what it gives back.",
        "A small moment of attention here will brighten both of you.",
        "Let it remind you that everything you keep close keeps you, too.",
    ]
}

// MARK: - Safe indexing

private extension Array {
    subscript(safe index: Int, default fallback: Element) -> Element {
        indices.contains(index) ? self[index] : fallback
    }
}

// MARK: - Daily insight (unchanged surface for Home)

enum DailyInsight {
    private static let insights = [
        "Stillness is not empty — it's where your clarity gathers. Give yourself five quiet minutes.",
        "The energy you protect in the morning is the energy you carry all day.",
        "You don't need to be lighter today. You only need to be honest.",
        "What you water grows. Choose one thought worth watering.",
        "Rest is not the absence of progress — it's where progress settles in.",
        "Let your breath be the slowest thing about you today.",
        "Your calm is contagious. Share it on purpose.",
        "A gentle no today protects a hundred better yeses.",
        "Notice what made you feel most alive yesterday. Do a little more of it.",
        "The quiet hours know things the busy hours don't.",
        "You are allowed to move at the speed of your own energy.",
        "One kind sentence — to yourself — can retune the whole day.",
        "Today, trade one scroll for one long look out the window.",
        "Energy follows attention. Aim yours somewhere beautiful.",
    ]

    static var today: String {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        return insights[day % insights.count]
    }
}

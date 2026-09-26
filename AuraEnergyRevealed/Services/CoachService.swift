//
//  CoachService.swift
//  Orenda
//
//  The Aura Coach brain.
//
//  Design goals:
//   1. When the cloud model is reachable, replies are genuinely conversational.
//   2. When it is NOT reachable — no credit, rate limited, offline, slow, bad key —
//      the app must degrade *invisibly*. The person never sees an error, a spinner
//      that never ends, or an empty bubble. `CoachService` never throws.
//   3. No API key ever lives in this binary. The app talks to a relay we control;
//      the key stays server-side. See CoachRelay.swift for the deployment notes.
//
//  Safety: this is a reflective wellness companion, never a medical or crisis
//  service. Concerning messages are always handled locally (so the guidance is
//  identical online and offline) and point toward real human support.
//

import Foundation

// MARK: - Conversation primitives

struct CoachTurn: Sendable, Equatable {
    let text: String
    let isUser: Bool
}

/// Everything the coach is allowed to know about the person, assembled by the view.
struct CoachContext: Sendable {
    var userName: String = ""
    var todaysAura: AuraHue?
    var recentAuras: [AuraHue] = []
    var intentions: [String] = []
    var recentMoods: [String] = []
    var streakDays: Int = 0
    var journalSnippet: String?

    static let empty = CoachContext()
}

protocol CoachProviding: Sendable {
    func reply(to message: String, history: [CoachTurn], context: CoachContext) async throws -> String
}

// MARK: - Crisis handling (always local, always first)

enum CoachSafety {

    private static let concerning: [String] = [
        "kill myself", "killing myself", "end my life", "ending my life", "want to die",
        "wanna die", "suicide", "suicidal", "self harm", "self-harm", "hurt myself",
        "hurting myself", "cut myself", "cutting myself", "no reason to live",
        "better off dead", "don't want to be here", "dont want to be here",
        "end it all", "take my own life"
    ]

    /// True when a message needs a careful, human-pointing response rather than a practice suggestion.
    static func needsSupportResponse(_ message: String) -> Bool {
        let lower = message.lowercased()
        return concerning.contains { lower.contains($0) }
    }

    static let supportResponse = """
        Thank you for telling me — that took courage, and I'm glad you said it out loud.

        What you're carrying sounds heavier than anything a breathing practice should be asked to hold, and I'd be doing you a disservice by offering one right now. Please talk to someone who can be properly present with you: a crisis line in your country, a doctor, or someone close to you who you trust.

        If you're in immediate danger, please contact your local emergency number.

        I'll still be here afterwards, whenever you want somewhere quiet to land.
        """
}

// MARK: - On-device coach

/// A considered, varied rule-based companion. This is the safety net, so it is
/// written to stand on its own rather than feel like a placeholder.
struct LocalCoachEngine: CoachProviding {

    private enum Topic {
        case anxious, tired, low, bright, angry, sleepless, unfocused,
             lonely, overwhelmed, grateful, stuck, selfCritical, relationship, greeting, unknown
    }

    private static func topic(for message: String) -> Topic {
        let m = message.lowercased()
        func has(_ words: [String]) -> Bool { words.contains { m.contains($0) } }

        if has(["anxious", "anxiety", "panic", "nervous", "worried", "worry", "on edge", "scatter", "racing"]) { return .anxious }
        if has(["exhausted", "tired", "drained", "no energy", "burnt out", "burned out", "wiped"]) { return .tired }
        if has(["sad", "down", "low", "blue", "crying", "cry", "grief", "heartbroken", "miss "]) { return .low }
        if has(["angry", "furious", "annoyed", "irritated", "frustrated", "rage", "resent"]) { return .angry }
        if has(["can't sleep", "cant sleep", "insomnia", "awake at", "sleepless", "restless night"]) { return .sleepless }
        if has(["focus", "distracted", "procrast", "concentrate", "scattered", "brain fog"]) { return .unfocused }
        if has(["lonely", "alone", "isolated", "no one", "nobody"]) { return .lonely }
        if has(["overwhelm", "too much", "drowning", "can't cope", "cant cope", "pressure", "swamped"]) { return .overwhelmed }
        if has(["grateful", "thankful", "gratitude", "blessed", "appreciate"]) { return .grateful }
        if has(["stuck", "lost", "directionless", "don't know what", "dont know what", "confused"]) { return .stuck }
        if has(["hate myself", "not good enough", "failure", "useless", "worthless", "stupid", "ashamed"]) { return .selfCritical }
        if has(["partner", "boyfriend", "girlfriend", "husband", "wife", "friend", "family", "mother", "father", "argument", "fight with"]) { return .relationship }
        if has(["happy", "good", "great", "wonderful", "amazing", "joy", "excited", "calm today"]) { return .bright }
        if has(["hi", "hello", "hey", "good morning", "good evening"]), m.count < 24 { return .greeting }
        return .unknown
    }

    private static let responses: [Topic: [String]] = [
        .anxious: [
            "Anxiety usually means some part of you is trying very hard to keep you safe. Let's slow the signal down: breathe in for four, hold for seven, out for eight — three rounds. I'll wait.",
            "When the mind races, the body is often the faster way in. Put both feet flat on the floor and name five things you can see. Then tell me what shifted, even slightly.",
            "Let's not try to argue with the worry — that rarely works. Instead, give it a shape: what's the sentence it keeps repeating? Sometimes writing it down takes the teeth out of it."
        ],
        .tired: [
            "Rest is a practice too, not a reward you have to earn. Would a short body scan help you set the day down gently?",
            "There's tired-from-doing and tired-from-carrying, and they need different things. Which one feels closer today?",
            "If you only had ten honest minutes to restore something, would you spend them on quiet, on movement, or on being with someone? Start there."
        ],
        .low: [
            "Thank you for telling me. Low days are part of a whole life, not a failure of one. Is this a day for gentleness, or for a small bit of movement?",
            "You don't have to talk yourself out of feeling this. Let it be here for a moment — then maybe a slow walk, or the Heart Opening practice, as a soft next step.",
            "Sadness tends to ask for company rather than solutions. Is there someone you could sit near today, even without explaining much?"
        ],
        .bright: [
            "Beautiful. Take ten slow seconds to really feel that — naming a good moment is what helps it stay.",
            "I love hearing that. What made the difference today? Knowing the ingredient makes it easier to find again.",
            "Good energy is worth marking. Want to write one line in your journal so future-you can read it on a harder day?"
        ],
        .angry: [
            "Anger usually stands guard over something that matters — a boundary, a value, a hurt. What do you think it's protecting?",
            "Let's give it somewhere to go before it goes somewhere unhelpful: a brisk walk, or writing the unsent version of what you'd say. Which is more your speed?",
            "You're allowed to be angry. The question is only what you want to do with the heat — point it at the problem rather than at yourself."
        ],
        .sleepless: [
            "The night mind exaggerates; almost nothing is as certain at 3am as it claims to be. Try a long, slow exhale — out for twice as long as in.",
            "If sleep won't come, stop chasing it and give the body rest instead: lie still, eyes closed, no pressure to sleep. Rest counts too.",
            "Is it a racing mind or a restless body keeping you up? They need different remedies, so it's worth knowing which."
        ],
        .unfocused: [
            "Scattered attention is often a tired mind, not a weak one. Pick the smallest possible next action — one you could finish in two minutes — and do only that.",
            "Try this: set a timer for ten minutes and allow yourself to do the task badly. Starting is the part that's actually hard.",
            "What's the one thing that, if it got done today, would make the rest feel lighter? Everything else can wait."
        ],
        .lonely: [
            "Loneliness is painful and also very common — it says nothing bad about you. Is there one person you could send a small, low-stakes message to today?",
            "Being alone and feeling lonely aren't the same. Which one is it right now?",
            "Connection doesn't have to be a big conversation. Sometimes it's a shared room, a walk, or a familiar voice. What's available to you today?"
        ],
        .overwhelmed: [
            "When everything feels urgent, nothing gets your full attention. Let's shrink the frame: what only needs to happen in the next hour?",
            "Try writing the whole list down, then crossing out anything that isn't actually yours to carry. There's usually more than you'd think.",
            "Overwhelm eases when things become specific. Name the three pieces out loud, and we'll look at just the first."
        ],
        .grateful: [
            "Gratitude is worth slowing down for. What's one detail of it you could describe — the small, specific part rather than the headline?",
            "That's lovely. Noticing it is already the practice; writing it down makes it last longer.",
            "Hold that for a few breaths before moving on. Good moments deserve the same attention we give the hard ones."
        ],
        .stuck: [
            "Being stuck often means two things you care about are pulling against each other. What are the two?",
            "You don't need the whole path — just the next honest step. What's one small thing you could try this week and learn from?",
            "If a friend described this exact situation to you, what would you gently tell them?"
        ],
        .selfCritical: [
            "That's a harsh voice to live with. Would you say it in those words to someone you love? If not, it may not be the truest thing available.",
            "Being disappointed in something you did is different from deciding who you are. Which one is actually going on?",
            "Let's not argue with it — just add one true, kinder sentence beside it. What would that sentence be?"
        ],
        .relationship: [
            "Relationships tend to hold our biggest feelings. What did you most want the other person to understand?",
            "It might help to separate what happened from the story about what it meant. What actually happened?",
            "What would a good outcome look like here — not a perfect one, just one you could live with?"
        ],
        .greeting: [
            "Hello. How is your energy sitting right now — heavy, light, restless, somewhere else?",
            "Good to see you. What's the weather like inside today?",
            "Hi. Tell me where you are today and we'll find something small to match it."
        ]
    ]

    func reply(to message: String, history: [CoachTurn], context: CoachContext) async throws -> String {
        if CoachSafety.needsSupportResponse(message) { return CoachSafety.supportResponse }

        let topic = Self.topic(for: message)

        // Vary by how far into the conversation we are, so repeats are rare.
        let spin = max(0, history.count)

        if let bank = Self.responses[topic], !bank.isEmpty {
            var line = bank[spin % bank.count]
            if let tail = contextualTail(for: topic, context: context, spin: spin) {
                line += "\n\n" + tail
            }
            return line
        }

        return openEnded(context: context, spin: spin)
    }

    /// A short second paragraph that ties the reply to the person's own data.
    private func contextualTail(for topic: Topic, context: CoachContext, spin: Int) -> String? {
        switch spin % 3 {
        case 0:
            if let aura = context.todaysAura {
                return "Your \(aura.displayName.lowercased()) reading today leans toward \(aura.essence.lowercased()) — worth keeping in mind."
            }
        case 1:
            if let intention = context.intentions.first {
                return "You set an intention around \(intention.lowercased()). Does today connect to that at all?"
            }
        default:
            if context.streakDays >= 3 {
                return "You've checked in \(context.streakDays) days running — that consistency is doing quiet work."
            }
        }
        return nil
    }

    private func openEnded(context: CoachContext, spin: Int) -> String {
        var options = [
            "Tell me a little more — what does it feel like in your body when you think about it?",
            "I'm listening. What part of this is weighing the most right now?",
            "Say more if you'd like. What would 'a bit better' actually look like today?"
        ]
        if let aura = context.todaysAura {
            options.append("Your \(aura.displayName.lowercased()) reading suggests \(aura.essence.lowercased()). Want a short practice matched to that?")
        }
        if let intention = context.intentions.first {
            options.append("You set an intention of \(intention.lowercased()) — how has that been showing up today?")
        }
        return options[spin % options.count]
    }
}

// MARK: - Cloud coach (via our relay; no key in the app)

struct RelayCoachClient: CoachProviding {

    enum RelayError: Error { case notConfigured, badStatus(Int), emptyReply, malformed }

    private let endpoint: URL?
    private let session: URLSession

    init(endpoint: URL? = CoachRelay.endpoint) {
        self.endpoint = endpoint
        let config = URLSessionConfiguration.ephemeral
        // Keep these tight: a slow relay must never hold the UI hostage.
        config.timeoutIntervalForRequest = CoachRelay.timeout
        config.timeoutIntervalForResource = CoachRelay.timeout
        config.waitsForConnectivity = false
        self.session = URLSession(configuration: config)
    }

    func reply(to message: String, history: [CoachTurn], context: CoachContext) async throws -> String {
        guard let endpoint else { throw RelayError.notConfigured }

        // Only the last few turns travel — cheaper, and less to expose.
        let trimmed = history.suffix(8).map { ["role": $0.isUser ? "user" : "assistant", "content": $0.text] }

        let payload: [String: Any] = [
            "system": Self.systemPrompt(context: context),
            "messages": trimmed + [["role": "user", "content": message]]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw RelayError.malformed }
        // 402/429/5xx all land here and are treated as "fall back quietly".
        guard (200...299).contains(http.statusCode) else { throw RelayError.badStatus(http.statusCode) }

        guard
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let reply = object["reply"] as? String
        else { throw RelayError.malformed }

        let cleaned = reply.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw RelayError.emptyReply }
        return cleaned
    }

    private static func systemPrompt(context: CoachContext) -> String {
        var lines: [String] = [
            "You are the Aura Coach inside Orenda, a reflective wellness app.",
            "Voice: warm, grounded, unhurried. Speak like a thoughtful friend, not a therapist or a guru.",
            "Keep replies to 2–4 short sentences. Usually end with one gentle, open question.",
            "You may reference the person's aura readings as symbolic prompts for reflection — never as measurements, diagnoses, or predictions.",
            "Never give medical, psychiatric, legal, or financial advice. Never diagnose.",
            "If someone describes self-harm, suicide, or abuse, do not coach: gently encourage them to reach out to a crisis line, a doctor, or someone they trust.",
            "Avoid clichés, emoji spam, and exclamation marks. No markdown headings or bullet lists."
        ]
        // Deliberately NOT sent: the person's name, or anything else that could
        // identify them. Nothing leaving the device is tied to who they are,
        // which keeps the App Privacy declaration to "not linked to you".
        if let aura = context.todaysAura {
            lines.append("Today's reading: \(aura.displayName) — \(aura.essence).")
        }
        if !context.recentAuras.isEmpty {
            lines.append("Recent readings: \(context.recentAuras.map(\.displayName).joined(separator: ", ")).")
        }
        if !context.intentions.isEmpty {
            lines.append("Their stated intentions: \(context.intentions.joined(separator: ", ")).")
        }
        if !context.recentMoods.isEmpty {
            lines.append("Recently logged moods: \(context.recentMoods.joined(separator: ", ")).")
        }
        if context.streakDays > 0 {
            lines.append("They have checked in \(context.streakDays) day(s) in a row.")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - The façade the UI talks to

/// Tries the cloud coach, falls back to the on-device coach on *any* problem.
/// This type deliberately has no throwing surface: the UI can always render a reply.
struct CoachService: Sendable {

    private let remote: CoachProviding?
    private let local: CoachProviding

    init(remote: CoachProviding? = RelayCoachClient(), local: CoachProviding = LocalCoachEngine()) {
        self.remote = remote
        self.local = local
    }

    /// Always returns something sensible. Never throws, never returns empty.
    func reply(to message: String, history: [CoachTurn], context: CoachContext) async -> String {

        // Sensitive messages are answered identically online and offline.
        if CoachSafety.needsSupportResponse(message) {
            return CoachSafety.supportResponse
        }

        if CoachRelay.isConfigured, let remote {
            do {
                return try await remote.reply(to: message, history: history, context: context)
            } catch {
                // Quota exhausted, offline, timeout, bad key, malformed — all silent.
                #if DEBUG
                print("[CoachService] relay unavailable, using on-device coach: \(error)")
                #endif
            }
        }

        if let fallback = try? await local.reply(to: message, history: history, context: context),
           !fallback.trimmingCharacters(in: .whitespaces).isEmpty {
            return fallback
        }

        return "I'm here with you. Tell me how your energy feels right now, and we'll find a small practice to match it."
    }
}

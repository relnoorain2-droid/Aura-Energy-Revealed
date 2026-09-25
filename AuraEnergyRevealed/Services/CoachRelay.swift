//
//  CoachRelay.swift
//  Auralis
//
//  Configuration for the Aura Coach relay.
//
//  ─────────────────────────────────────────────────────────────────────────
//  IMPORTANT: no OpenAI key belongs in this file, or anywhere in this app.
//
//  Anything shipped inside an iOS binary can be extracted in minutes, and a
//  leaked key means someone else spends your OpenAI balance. Instead the app
//  calls a tiny relay you own; the key lives there as a secret.
//
//  Deployment steps live in  docs/CoachRelay-Setup.md  in this repo.
//  Once the relay is live, paste its URL into `endpointString` below.
//
//  Leaving `endpointString` empty is safe and intentional: the app simply
//  uses the on-device coach and behaves completely normally.
//  ─────────────────────────────────────────────────────────────────────────
//

import Foundation

enum CoachRelay {

    /// The Cloudflare Worker relay that holds the OpenAI key server-side.
    /// Empty = on-device coach only. Never put a key here.
    static let endpointString = "https://auralis-coach.ksbpstech.workers.dev"

    /// Hard ceiling on how long the UI will wait before using the local coach.
    static let timeout: TimeInterval = 12

    static var endpoint: URL? {
        guard !endpointString.isEmpty else { return nil }
        return URL(string: endpointString)
    }

    static var isConfigured: Bool { endpoint != nil }
}

//
//  CoachQuota.swift
//  Auralis
//
//  How many Aura Coach messages a person may send in the current period.
//
//  Two different "running out" cases exist in this app and they must not be
//  confused:
//
//   • The *developer's* cloud balance runs out  → invisible. CoachService
//     quietly answers on-device; the person notices nothing. (CoachService.swift)
//
//   • The *person's* own allowance runs out     → visible, and handled here.
//     They are offered more conversations as an Apple In-App Purchase.
//
//  All payment happens through StoreKit. The app must never link out to an
//  external payment page for digital content — App Store Review Guideline 3.1.1.
//

import SwiftUI
import Observation

@Observable
final class CoachQuota {

    // MARK: Tuning

    /// Taster for people without Aura+, resets daily.
    static let freeDailyMessages = 3

    /// Included with an Aura+ subscription, resets weekly.
    static let subscriberWeeklyMessages = 150

    /// Conversations granted by one top-up purchase. Do not expire.
    static let messagesPerTopUp = 300

    // MARK: Stored state

    @ObservationIgnored
    @AppStorage("coachMessagesUsed") private var messagesUsedStored: Int = 0

    @ObservationIgnored
    @AppStorage("coachPeriodStart") private var periodStartStored: Double = 0

    @ObservationIgnored
    @AppStorage("coachTopUpCredits") private var topUpCreditsStored: Int = 0

    /// Bumped on every change so `@Observable` views refresh.
    private var revision = 0

    // MARK: Derived

    private func rollPeriodIfNeeded(isSubscribed: Bool) {
        let start = Date(timeIntervalSince1970: periodStartStored)
        let calendar = Calendar.current
        let expired: Bool

        if periodStartStored == 0 {
            expired = true
        } else if isSubscribed {
            expired = !calendar.isDate(start, equalTo: .now, toGranularity: .weekOfYear)
        } else {
            expired = !calendar.isDateInToday(start)
        }

        if expired {
            periodStartStored = Date.now.timeIntervalSince1970
            messagesUsedStored = 0
        }
    }

    func allowance(isSubscribed: Bool) -> Int {
        isSubscribed ? Self.subscriberWeeklyMessages : Self.freeDailyMessages
    }

    func messagesUsed(isSubscribed: Bool) -> Int {
        rollPeriodIfNeeded(isSubscribed: isSubscribed)
        _ = revision
        return messagesUsedStored
    }

    var topUpCredits: Int {
        _ = revision
        return topUpCreditsStored
    }

    func remainingIncluded(isSubscribed: Bool) -> Int {
        max(0, allowance(isSubscribed: isSubscribed) - messagesUsed(isSubscribed: isSubscribed))
    }

    /// Total conversations still available, including purchased top-ups.
    func remainingTotal(isSubscribed: Bool) -> Int {
        remainingIncluded(isSubscribed: isSubscribed) + topUpCredits
    }

    func canSend(isSubscribed: Bool) -> Bool {
        remainingTotal(isSubscribed: isSubscribed) > 0
    }

    /// Spend one message. Included allowance is used before purchased credits.
    func consume(isSubscribed: Bool) {
        rollPeriodIfNeeded(isSubscribed: isSubscribed)
        if messagesUsedStored < allowance(isSubscribed: isSubscribed) {
            messagesUsedStored += 1
        } else if topUpCreditsStored > 0 {
            topUpCreditsStored -= 1
        }
        revision &+= 1
    }

    /// Called after StoreKit confirms a top-up purchase.
    func grantTopUp(packs: Int = 1) {
        topUpCreditsStored += Self.messagesPerTopUp * max(1, packs)
        revision &+= 1
    }

    /// When the period resets, how the UI should describe it.
    func renewalDescription(isSubscribed: Bool) -> String {
        isSubscribed ? "Your included conversations refresh weekly." : "You get \(Self.freeDailyMessages) free conversations a day."
    }
}

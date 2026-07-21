//
//  AppState.swift
//  Aura Energy Revealed
//
//  Global app phase + lightweight user profile state (MVVM: shared app-level model).
//

import SwiftUI
import Observation

enum AppPhase: Equatable {
    case splash
    case welcome
    case onboarding
    case permissions
    case main
}

enum AppTab: String, CaseIterable {
    case home, explore, practice, you

    var title: String {
        switch self {
        case .home: "Home"
        case .explore: "Explore"
        case .practice: "Practice"
        case .you: "You"
        }
    }

    var symbol: String {
        switch self {
        case .home: "sun.max"
        case .explore: "sparkles.rectangle.stack"
        case .practice: "leaf"
        case .you: "person.crop.circle"
        }
    }
}

@Observable
final class AppState {

    // MARK: Persistence-backed flags
    @ObservationIgnored
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboardingStored = false

    @ObservationIgnored
    @AppStorage("userName") var userName: String = ""

    @ObservationIgnored
    @AppStorage("userIntentions") var userIntentionsRaw: String = ""

    @ObservationIgnored
    @AppStorage("freeScansUsed") var freeScansUsed: Int = 0

    // MARK: Session state
    var phase: AppPhase = .splash
    var selectedTab: AppTab = .home
    var isScanFlowPresented = false
    var isPaywallPresented = false

    /// Free tier: exactly one complimentary scan, then Aura+ is required.
    static let freeScanAllowance = 1

    var intentions: [String] {
        get { userIntentionsRaw.isEmpty ? [] : userIntentionsRaw.components(separatedBy: "|") }
        set { userIntentionsRaw = newValue.joined(separator: "|") }
    }

    var hasCompletedOnboarding: Bool {
        get { hasCompletedOnboardingStored }
        set { hasCompletedOnboardingStored = newValue }
    }

    func advanceFromSplash() {
        phase = hasCompletedOnboarding ? .main : .welcome
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        phase = .main
    }

    /// Whether the user may run another scan without Aura+.
    func canScan(isSubscribed: Bool) -> Bool {
        isSubscribed || freeScansUsed < Self.freeScanAllowance
    }

    func consumeFreeScanIfNeeded(isSubscribed: Bool) {
        guard !isSubscribed else { return }
        freeScansUsed += 1
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Welcome back"
        }
    }
}

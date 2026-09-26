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

/// Light is the default. The app was dark-first; it is now paper-first, with
/// dark kept as a deliberate choice rather than the only option.
enum AppAppearance: String, CaseIterable, Identifiable {
    case light, dark, system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .light: "Light"
        case .dark: "Dark"
        case .system: "System"
        }
    }

    var symbol: String {
        switch self {
        case .light: "sun.max"
        case .dark: "moon"
        case .system: "circle.lefthalf.filled"
        }
    }

    /// `nil` hands the decision back to iOS.
    var colorScheme: ColorScheme? {
        switch self {
        case .light: .light
        case .dark: .dark
        case .system: nil
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

    @ObservationIgnored
    @AppStorage("appAppearance") private var appearanceRaw: String = AppAppearance.light.rawValue

    /// Bumped on change so `@Observable` views re-render when appearance flips.
    private var appearanceRevision = 0

    var appearance: AppAppearance {
        get {
            _ = appearanceRevision
            return AppAppearance(rawValue: appearanceRaw) ?? .light
        }
        set {
            appearanceRaw = newValue.rawValue
            appearanceRevision &+= 1
        }
    }

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

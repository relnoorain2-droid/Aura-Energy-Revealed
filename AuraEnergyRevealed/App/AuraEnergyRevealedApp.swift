//
//  AuraEnergyRevealedApp.swift
//  Aura Energy Revealed
//
//  App entry point. Dark-mode-first, MVVM, SwiftData-backed.
//

import SwiftUI
import SwiftData

@main
struct AuraEnergyRevealedApp: App {

    @State private var appState = AppState()
    @State private var store = StoreService()
    @State private var coachQuota = CoachQuota()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(store)
                .environment(coachQuota)
                .preferredColorScheme(.dark)
                .tint(AuraPalette.auroraPurple)
                .task {
                    FontRegistrar.registerBundledFonts()
                    // Extra coach conversations are granted here, so a top-up
                    // bought anywhere (or replayed later) always lands.
                    store.onCoachTopUpPurchased = { [coachQuota] in
                        coachQuota.grantTopUp()
                    }
                    await store.start()
                }
        }
        .modelContainer(for: [AuraReading.self, JournalEntry.self, RitualCompletion.self])
    }
}

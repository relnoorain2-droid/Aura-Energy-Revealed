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

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(store)
                .preferredColorScheme(.dark)
                .tint(AuraPalette.auroraPurple)
                .task {
                    FontRegistrar.registerBundledFonts()
                    await store.start()
                }
        }
        .modelContainer(for: [AuraReading.self, JournalEntry.self])
    }
}

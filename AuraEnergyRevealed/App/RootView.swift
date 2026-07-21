//
//  RootView.swift
//  Aura Energy Revealed
//
//  Phase router: Splash → Welcome → Onboarding → Permissions → Main.
//  Cross-dissolve transitions per spec (screen 01, "Transition").
//

import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreService.self) private var store

    var body: some View {
        @Bindable var appState = appState
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()

            switch appState.phase {
            case .splash:
                SplashView().transition(.opacity)
            case .welcome:
                WelcomeView().transition(.opacity)
            case .onboarding:
                OnboardingView().transition(.opacity)
            case .permissions:
                PermissionsView().transition(.opacity)
            case .main:
                MainTabView().transition(.opacity)
            }
        }
        .animation(AuraMotion.expressive, value: appState.phase)
        .fullScreenCover(isPresented: $appState.isScanFlowPresented) {
            ScanFlowView()
        }
        .sheet(isPresented: $appState.isPaywallPresented) {
            PaywallView()
        }
    }
}

// MARK: - Main tab container

struct MainTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack(alignment: .bottom) {
            AuroraBackground()

            Group {
                switch appState.selectedTab {
                case .home: HomeView()
                case .explore: ExploreView()
                case .practice: PracticeView()
                case .you: ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            FloatingTabBar()
        }
        .ignoresSafeArea(.keyboard)
    }
}

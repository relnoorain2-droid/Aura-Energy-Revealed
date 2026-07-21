//
//  ScanFlowView.swift
//  Aura Energy Revealed
//
//  The scan spine: gate → camera/upload → cinematic scanning → result.
//  MVVM: ScanViewModel owns the state machine and reading generation.
//

import SwiftUI
import SwiftData

struct ScanFlowView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreService.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AuraReading.date, order: .reverse) private var history: [AuraReading]

    @State private var viewModel = ScanViewModel()

    var body: some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()

            switch viewModel.stage {
            case .camera:
                ScanCameraView(viewModel: viewModel)
                    .transition(.opacity)
            case .scanning:
                ScanningView(viewModel: viewModel)
                    .transition(.opacity)
            case .result(let reading):
                ResultView(reading: reading, isNewReading: true)
                    .transition(.opacity)
            case .failed:
                retryCard
                    .transition(.opacity)
            }
        }
        .animation(AuraMotion.expressive, value: viewModel.stage.key)
        .onAppear {
            viewModel.configure(
                appState: appState,
                store: store,
                modelContext: modelContext,
                history: history
            )
            // Soft paywall: free tier gets exactly one complimentary scan.
            if !appState.canScan(isSubscribed: store.isSubscribed) {
                dismiss()
                appState.isPaywallPresented = true
            }
        }
        .onDisappear {
            viewModel.tearDown()
        }
    }

    /// Calm retry card — "The light shifted — let's try once more."
    private var retryCard: some View {
        VStack(spacing: 20) {
            AuraOrbView(style: .brand, size: 110)
                .opacity(0.6)
            Text("The light shifted —\nlet's try once more.")
                .font(AuraFont.display(26, relativeTo: .title))
                .foregroundStyle(AuraPalette.ink)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Try again") {
                viewModel.stage = .camera
            }
            .padding(.horizontal, 48)
            Button("Not now") { dismiss() }
                .font(AuraFont.text(13))
                .foregroundStyle(AuraPalette.inkGhost)
        }
        .padding(24)
    }
}

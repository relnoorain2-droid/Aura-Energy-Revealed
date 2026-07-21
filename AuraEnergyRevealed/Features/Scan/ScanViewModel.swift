//
//  ScanViewModel.swift
//  Aura Energy Revealed
//
//  Owns the scan state machine, the captured photo, segmentation and
//  reading generation. Views stay declarative and dumb.
//

import SwiftUI
import SwiftData
import Observation

@Observable
final class ScanViewModel {

    enum Stage {
        case camera
        case scanning
        case result(AuraReading)
        case failed

        var key: String {
            switch self {
            case .camera: "camera"
            case .scanning: "scanning"
            case .result: "result"
            case .failed: "failed"
            }
        }
    }

    var stage: Stage = .camera
    var scanMode: ScanMode = .selfAura
    var capturedImage: UIImage?
    var segmentation: SegmentationResult?

    let camera = CameraService()

    private weak var appState: AppState?
    private var store: StoreService?
    private var modelContext: ModelContext?
    private var history: [AuraReading] = []
    private let engine: AuraInterpreting = AuraEngine()

    func configure(appState: AppState, store: StoreService, modelContext: ModelContext, history: [AuraReading]) {
        self.appState = appState
        self.store = store
        self.modelContext = modelContext
        self.history = history
    }

    func tearDown() {
        camera.stop()
    }

    // MARK: Capture

    func capture() {
        Haptics.impactLight()
        camera.capturePhoto { [weak self] image in
            guard let self else { return }
            if let image {
                self.beginScan(with: image)
            } else {
                self.stage = .failed
            }
        }
    }

    func usePickedImage(_ image: UIImage) {
        beginScan(with: image)
    }

    private func beginScan(with image: UIImage) {
        capturedImage = image
        camera.stop()
        stage = .scanning

        // Run interpretation + segmentation while the cinematic build plays.
        Task { @MainActor in
            let draft = engine.makeReading(
                mode: scanMode,
                photo: image,
                intentions: appState?.intentions ?? [],
                history: history,
                recentMoods: fetchRecentMoods()
            )

            let glowColor = UIColor(draft.dominant.orbStyle.colors.first ?? AuraPalette.lavender)
            segmentation = await PersonSegmentationService.process(image: image, glowColor: glowColor)

            // Persist the reading with the photo — the user's image is the hero.
            let reading = AuraReading(
                mode: draft.mode,
                dominant: draft.dominant,
                secondary: draft.secondary,
                tertiary: draft.tertiary,
                dominantFraction: draft.dominantFraction,
                secondaryFraction: draft.secondaryFraction,
                tertiaryFraction: draft.tertiaryFraction,
                essence: draft.essence,
                interpretation: draft.interpretation,
                intuition: draft.intuition,
                calm: draft.calm,
                vitality: draft.vitality,
                suggestedPractice: draft.suggestedPractice,
                photoData: image.jpegData(compressionQuality: 0.85)
            )
            pendingReading = reading
        }
    }

    /// Recent journal moods feed the engine's personalization (on-device only).
    private func fetchRecentMoods() -> [String] {
        guard let modelContext else { return [] }
        var descriptor = FetchDescriptor<JournalEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 3
        let entries = (try? modelContext.fetch(descriptor)) ?? []
        return entries.flatMap(\.moods)
    }

    /// Set once analysis completes; the scanning animation reveals it
    /// only after the full cinematic build (never cut the moment short).
    private(set) var pendingReading: AuraReading?

    func completeScan() {
        guard let reading = pendingReading else {
            stage = .failed
            return
        }
        if let modelContext {
            modelContext.insert(reading)
            try? modelContext.save()
        }
        if let appState, let store {
            appState.consumeFreeScanIfNeeded(isSubscribed: store.isSubscribed)
        }
        Haptics.success()
        stage = .result(reading)
    }
}

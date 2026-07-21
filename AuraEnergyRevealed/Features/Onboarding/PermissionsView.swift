//
//  PermissionsView.swift
//  Aura Energy Revealed
//
//  Screen 04 — earn access with honesty. Priming cards before the OS
//  dialogs; privacy is the pitch. No dead ends when denied.
//

import SwiftUI
import AVFoundation

struct PermissionsView: View {
    @Environment(AppState.self) private var appState
    @State private var cameraGranted = false
    @State private var notificationsGranted = false

    var body: some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()
            RadialBloom(color: AuraPalette.auroraPurpleDeep, center: .init(x: 0.5, y: 0.2), opacity: 0.3)

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 70)

                Text("A little access,\nfor the magic")
                    .font(AuraFont.display(30, relativeTo: .largeTitle))
                    .foregroundStyle(AuraPalette.ink)
                    .padding(.bottom, 8)

                Text("Everything happens privately on your iPhone.")
                    .font(AuraFont.text(13, weight: .light))
                    .foregroundStyle(AuraPalette.inkDim)
                    .padding(.bottom, 22)

                permissionCard(
                    symbol: "camera.fill",
                    color: AuraPalette.electricBlue,
                    title: "Camera",
                    reason: "Capture your aura in real time",
                    granted: cameraGranted
                ) {
                    requestCamera()
                }
                .riseFadeIn(index: 0)

                permissionCard(
                    symbol: "photo.on.rectangle",
                    color: AuraPalette.lavender,
                    title: "Photos",
                    reason: "Read an aura from a saved image",
                    granted: true,
                    note: "Asked when you choose a photo"
                ) {}
                .riseFadeIn(index: 1)

                permissionCard(
                    symbol: "bell.badge.fill",
                    color: AuraPalette.gold,
                    title: "Notifications",
                    reason: "A gentle daily reflection nudge",
                    granted: notificationsGranted
                ) {
                    requestNotifications()
                }
                .riseFadeIn(index: 2)

                Spacer()

                Text("Your photos are analysed on your device and never uploaded without asking.")
                    .font(AuraFont.text(12, weight: .light))
                    .foregroundStyle(AuraPalette.inkFaint)
                    .padding(.bottom, 14)

                PrimaryButton(title: "Continue") {
                    appState.completeOnboarding()
                }
                .padding(.bottom, 36)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: Cards

    @ViewBuilder
    private func permissionCard(
        symbol: String, color: Color, title: String, reason: String,
        granted: Bool, note: String? = nil, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.16))
                    .frame(width: 42, height: 42)
                    .overlay {
                        Image(systemName: symbol)
                            .font(.system(size: 17))
                            .foregroundStyle(color)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AuraFont.text(14, weight: .semibold))
                        .foregroundStyle(AuraPalette.ink)
                    Text(note ?? reason)
                        .font(AuraFont.text(11.5, weight: .light))
                        .foregroundStyle(AuraPalette.inkDim)
                }

                Spacer()

                // Toggle-style state preview
                Capsule()
                    .fill(granted ? AuraPalette.emerald : Color.white.opacity(0.15))
                    .frame(width: 40, height: 24)
                    .overlay(alignment: granted ? .trailing : .leading) {
                        Circle()
                            .fill(.white)
                            .frame(width: 20, height: 20)
                            .padding(2)
                    }
                    .animation(AuraMotion.micro, value: granted)
            }
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: AuraRadius.card, style: .continuous)
                    .fill(.white.opacity(0.05))
                RoundedRectangle(cornerRadius: AuraRadius.card, style: .continuous)
                    .strokeBorder(.white.opacity(0.09), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .padding(.bottom, 12)
        .accessibilityLabel("\(title): \(reason). \(granted ? "Enabled" : "Tap to enable")")
    }

    // MARK: Requests

    private func requestCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraGranted = granted
                    if granted { Haptics.success() }
                }
            }
        default:
            openSettings()
        }
    }

    private func requestNotifications() {
        Task {
            let granted = await NotificationService.requestAuthorization()
            await MainActor.run {
                notificationsGranted = granted
                if granted {
                    Haptics.success()
                    NotificationService.scheduleDailyReflection(hour: 9, minute: 0)
                }
            }
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

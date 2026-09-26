//
//  ScanCameraView.swift
//  Aura Energy Revealed
//
//  Screen 06 — full-bleed viewfinder, dimmed vignette, framing ring,
//  minimal chrome. The moment feels ceremonial.
//

import SwiftUI
import PhotosUI

struct ScanCameraView: View {
    @Bindable var viewModel: ScanViewModel
    @ObservedObject var camera: CameraService

    init(viewModel: ScanViewModel) {
        self.viewModel = viewModel
        _camera = ObservedObject(wrappedValue: viewModel.camera)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(StoreService.self) private var store
    @Environment(AppState.self) private var appState

    @State private var pickedItem: PhotosPickerItem?
    @State private var ringReady = false

    var body: some View {
        ZStack {
            // Live viewfinder or graceful fallback
            if camera.status == .configured {
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [Color(hex: 0x1A1420), Color(hex: 0x0F0D16)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if camera.status == .denied {
                    deniedCard
                }
            }

            // Vignette
            RadialGradient(
                colors: [.clear, .black.opacity(0.55)],
                center: .center, startRadius: 140, endRadius: 460
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Framing guide — an oval for a face, a wide rectangle for a room
            // or an object. The shape itself tells you what to point at.
            framingGuide
                .allowsHitTesting(false)

            VStack {
                topChrome
                Spacer()

                VStack(spacing: 4) {
                    Text(ringReady ? "Hold still" : viewModel.scanMode.captureTitle)
                        .font(AuraFont.text(14, weight: .semibold))
                        .foregroundStyle(ringReady ? AuraPalette.emerald : AuraPalette.gold)
                    Text(viewModel.scanMode.captureHint)
                        .font(AuraFont.text(11))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 22)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(viewModel.scanMode.captureTitle). \(viewModel.scanMode.captureHint)")

                bottomControls
            }
        }
        .onAppear {
            // Point the camera at the right subject before the session starts.
            camera.use(front: viewModel.scanMode.usesFrontCamera)
            camera.requestAndConfigure()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                withAnimation(AuraMotion.standard) { ringReady = true }
            }
        }
        .onChange(of: viewModel.scanMode) { _, mode in
            // Switching subject switches the camera with it.
            camera.use(front: mode.usesFrontCamera)
            ringReady = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(AuraMotion.standard) { ringReady = true }
            }
        }
        .onChange(of: pickedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run { viewModel.usePickedImage(image) }
                }
            }
        }
    }

    // MARK: Chrome

    private var topChrome: some View {
        HStack {
            circleButton(symbol: "xmark") { dismiss() }

            Spacer()

            Menu {
                ForEach(ScanMode.allCases) { mode in
                    Button {
                        selectMode(mode)
                    } label: {
                        Label(
                            mode.isPremium && !store.isSubscribed ? "\(mode.title) · Aura+" : mode.title,
                            systemImage: mode.symbol
                        )
                    }
                }
            } label: {
                AuraChip(label: "✦ \(viewModel.scanMode.title) ▾", emphasized: true)
            }

            Spacer()

            circleButton(symbol: "arrow.triangle.2.circlepath.camera") {
                camera.flipCamera()
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
    }

    /// An upright oval for a face; a wide rectangle for a room, plant, pet,
    /// object or dish. The guide shape alone tells you what to point at.
    @ViewBuilder
    private var framingGuide: some View {
        let tint = (ringReady ? AuraPalette.emerald : AuraPalette.gold).opacity(0.8)
        let glow = AuraPalette.emerald.opacity(ringReady ? 0.35 : 0)

        if viewModel.scanMode.isPersonReading {
            Ellipse()
                .strokeBorder(tint, lineWidth: 2)
                .frame(width: 210, height: 250)
                .shadow(color: glow, radius: 16)
                .offset(y: -30)
        } else {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(tint, lineWidth: 2)
                .frame(width: 292, height: 220)
                .shadow(color: glow, radius: 16)
                .offset(y: -20)
        }
    }

    private var bottomControls: some View {
        HStack(spacing: 40) {
            // Photo upload shortcut
            PhotosPicker(selection: $pickedItem, matching: .images) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AuraPalette.lavender, AuraPalette.electricBlue],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                    }
            }
            .accessibilityLabel("Choose a photo instead")

            // Capture orb
            Button {
                viewModel.capture()
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(.white.opacity(0.9), lineWidth: 4)
                        .frame(width: 74, height: 74)
                    Circle()
                        .fill(AngularGradient(colors: AuraPalette.spectrum, center: .center))
                        .frame(width: 58, height: 58)
                }
            }
            .pressScale()
            .disabled(camera.status != .configured)
            .opacity(camera.status == .configured ? 1 : 0.4)
            .accessibilityLabel("Capture")

            circleButton(symbol: "bolt.slash") {}
                .opacity(0.7)
        }
        .padding(.bottom, 44)
    }

    private func selectMode(_ mode: ScanMode) {
        if mode.isPremium && !store.isSubscribed {
            dismiss()
            appState.isPaywallPresented = true
        } else {
            viewModel.scanMode = mode
        }
    }

    private func circleButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(.black.opacity(0.4))
                .frame(width: 38, height: 38)
                .overlay {
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                }
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private var deniedCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "camera.badge.ellipsis")
                .font(.system(size: 30))
                .foregroundStyle(AuraPalette.rose)
            Text("The camera is resting")
                .font(AuraFont.display(22, relativeTo: .title2))
                .foregroundStyle(AuraPalette.ink)
            Text("Enable camera access in Settings, or choose a photo from your library instead.")
                .font(AuraFont.text(13, weight: .light))
                .foregroundStyle(AuraPalette.inkDim)
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(AuraFont.text(14, weight: .semibold))
            .foregroundStyle(AuraPalette.electricBlue)
        }
        .padding(28)
    }
}

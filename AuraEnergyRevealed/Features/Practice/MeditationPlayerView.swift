//
//  MeditationPlayerView.swift
//  Aura Energy Revealed
//
//  Screen 14 — the breathing player. The aura expands on inhale and
//  contracts on exhale (4-7-8 pacing). Tap the orb to pause/play.
//
//  Audio lifecycle (important):
//  Breathing cadence, the elapsed clock and the spoken cues are ALL driven by
//  a single, cancelable Timer. There are deliberately no free-running
//  DispatchQueue.asyncAfter loops — those cannot be cancelled and were the
//  cause of sound continuing after the screen was closed. `teardown()` is the
//  one place that stops everything, and it runs on close, on finish, when the
//  app leaves the foreground, and on audio interruptions.
//

import SwiftUI

struct MeditationPlayerView: View {
    let meditation: Meditation

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("meditationsCompleted") private var meditationsCompleted = 0
    @AppStorage("weeklyCalmMinutes") private var weeklyCalmMinutes = 70.0
    @AppStorage("meditationSoundMuted") private var soundMuted = false

    @State private var elapsed: TimeInterval = 0
    @State private var isPlaying = true
    @State private var breathPhase: BreathPhase = .inhale
    @State private var phaseRemaining: Double = BreathPhase.inhale.duration
    @State private var timer: Timer?
    @State private var audio = MeditationAudioService()
    @State private var didComplete = false

    private enum BreathPhase: String {
        case inhale = "Breathe in"
        case hold = "Hold"
        case exhale = "Breathe out"

        var scale: CGFloat {
            switch self {
            case .inhale: 1.18
            case .hold: 1.18
            case .exhale: 0.88
            }
        }

        var duration: Double {
            switch self {
            case .inhale: 4
            case .hold: 7
            case .exhale: 8
            }
        }

        var next: BreathPhase {
            switch self {
            case .inhale: .hold
            case .hold: .exhale
            case .exhale: .inhale
            }
        }
    }

    private var total: TimeInterval { Double(meditation.minutes * 60) }

    var body: some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()
            RadialBloom(
                color: meditation.hue.orbStyle.colors.first ?? AuraPalette.emerald,
                center: .init(x: 0.5, y: 0.35),
                opacity: 0.28
            )

            VStack(spacing: 0) {
                HStack {
                    MonoLabel(text: "Meditation")
                    Spacer()
                    Button {
                        soundMuted.toggle()
                        audio.isMuted = soundMuted
                        Haptics.impactSoft()
                    } label: {
                        Image(systemName: soundMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AuraPalette.ink.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel(soundMuted ? "Unmute sound" : "Mute sound")
                    .padding(.trailing, 8)

                    Button { finish() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AuraPalette.ink.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Close meditation")
                }
                .padding(.horizontal, AuraSpacing.gutter)
                .padding(.top, 20)

                Spacer()

                // Breathing orb — tap to pause/play
                Button { togglePlay() } label: {
                    AuraOrbView(style: meditation.hue.orbStyle, size: 190)
                        .scaleEffect(reduceMotion || !isPlaying ? 1 : breathPhase.scale)
                        .animation(.easeInOut(duration: breathPhase.duration), value: breathPhase)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isPlaying ? "Pause meditation" : "Resume meditation")

                Text(isPlaying ? breathPhase.rawValue : "Paused")
                    .font(AuraFont.text(13, weight: .medium))
                    .foregroundStyle(AuraPalette.inkDim)
                    .padding(.top, 24)

                Text(meditation.title)
                    .font(AuraFont.display(26, relativeTo: .title))
                    .foregroundStyle(AuraPalette.ink)
                    .padding(.top, 8)

                Text("\(meditation.subtitle) · \(meditation.minutes) min")
                    .font(AuraFont.text(12, weight: .light))
                    .foregroundStyle(AuraPalette.inkDim)
                    .padding(.top, 4)

                Spacer()

                // Progress
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.12))
                            Capsule()
                                .fill(meditation.hue.orbStyle.colors.first ?? AuraPalette.emerald)
                                .frame(width: geo.size.width * min(1, elapsed / total))
                        }
                    }
                    .frame(height: 4)

                    HStack {
                        Text(timeString(elapsed))
                        Spacer()
                        Text(timeString(total))
                    }
                    .font(AuraFont.mono(11))
                    .foregroundStyle(AuraPalette.inkGhost)
                }
                .padding(.horizontal, AuraSpacing.gutter)

                // Transport
                HStack(spacing: 34) {
                    transportButton("gobackward.15") { elapsed = max(0, elapsed - 15) }

                    Button { togglePlay() } label: {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [meditation.hue.orbStyle.colors.first ?? AuraPalette.emerald, AuraPalette.electricBlue],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .overlay {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.white)
                            }
                            .shadow(color: (meditation.hue.orbStyle.colors.first ?? AuraPalette.emerald).opacity(0.5), radius: 14)
                    }
                    .pressScale()

                    transportButton("goforward.15") { elapsed = min(total, elapsed + 15) }
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear { begin() }
        .onDisappear { teardown() }
        // If the app is backgrounded or covered, always silence + stop.
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                isPlaying = false
                teardown()
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func transportButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18))
                .foregroundStyle(AuraPalette.ink.opacity(0.6))
        }
    }

    // MARK: - Playback control

    private func begin() {
        isPlaying = true
        audio.onInterruptionBegan = {
            isPlaying = false
            teardown()
        }
        audio.isMuted = soundMuted
        audio.start(baseHz: 110)
        audio.speak(breathPhase.rawValue)
        startTimer()
    }

    private func togglePlay() {
        Haptics.impactSoft()
        isPlaying.toggle()
        if isPlaying {
            // Resume — restart audio/timer if they were fully stopped
            // (e.g. after returning from the background).
            if !audio.isRunning {
                audio.isMuted = soundMuted
                audio.start(baseHz: 110)
            } else {
                audio.resume()
            }
            if timer == nil { startTimer() }
        } else {
            audio.pause()
        }
    }

    private func startTimer() {
        timer?.invalidate()
        phaseRemaining = breathPhase.duration
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard isPlaying else { return }

            elapsed += 1
            if elapsed >= total { finish(); return }

            phaseRemaining -= 1
            if phaseRemaining <= 0 {
                breathPhase = breathPhase.next
                phaseRemaining = breathPhase.duration
                Haptics.impactSoft()
                audio.speak(breathPhase.rawValue)
            }
        }
    }

    /// The single, authoritative stop. Safe to call repeatedly.
    private func teardown() {
        timer?.invalidate()
        timer = nil
        audio.stop()
    }

    private func finish() {
        teardown()
        if !didComplete, elapsed >= total * 0.8 {
            didComplete = true
            meditationsCompleted += 1
            weeklyCalmMinutes += Double(meditation.minutes)
            Haptics.success()
        }
        dismiss()
    }

    private func timeString(_ t: TimeInterval) -> String {
        String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }
}

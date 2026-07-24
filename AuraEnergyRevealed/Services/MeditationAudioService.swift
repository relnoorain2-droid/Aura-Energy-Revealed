//
//  MeditationAudioService.swift
//  Aura Energy Revealed
//
//  Sound for the meditation player. Two layers, both generated on-device so
//  nothing is bundled and there is zero music-licensing exposure:
//
//    1. Ambient pad — a soft, slowly-breathing drone synthesised in real time
//       with AVAudioEngine (a few detuned sine partials + gentle reverb).
//    2. Voice cues — spoken "Breathe in / Hold / Breathe out" guidance via
//       Apple's on-device AVSpeechSynthesizer, timed to the 4-7-8 pattern.
//
//  Lifecycle contract:
//    • stop() is idempotent and FINAL — after it runs, no sound can play until
//      start() is called again. speak() is a no-op unless the service is
//      running, so a stray call can never revive audio.
//    • An audio-session interruption (a phone call, Siri, another app) pauses
//      playback and notifies the UI via onInterruptionBegan.
//    • deinit stops everything, so a released player can never orphan sound.
//

import AVFoundation

final class MeditationAudioService {

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private let reverb = AVAudioUnitReverb()
    private let synth = AVSpeechSynthesizer()

    private let sampleRate: Double = 44_100
    private var phase1: Double = 0   // root
    private var phase2: Double = 0   // fifth
    private var phase3: Double = 0   // octave
    private var lfoPhase: Double = 0 // slow amplitude swell

    private var graphBuilt = false
    private var interruptionObserver: NSObjectProtocol?

    /// Base pitch of the pad.
    private var rootHz: Double = 110

    /// Called (on the main queue) when the audio session is interrupted so the
    /// player can reflect the paused state.
    var onInterruptionBegan: (() -> Void)?

    private(set) var isRunning = false
    var isMuted = false {
        didSet { engine.mainMixerNode.outputVolume = isMuted ? 0 : padVolume }
    }

    private let padVolume: Float = 0.5

    deinit { stop() }

    // MARK: - Lifecycle

    func start(baseHz: Double = 110) {
        guard !isRunning else { return }
        rootHz = baseHz
        configureSession()
        registerInterruptionObserver()
        buildGraphIfNeeded()
        do {
            try engine.start()
            engine.mainMixerNode.outputVolume = isMuted ? 0 : padVolume
            isRunning = true
        } catch {
            isRunning = false
        }
    }

    /// Temporarily silence without tearing down (tap-to-pause).
    func pause() {
        synth.stopSpeaking(at: .immediate)
        if engine.isRunning { engine.pause() }
    }

    /// Resume after pause(). No-op if the service was fully stopped.
    func resume() {
        guard isRunning else { return }
        try? engine.start()
    }

    /// The one, final stop. Safe to call repeatedly and from any state.
    func stop() {
        synth.stopSpeaking(at: .immediate)
        if engine.isRunning { engine.stop() }
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
            interruptionObserver = nil
        }
        if isRunning {
            isRunning = false
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    // MARK: - Voice cues

    /// Speak a short breath cue. No-op unless running and unmuted, so a stray
    /// call after stop() can never restart audio.
    func speak(_ text: String) {
        guard isRunning, !isMuted else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.82
        utterance.pitchMultiplier = 0.96
        utterance.volume = 0.7
        utterance.preUtteranceDelay = 0
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synth.speak(utterance)
    }

    // MARK: - Private

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func registerInterruptionObserver() {
        guard interruptionObserver == nil else { return }
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self,
                  let info = note.userInfo,
                  let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: raw)
            else { return }
            if type == .began {
                self.synth.stopSpeaking(at: .immediate)
                if self.engine.isRunning { self.engine.pause() }
                self.onInterruptionBegan?()
            }
        }
    }

    private func buildGraphIfNeeded() {
        guard !graphBuilt else { return }
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let twoPi = 2.0 * Double.pi
            let inc1 = twoPi * self.rootHz / self.sampleRate
            let inc2 = twoPi * (self.rootHz * 1.5) / self.sampleRate      // perfect fifth
            let inc3 = twoPi * (self.rootHz * 2.0) / self.sampleRate      // octave
            let lfoInc = twoPi * 0.07 / self.sampleRate                   // ~14s swell

            for frame in 0..<Int(frameCount) {
                let swell = 0.5 + 0.5 * sin(self.lfoPhase)               // 0…1
                let s1 = sin(self.phase1) * 0.5
                let s2 = sin(self.phase2) * 0.28
                let s3 = sin(self.phase3) * 0.16
                let sample = Float((s1 + s2 + s3) * (0.35 + 0.65 * swell) * 0.6)

                self.phase1 += inc1; if self.phase1 > twoPi { self.phase1 -= twoPi }
                self.phase2 += inc2; if self.phase2 > twoPi { self.phase2 -= twoPi }
                self.phase3 += inc3; if self.phase3 > twoPi { self.phase3 -= twoPi }
                self.lfoPhase += lfoInc; if self.lfoPhase > twoPi { self.lfoPhase -= twoPi }

                for buffer in ablPointer {
                    let buf = buffer.mData!.assumingMemoryBound(to: Float.self)
                    buf[frame] = sample
                }
            }
            return noErr
        }

        sourceNode = node
        engine.attach(node)
        engine.attach(reverb)
        reverb.loadFactoryPreset(.largeHall2)
        reverb.wetDryMix = 55

        engine.connect(node, to: reverb, format: format)
        engine.connect(reverb, to: engine.mainMixerNode, format: format)
        graphBuilt = true
    }
}

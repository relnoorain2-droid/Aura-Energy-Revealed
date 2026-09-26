//
//  DailyRitualView.swift
//  Auralis
//
//  A four-part guided ritual: arrive, breathe, set an intention, reflect.
//  The content changes daily and the breath pattern follows your latest reading.
//
//  The breathing stage is driven by a single cancellable timer that is torn down
//  on disappear, on completion and when the app leaves the foreground — so it
//  can never keep running behind the user's back.
//

import SwiftUI
import SwiftData

struct DailyRitualView: View {

    enum Stage: Int, CaseIterable {
        case arrive, breathe, intention, reflect, close

        var label: String {
            switch self {
            case .arrive: "Arrive"
            case .breathe: "Breathe"
            case .intention: "Intention"
            case .reflect: "Reflect"
            case .close: "Close"
            }
        }
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \AuraReading.date, order: .reverse) private var readings: [AuraReading]

    @State private var stage: Stage = .arrive
    @State private var intentionText = ""
    @State private var reflectionText = ""

    // Breathing engine
    @State private var timer: Timer?
    @State private var phaseIndex = 0
    @State private var phaseRemaining = 0
    @State private var round = 1
    @State private var isBreathing = false
    @State private var secondsPracticed = 0

    private var latestAura: AuraHue? { readings.first?.dominant }
    private var ritual: DailyRitual { DailyRitualComposer.ritual(aura: latestAura) }

    var body: some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()
            RadialBloom(color: tint, center: .init(x: 0.5, y: 0.15), opacity: 0.26)

            VStack(spacing: 0) {
                topBar
                progressRail
                    .padding(.horizontal, AuraSpacing.gutter)
                    .padding(.bottom, 18)

                ScrollView {
                    Group {
                        switch stage {
                        case .arrive:    arriveStage
                        case .breathe:   breatheStage
                        case .intention: intentionStage
                        case .reflect:   reflectStage
                        case .close:     closeStage
                        }
                    }
                    .padding(.horizontal, AuraSpacing.gutter)
                }
                .scrollIndicators(.hidden)

                footer
            }
        }
        .onDisappear(perform: teardown)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { pauseBreathing() }
        }
    }

    private var tint: Color {
        latestAura?.titleColor ?? AuraPalette.auroraPurple
    }

    // MARK: Chrome

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(ritual.title)
                    .font(AuraFont.display(19))
                    .foregroundStyle(AuraPalette.ink)
                Text("\(ritual.estimatedMinutes) min · \(stage.label)")
                    .font(AuraFont.mono(9))
                    .foregroundStyle(AuraPalette.inkGhost)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13))
                    .foregroundStyle(AuraPalette.ink.opacity(0.6))
            }
            .accessibilityLabel("Close ritual")
        }
        .padding(.horizontal, AuraSpacing.gutter)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    private var progressRail: some View {
        HStack(spacing: 5) {
            ForEach(Stage.allCases, id: \.rawValue) { item in
                Capsule()
                    .fill(item.rawValue <= stage.rawValue ? tint : AuraPalette.fillStrong)
                    .frame(height: 3)
            }
        }
        .animation(.easeOut(duration: 0.3), value: stage)
    }

    // MARK: Stages

    private var arriveStage: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(ritual.opening)
                .font(AuraFont.display(25))
                .foregroundStyle(AuraPalette.ink)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            GlassCard(padding: 16, tint: tint) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("TODAY'S BREATH")
                        .font(AuraFont.mono(9))
                        .foregroundStyle(AuraPalette.inkGhost)
                    Text(ritual.breath.name)
                        .font(AuraFont.text(15, weight: .semibold))
                        .foregroundStyle(AuraPalette.ink)
                    Text(ritual.breath.purpose)
                        .font(AuraFont.text(12))
                        .foregroundStyle(AuraPalette.inkDim)
                        .fixedSize(horizontal: false, vertical: true)
                    if let aura = ritual.aura {
                        Divider().overlay(AuraPalette.hairline)
                        Text("Chosen for your \(aura.displayName.lowercased()) reading.")
                            .font(AuraFont.text(11))
                            .foregroundStyle(AuraPalette.inkGhost)
                    }
                }
            }
        }
        .padding(.bottom, 20)
    }

    private var breatheStage: some View {
        VStack(spacing: 22) {
            Text(currentPhaseName)
                .font(AuraFont.display(27))
                .foregroundStyle(AuraPalette.ink)
                .contentTransition(.opacity)

            ZStack {
                Circle()
                    .stroke(tint.opacity(0.18), lineWidth: 1)
                    .frame(width: 230, height: 230)

                Circle()
                    .fill(RadialGradient(colors: [tint.opacity(0.55), tint.opacity(0.05)],
                                         center: .center, startRadius: 4, endRadius: 120))
                    .frame(width: 210, height: 210)
                    .scaleEffect(breathScale)
                    .animation(.easeInOut(duration: Double(max(1, currentPhaseDuration))), value: phaseIndex)

                VStack(spacing: 2) {
                    Text("\(max(0, phaseRemaining))")
                        .font(AuraFont.display(40))
                        .foregroundStyle(AuraPalette.ink)
                    Text("Round \(round) of \(ritual.breath.rounds)")
                        .font(AuraFont.mono(9))
                        .foregroundStyle(AuraPalette.inkGhost)
                }
            }
            .frame(height: 250)

            Text(ritual.breath.cadenceLabel)
                .font(AuraFont.mono(11))
                .foregroundStyle(AuraPalette.inkGhost)

            Button {
                isBreathing ? pauseBreathing() : startBreathing()
            } label: {
                Text(isBreathing ? "Pause" : (phaseRemaining == 0 && round == 1 ? "Begin" : "Resume"))
                    .font(AuraFont.text(13, weight: .semibold))
                    .foregroundStyle(AuraPalette.ink)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 11)
                    .background { Capsule().fill(AuraPalette.fillStrong) }
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 20)
    }

    private var intentionStage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(ritual.intentionPrompt)
                .font(AuraFont.display(23))
                .foregroundStyle(AuraPalette.ink)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            promptEditor(text: $intentionText, placeholder: "A sentence is plenty…")

            Text("This is only for you. It stays on your device.")
                .font(AuraFont.text(11))
                .foregroundStyle(AuraPalette.inkGhost)
        }
        .padding(.bottom, 20)
    }

    private var reflectStage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(ritual.reflectionPrompt)
                .font(AuraFont.display(23))
                .foregroundStyle(AuraPalette.ink)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            promptEditor(text: $reflectionText, placeholder: "Write as much or as little as you like…")
        }
        .padding(.bottom, 20)
    }

    private var closeStage: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(ritual.closing)
                .font(AuraFont.display(25))
                .foregroundStyle(AuraPalette.ink)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            if !intentionText.isEmpty || !reflectionText.isEmpty {
                GlassCard(padding: 16, tint: tint) {
                    VStack(alignment: .leading, spacing: 12) {
                        if !intentionText.isEmpty {
                            summaryRow(title: "YOUR INTENTION", body: intentionText)
                        }
                        if !reflectionText.isEmpty {
                            if !intentionText.isEmpty { Divider().overlay(AuraPalette.hairline) }
                            summaryRow(title: "YOUR REFLECTION", body: reflectionText)
                        }
                    }
                }
            }

            if secondsPracticed > 0 {
                Text("You breathed for \(secondsPracticed / 60)m \(secondsPracticed % 60)s.")
                    .font(AuraFont.text(11))
                    .foregroundStyle(AuraPalette.inkGhost)
            }
        }
        .padding(.bottom, 20)
    }

    private func summaryRow(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(AuraFont.mono(9))
                .foregroundStyle(AuraPalette.inkGhost)
            Text(body)
                .font(AuraFont.text(13))
                .foregroundStyle(AuraPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func promptEditor(text: Binding<String>, placeholder: String) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16).fill(AuraPalette.fill)
            RoundedRectangle(cornerRadius: 16).strokeBorder(AuraPalette.hairline, lineWidth: 1)
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(AuraFont.text(13))
                    .foregroundStyle(AuraPalette.inkGhost)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .allowsHitTesting(false)
            }
            TextEditor(text: text)
                .font(AuraFont.text(13))
                .foregroundStyle(AuraPalette.ink)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
        }
        .frame(minHeight: 130)
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 10) {
            if stage != .arrive {
                Button {
                    pauseBreathing()
                    withAnimation { stage = Stage(rawValue: stage.rawValue - 1) ?? .arrive }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AuraPalette.ink)
                        .frame(width: 46, height: 46)
                        .background { Circle().fill(AuraPalette.fillStrong) }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Previous step")
            }

            Button(action: advance) {
                Text(stage == .close ? "Finish" : "Continue")
                    .font(AuraFont.text(14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background { Capsule().fill(AuraPalette.primaryGradient) }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AuraSpacing.gutter)
        .padding(.vertical, 14)
    }

    private func advance() {
        Haptics.impactSoft()
        if stage == .close {
            save()
            dismiss()
            return
        }
        pauseBreathing()
        withAnimation { stage = Stage(rawValue: stage.rawValue + 1) ?? .close }
        if stage == .breathe { resetBreathing() }
    }

    // MARK: Breathing engine

    private var phases: [(name: String, duration: Int)] {
        var list: [(String, Int)] = [("Breathe in", ritual.breath.inhale)]
        if ritual.breath.hold > 0 { list.append(("Hold", ritual.breath.hold)) }
        list.append(("Breathe out", ritual.breath.exhale))
        if ritual.breath.rest > 0 { list.append(("Rest", ritual.breath.rest)) }
        return list
    }

    private var currentPhaseName: String { phases[phaseIndex % phases.count].name }
    private var currentPhaseDuration: Int { phases[phaseIndex % phases.count].duration }

    private var breathScale: CGFloat {
        switch currentPhaseName {
        case "Breathe in": 1.0
        case "Hold": 1.0
        case "Breathe out": 0.62
        default: 0.62
        }
    }

    private func resetBreathing() {
        phaseIndex = 0
        phaseRemaining = phases[0].duration
        round = 1
    }

    private func startBreathing() {
        guard !isBreathing else { return }
        if phaseRemaining == 0 { resetBreathing() }
        isBreathing = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in tick() }
        }
    }

    private func pauseBreathing() {
        isBreathing = false
        timer?.invalidate()
        timer = nil
    }

    private func teardown() {
        pauseBreathing()
    }

    @MainActor
    private func tick() {
        guard isBreathing else { return }
        secondsPracticed += 1

        if phaseRemaining > 1 {
            phaseRemaining -= 1
            return
        }

        // Move to the next phase, and possibly the next round.
        let next = phaseIndex + 1
        if next >= phases.count {
            if round >= ritual.breath.rounds {
                pauseBreathing()
                Haptics.success()
                withAnimation { stage = .intention }
                return
            }
            round += 1
            phaseIndex = 0
        } else {
            phaseIndex = next
        }
        phaseRemaining = phases[phaseIndex % phases.count].duration
        Haptics.tick()
    }

    // MARK: Save

    private func save() {
        let completion = RitualCompletion(
            intention: intentionText.trimmingCharacters(in: .whitespacesAndNewlines),
            reflection: reflectionText.trimmingCharacters(in: .whitespacesAndNewlines),
            aura: latestAura,
            breathPatternID: ritual.breath.id,
            secondsPracticed: secondsPracticed
        )
        modelContext.insert(completion)
        try? modelContext.save()
    }
}

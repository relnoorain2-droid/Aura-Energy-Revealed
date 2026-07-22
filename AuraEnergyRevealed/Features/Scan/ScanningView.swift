//
//  ScanningView.swift
//  Aura Energy Revealed
//
//  Screen 07 — the signature moment. A deliberate ~7s cinematic build:
//  0–1.5s  capture freezes & desaturates
//  1.5–4s  a light bar sweeps the subject, particles rise
//  4–5.5s  concentric rings expand, colour blooms from the center
//  5.5–7s  orb coalesces, whites bloom, crossfade to result
//  Reduce Motion: luminous cross-fade with progress instead.
//

import SwiftUI

struct ScanningView: View {
    @Bindable var viewModel: ScanViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var phase = 0            // 0 freeze · 1 sweep · 2 bloom · 3 coalesce
    @State private var statusIndex = 0
    @State private var scanlineDown = false
    @State private var ringsOn = false
    @State private var whiteBloom = false

    private let statusLines = [
        "Reading your energy…",
        "Sensing chakra resonance",
        "Interpreting your colours",
    ]

    var body: some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()
            RadialBloom(color: AuraPalette.auroraPurpleDeep, center: .init(x: 0.5, y: 0.45), opacity: phase >= 2 ? 0.45 : 0.2)

            // Frozen, desaturated capture beneath the effects
            if let image = viewModel.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .saturation(phase == 0 ? 0.6 : 0.25)
                    .opacity(phase >= 3 ? 0.15 : 0.4)
                    .overlay(AuraPalette.deepSpace.opacity(0.5))
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 1.2), value: phase)
            }

            if !reduceMotion {
                RisingParticles()
                    .opacity(phase >= 1 ? 1 : 0)
                    .animation(.easeIn(duration: 0.8), value: phase)
            }

            // Concentric resonance rings
            if ringsOn && !reduceMotion {
                ForEach(0..<3, id: \.self) { i in
                    ExpandingRing(delay: Double(i))
                }
            }

            // Coalescing orb
            AuraOrbView(style: .brand, size: 200)
                .opacity(phase >= 2 ? 1 : 0)
                .scaleEffect(phase >= 2 ? 1 : 0.5)
                .animation(.spring(response: 1.1, dampingFraction: 0.75), value: phase)

            // Scanning light bar
            if phase == 1 && !reduceMotion {
                GeometryReader { geo in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white, .clear],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(height: 2)
                        .shadow(color: .white, radius: 8)
                        .offset(y: scanlineDown ? geo.size.height * 0.86 : geo.size.height * 0.08)
                        .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: scanlineDown)
                        .padding(.horizontal, 30)
                }
                .transition(.opacity)
            }

            // White bloom before the reveal
            Color.white
                .ignoresSafeArea()
                .opacity(whiteBloom ? 0.85 : 0)
                .animation(.easeIn(duration: 0.7), value: whiteBloom)

            // Status copy
            VStack {
                Spacer()
                Text(statusLines[statusIndex])
                    .font(AuraFont.display(24, relativeTo: .title2))
                    .foregroundStyle(.white.opacity(0.9))
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.4), value: statusIndex)
                MonoLabel(text: statusLines[(statusIndex + 1) % statusLines.count], color: AuraPalette.ink.opacity(0.5))
                    .padding(.top, 8)
                    .padding(.bottom, 120)
            }
        }
        .onAppear { runSequence() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Reading your energy")
    }

    // MARK: Sequence direction

    private func runSequence() {
        let total: Double = reduceMotion ? 3.0 : 7.0

        if reduceMotion {
            // Simple luminous cross-fade
            phase = 2
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { statusIndex = 2 }
        } else {
            // Phase 1 · sweep
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                phase = 1
                scanlineDown = true
                Haptics.tick()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { statusIndex = 1; Haptics.tick() }

            // Phase 2 · rings + bloom
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                phase = 2
                ringsOn = true
                statusIndex = 2
                Haptics.impactSoft()
            }

            // Phase 3 · coalesce + white bloom
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
                phase = 3
                whiteBloom = true
            }
        }

        // Reveal — only after the full build
        DispatchQueue.main.asyncAfter(deadline: .now() + total) {
            viewModel.completeScan()
        }
    }
}

// MARK: - Rising energy particles (TimelineView + Canvas)

struct RisingParticles: View {
    private struct Particle {
        let x: Double        // 0...1
        let speed: Double    // screen-heights per second
        let size: Double
        let color: Color
        let phaseOffset: Double
    }

    private let particles: [Particle] = {
        let colors: [Color] = [AuraPalette.electricBlue, AuraPalette.lavender, AuraPalette.emerald, AuraPalette.gold, AuraPalette.rose]
        var result: [Particle] = []
        for i in 0..<22 {
            let x: Double = Double((i * 37) % 100) / 100.0
            let sp: Double = 0.12 + Double((i * 13) % 10) / 60.0
            let sz: Double = 3.0 + Double(i % 4)
            let c: Color = colors[i % colors.count]
            let ph: Double = Double((i * 29) % 100) / 100.0
            result.append(Particle(x: x, speed: sp, size: sz, color: c, phaseOffset: ph))
        }
        return result
    }()

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for p in particles {
                    let progress = ((t * p.speed) + p.phaseOffset).truncatingRemainder(dividingBy: 1)
                    let y = size.height * (1 - progress)
                    let opacity = progress < 0.15 ? progress / 0.15 : (1 - progress)
                    let rect = CGRect(
                        x: size.width * p.x, y: y,
                        width: p.size, height: p.size
                    )
                    var circle = context
                    circle.opacity = opacity * 0.9
                    circle.addFilter(.blur(radius: 0.5))
                    circle.fill(Path(ellipseIn: rect), with: .color(p.color))
                    circle.addFilter(.blur(radius: 4))
                    circle.fill(Path(ellipseIn: rect.insetBy(dx: -3, dy: -3)), with: .color(p.color.opacity(0.5)))
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

// MARK: - Expanding resonance ring

struct ExpandingRing: View {
    let delay: Double
    @State private var expanded = false

    var body: some View {
        Circle()
            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
            .frame(width: 200, height: 200)
            .scaleEffect(expanded ? 1.5 : 0.6)
            .opacity(expanded ? 0 : 0.8)
            .animation(
                .easeOut(duration: 3).repeatForever(autoreverses: false).delay(delay),
                value: expanded
            )
            .onAppear { expanded = true }
    }
}

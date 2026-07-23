//
//  InstructionsView.swift
//  Aura Energy Revealed
//
//  A visual "How to use Aura" guide, opened from Settings. Walks a new user
//  through every part of the app with an illustrative symbol per step.
//

import SwiftUI

struct InstructionsView: View {

    private struct Step: Identifiable {
        let id = UUID()
        let symbol: String
        let tint: Color
        let title: String
        let body: String
    }

    private let steps: [Step] = [
        Step(symbol: "camera.viewfinder", tint: AuraPalette.lavender,
             title: "1 · Scan your aura",
             body: "Open the Scan tab, centre your face in the framing ring and hold still for the ~7-second reading. No camera handy? Tap Upload to read any photo instead."),
        Step(symbol: "sparkles", tint: AuraPalette.electricBlue,
             title: "2 · See your reading",
             body: "Your real photo stays the hero, wrapped in your aura colour with chakra points glowing along your body's meridian."),
        Step(symbol: "chart.bar.doc.horizontal", tint: AuraPalette.emerald,
             title: "3 · Go deeper",
             body: "Open Details for your colour composition, the Body Map, and a Chakra balance view — each with its own meaning and a suggested practice."),
        Step(symbol: "leaf.fill", tint: AuraPalette.gold,
             title: "4 · Practice daily",
             body: "In Practice, meditate with guided 4-7-8 breathing (now with ambient sound and spoken cues), journal how your energy feels, and chat with the Aura Coach."),
        Step(symbol: "chart.line.uptrend.xyaxis", tint: AuraPalette.rose,
             title: "5 · Track your journey",
             body: "The You tab keeps your streak, full history, and an energy-over-time chart so you can watch your patterns unfold."),
        Step(symbol: "star.circle.fill", tint: AuraPalette.lavender,
             title: "6 · Aura+",
             body: "Your first scan is free. Aura+ unlocks unlimited scans, full history, the Body Map, the Coach, and premium meditations."),
    ]

    var body: some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AuraOrbView(style: .brand, size: 88)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 28)

                    Text("How to use Aura")
                        .font(AuraFont.display(28, relativeTo: .title))
                        .foregroundStyle(AuraPalette.ink)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

                    Text("A gentle mirror for your energy — here's the whole flow in six steps.")
                        .font(AuraFont.text(13, weight: .light))
                        .foregroundStyle(AuraPalette.inkDim)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 4)

                    ForEach(steps) { step in
                        GlassCard(padding: 16) {
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: step.symbol)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(step.tint)
                                    .frame(width: 46, height: 46)
                                    .background(step.tint.opacity(0.14), in: Circle())
                                    .overlay(Circle().strokeBorder(step.tint.opacity(0.35), lineWidth: 1))
                                    .shadow(color: step.tint.opacity(0.4), radius: 10)

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(step.title)
                                        .font(AuraFont.text(14.5, weight: .semibold))
                                        .foregroundStyle(AuraPalette.ink)
                                    Text(step.body)
                                        .font(AuraFont.text(12.5, weight: .light))
                                        .foregroundStyle(AuraPalette.ink.opacity(0.82))
                                        .lineSpacing(4)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    GlassCard(padding: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            MonoLabel(text: "A note", color: AuraPalette.emerald)
                            Text("Aura readings are generated interpretations meant for reflection — not measurements or medical advice. Everything is analysed on your device and stays private.")
                                .font(AuraFont.text(12.5, weight: .light))
                                .foregroundStyle(AuraPalette.ink.opacity(0.82))
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, AuraSpacing.gutter)
                .padding(.bottom, 34)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDragIndicator(.visible)
    }
}

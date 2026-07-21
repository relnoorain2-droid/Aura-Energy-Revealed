//
//  CoachView.swift
//  Aura Energy Revealed
//
//  Screen 16 — the AI wellness coach. Warm, encouraging, never medical.
//  On-device scripted guidance today; the CoachResponding seam is ready
//  for a cloud AI API later. Aura+ core feature; free gets a daily teaser.
//

import SwiftUI
import SwiftData

protocol CoachResponding {
    func reply(to message: String, todaysAura: AuraHue?, intentions: [String]) -> String
}

struct LocalCoach: CoachResponding {
    func reply(to message: String, todaysAura: AuraHue?, intentions: [String]) -> String {
        let lower = message.lowercased()
        if lower.contains("scatter") || lower.contains("anx") || lower.contains("stress") {
            return "Let's try a 5-minute grounding breath together. Inhale for 4, hold for 7, out for 8 — I'll be right here. 🌙"
        }
        if lower.contains("tired") || lower.contains("exhaust") || lower.contains("drained") {
            return "Rest is a practice too. Would a short body-scan help you put the day down gently?"
        }
        if lower.contains("happy") || lower.contains("good") || lower.contains("great") {
            return "Beautiful. Take ten seconds to really feel that — naming a good moment helps it stay."
        }
        if lower.contains("sad") || lower.contains("down") || lower.contains("low") {
            return "Thank you for telling me. Low days are part of a full life. A slow walk or the Heart Opening practice can be a soft next step — and talking with someone you trust always helps."
        }
        if let aura = todaysAura {
            return "Your \(aura.displayName.lowercased()) reading suggests \(aura.essence.lowercased()). Want a short practice matched to that energy?"
        }
        if let intention = intentions.first {
            return "You set an intention of \(intention.lowercased()) — how has that been showing up for you today?"
        }
        return "I'm here. Tell me how your energy feels right now, and we'll find a small practice to match it."
    }
}

private struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct CoachView: View {
    @Environment(StoreService.self) private var store
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \AuraReading.date, order: .reverse) private var readings: [AuraReading]

    @State private var messages: [ChatMessage] = []
    @State private var draft = ""
    @State private var freeMessagesUsed = 0
    @FocusState private var inputFocused: Bool

    private let coach: CoachResponding = LocalCoach()

    private var todaysAura: AuraHue? {
        readings.first { Calendar.current.isDateInToday($0.date) }?.dominant
    }

    var body: some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()
            RadialBloom(color: AuraPalette.auroraPurpleDeep, center: .init(x: 0.2, y: 0), opacity: 0.22)

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 10) {
                    AuraOrbView(style: .brand, size: 34)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Aura Coach")
                            .font(AuraFont.text(14, weight: .semibold))
                            .foregroundStyle(AuraPalette.ink)
                        HStack(spacing: 4) {
                            Circle().fill(AuraPalette.emerald).frame(width: 5, height: 5)
                            Text("ONLINE")
                                .font(AuraFont.mono(8))
                                .foregroundStyle(AuraPalette.emerald)
                        }
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13))
                            .foregroundStyle(AuraPalette.ink.opacity(0.6))
                    }
                }
                .padding(.horizontal, AuraSpacing.gutter)
                .padding(.vertical, 14)

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(messages) { message in
                                bubble(message)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, AuraSpacing.gutter)
                        .padding(.bottom, 10)
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: messages.count) {
                        if let last = messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                // Input / gate
                if store.isSubscribed || freeMessagesUsed < 1 {
                    inputBar
                } else {
                    upgradeBar
                }
            }
        }
        .onAppear {
            if messages.isEmpty {
                let opener = todaysAura.map {
                    "Your \($0.displayName.lowercased()) reading suggests a \(quality(for: $0)) day. Want a short practice to match it?"
                } ?? "Welcome. I read your auras, journal, and streak to suggest small practices. How does your energy feel right now?"
                messages.append(ChatMessage(text: opener, isUser: false))
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func quality(for hue: AuraHue) -> String {
        switch hue {
        case .violet, .purple, .indigo: "reflective"
        case .blue, .white, .silver: "calm"
        case .green, .pink: "open-hearted"
        case .gold, .rainbow: "bright"
        case .red: "energised"
        }
    }

    private func bubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.isUser { Spacer(minLength: 50) }
            Text(message.text)
                .font(AuraFont.text(13))
                .foregroundStyle(.white)
                .lineSpacing(3)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background {
                    if message.isUser {
                        UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 4, topTrailingRadius: 16)
                            .fill(AuraPalette.primaryGradient)
                    } else {
                        UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 4, bottomTrailingRadius: 16, topTrailingRadius: 16)
                            .fill(.white.opacity(0.06))
                        UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 4, bottomTrailingRadius: 16, topTrailingRadius: 16)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                    }
                }
            if !message.isUser { Spacer(minLength: 50) }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Ask anything…", text: $draft)
                .focused($inputFocused)
                .font(AuraFont.text(13))
                .foregroundStyle(AuraPalette.ink)
                .padding(.horizontal, 14)
                .frame(height: 40)
                .background {
                    Capsule().fill(.white.opacity(0.06))
                    Capsule().strokeBorder(.white.opacity(0.1), lineWidth: 1)
                }

            Button {
                send()
            } label: {
                Circle()
                    .fill(AuraPalette.primaryGradient)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                    }
            }
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, AuraSpacing.gutter)
        .padding(.vertical, 12)
    }

    private var upgradeBar: some View {
        Button {
            dismiss()
            appState.isPaywallPresented = true
        } label: {
            GlassCard(padding: 14, tint: AuraPalette.gold) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(AuraPalette.gold)
                    Text("Continue the conversation with Aura+")
                        .font(AuraFont.text(13, weight: .semibold))
                        .foregroundStyle(AuraPalette.ink)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(AuraPalette.inkGhost)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AuraSpacing.gutter)
        .padding(.vertical, 12)
    }

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        draft = ""
        messages.append(ChatMessage(text: text, isUser: true))
        if !store.isSubscribed { freeMessagesUsed += 1 }

        // Streamed-feel delay for the reply
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            let reply = coach.reply(to: text, todaysAura: todaysAura, intentions: appState.intentions)
            messages.append(ChatMessage(text: reply, isUser: false))
        }
    }
}

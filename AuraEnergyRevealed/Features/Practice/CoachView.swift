//
//  CoachView.swift
//  Auralis
//
//  Screen 16 — the Aura Coach.
//
//  Replies come from CoachService, which talks to our relay when it can and
//  answers on-device when it can't. CoachService never throws, so this view has
//  no error state to render: a reply always arrives.
//
//  Conversations are metered by CoachQuota. When someone runs out, they are
//  offered more through StoreKit only — never an external payment link
//  (App Store Review Guideline 3.1.1).
//

import SwiftUI
import SwiftData

private struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct CoachView: View {
    @Environment(StoreService.self) private var store
    @Environment(AppState.self) private var appState
    @Environment(CoachQuota.self) private var quota
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \AuraReading.date, order: .reverse) private var readings: [AuraReading]
    @Query(sort: \JournalEntry.date, order: .reverse) private var journal: [JournalEntry]

    @State private var messages: [ChatMessage] = []
    @State private var draft = ""
    @State private var isThinking = false
    @FocusState private var inputFocused: Bool

    private let coach = CoachService()

    private var todaysAura: AuraHue? {
        readings.first { Calendar.current.isDateInToday($0.date) }?.dominant
    }

    private var canSend: Bool { quota.canSend(isSubscribed: store.isSubscribed) }

    var body: some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()
            RadialBloom(color: AuraPalette.auroraPurpleDeep, center: .init(x: 0.2, y: 0), opacity: 0.22)

            VStack(spacing: 0) {
                header

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(messages) { message in
                                bubble(message).id(message.id)
                            }
                            if isThinking {
                                TypingBubble().id("typing")
                            }
                        }
                        .padding(.horizontal, AuraSpacing.gutter)
                        .padding(.bottom, 10)
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: messages.count) { scrollToEnd(proxy) }
                    .onChange(of: isThinking) { scrollToEnd(proxy) }
                }

                if canSend {
                    inputBar
                } else if !store.isSubscribed {
                    upgradeBar
                } else {
                    topUpBar
                }
            }
        }
        .onAppear(perform: seedOpeningMessage)
        .presentationDragIndicator(.visible)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            AuraOrbView(style: .brand, size: 34)
            VStack(alignment: .leading, spacing: 0) {
                Text("Aura Coach")
                    .font(AuraFont.text(14, weight: .semibold))
                    .foregroundStyle(AuraPalette.ink)
                Text(remainingLabel)
                    .font(AuraFont.mono(8))
                    .foregroundStyle(AuraPalette.inkGhost)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13))
                    .foregroundStyle(AuraPalette.ink.opacity(0.6))
            }
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, AuraSpacing.gutter)
        .padding(.vertical, 14)
    }

    private var remainingLabel: String {
        let left = quota.remainingTotal(isSubscribed: store.isSubscribed)
        if left <= 0 { return "NO CONVERSATIONS LEFT" }
        if left > 99 { return "READY" }
        return "\(left) CONVERSATION\(left == 1 ? "" : "S") LEFT"
    }

    // MARK: Bubbles

    private func bubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.isUser { Spacer(minLength: 50) }
            Text(message.text)
                .font(AuraFont.text(13))
                .foregroundStyle(.white)
                .lineSpacing(3)
                .textSelection(.enabled)
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

    // MARK: Input & gates

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Ask anything…", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .focused($inputFocused)
                .font(AuraFont.text(13))
                .foregroundStyle(AuraPalette.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.06))
                    RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.1), lineWidth: 1)
                }
                .disabled(isThinking)
                .onSubmit(send)

            Button(action: send) {
                Circle()
                    .fill(AuraPalette.primaryGradient)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .opacity(sendEnabled ? 1 : 0.4)
            }
            .disabled(!sendEnabled)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, AuraSpacing.gutter)
        .padding(.vertical, 12)
    }

    private var sendEnabled: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isThinking
    }

    /// Free tier exhausted — subscribing is the better value, so lead with that.
    private var upgradeBar: some View {
        Button {
            dismiss()
            appState.isPaywallPresented = true
        } label: {
            GlassCard(padding: 14, tint: AuraPalette.gold) {
                HStack {
                    Image(systemName: "sparkles").foregroundStyle(AuraPalette.gold)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Continue with Aura+")
                            .font(AuraFont.text(13, weight: .semibold))
                            .foregroundStyle(AuraPalette.ink)
                        Text("Includes \(CoachQuota.subscriberWeeklyMessages) conversations a week")
                            .font(AuraFont.text(11))
                            .foregroundStyle(AuraPalette.inkGhost)
                    }
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

    /// Subscriber who used the whole weekly allowance — offer a top-up via Apple.
    private var topUpBar: some View {
        VStack(spacing: 8) {
            Button {
                Task { await store.purchaseCoachTopUp() }
            } label: {
                GlassCard(padding: 14, tint: AuraPalette.gold) {
                    HStack {
                        Image(systemName: "bubble.left.and.text.bubble.right")
                            .foregroundStyle(AuraPalette.gold)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(CoachTopUp.title) · \(store.topUpDisplayPrice)")
                                .font(AuraFont.text(13, weight: .semibold))
                                .foregroundStyle(AuraPalette.ink)
                            Text(CoachTopUp.blurb)
                                .font(AuraFont.text(11))
                                .foregroundStyle(AuraPalette.inkGhost)
                        }
                        Spacer()
                        if store.purchaseInFlight {
                            ProgressView().tint(AuraPalette.gold)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(AuraPalette.inkGhost)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(store.purchaseInFlight)

            Text(quota.renewalDescription(isSubscribed: store.isSubscribed))
                .font(AuraFont.text(10))
                .foregroundStyle(AuraPalette.inkGhost)
        }
        .padding(.horizontal, AuraSpacing.gutter)
        .padding(.vertical, 12)
    }

    // MARK: Behaviour

    private func scrollToEnd(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) {
            if isThinking {
                proxy.scrollTo("typing", anchor: .bottom)
            } else if let last = messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    private func seedOpeningMessage() {
        guard messages.isEmpty else { return }
        let opener = todaysAura.map {
            "Your \($0.displayName.lowercased()) reading points toward \($0.essence.lowercased()). How does that sit with how you actually feel today?"
        } ?? "Welcome. I read your aura history, journal and streak to suggest small practices. How does your energy feel right now?"
        messages.append(ChatMessage(text: opener, isUser: false))
    }

    private func buildContext() -> CoachContext {
        var context = CoachContext()
        context.userName = appState.userName
        context.todaysAura = todaysAura
        context.recentAuras = Array(readings.prefix(5).map(\.dominant))
        context.intentions = appState.intentions
        context.recentMoods = Array(journal.prefix(5).flatMap(\.moods).prefix(6))
        context.streakDays = currentStreak
        return context
    }

    /// Consecutive days with at least one reading, counting back from today.
    private var currentStreak: Int {
        let calendar = Calendar.current
        let days = Set(readings.map { calendar.startOfDay(for: $0.date) })
        guard !days.isEmpty else { return 0 }
        var streak = 0
        var cursor = calendar.startOfDay(for: .now)
        if !days.contains(cursor) {
            guard let back = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = back
        }
        while days.contains(cursor) {
            streak += 1
            guard let back = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = back
        }
        return streak
    }

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isThinking, canSend else { return }

        draft = ""
        messages.append(ChatMessage(text: text, isUser: true))
        quota.consume(isSubscribed: store.isSubscribed)
        isThinking = true

        let history = messages.map { CoachTurn(text: $0.text, isUser: $0.isUser) }
        let context = buildContext()

        Task {
            // CoachService handles relay failure, quota exhaustion and offline
            // internally, so a usable reply always comes back.
            let reply = await coach.reply(to: text, history: history, context: context)
            await MainActor.run {
                isThinking = false
                messages.append(ChatMessage(text: reply, isUser: false))
                Haptics.impactSoft()
            }
        }
    }
}

// MARK: - Typing indicator

private struct TypingBubble: View {
    @State private var phase = 0.0

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(.white.opacity(0.55))
                        .frame(width: 6, height: 6)
                        .scaleEffect(scale(for: index))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 4, bottomTrailingRadius: 16, topTrailingRadius: 16)
                    .fill(.white.opacity(0.06))
            }
            Spacer(minLength: 50)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
        .accessibilityLabel("Aura Coach is typing")
    }

    private func scale(for index: Int) -> Double {
        let offset = Double(index) * 0.18
        return 0.7 + 0.5 * abs(sin((phase + offset) * .pi))
    }
}

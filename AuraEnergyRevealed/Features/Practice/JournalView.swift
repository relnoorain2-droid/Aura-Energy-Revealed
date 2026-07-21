//
//  JournalView.swift
//  Aura Energy Revealed
//
//  Screen 15 — aura-linked prompt → free text → mood chips → auto-saved.
//  Free keeps the last 7 days; Aura+ is unlimited.
//

import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreService.self) private var store
    @Environment(AppState.self) private var appState

    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \AuraReading.date, order: .reverse) private var readings: [AuraReading]

    @State private var text = ""
    @State private var selectedMoods: Set<String> = []
    @FocusState private var editorFocused: Bool

    private let moods = ["😌 Calm", "🌙 Reflective", "✨ Inspired", "🌊 Heavy", "☀️ Bright"]

    private let prompts = [
        "Where did you feel most at peace today?",
        "What drained your energy — and what restored it?",
        "What is one thing your quieter self knows?",
        "Who made your day lighter, and how?",
        "What would you like tomorrow's energy to feel like?",
        "What did you notice today that you usually rush past?",
    ]

    private var todaysPrompt: String {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        return prompts[day % prompts.count]
    }

    private var todaysAura: AuraHue? {
        readings.first { Calendar.current.isDateInToday($0.date) }?.dominant
    }

    private var todaysEntry: JournalEntry? {
        entries.first { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Daily Journal")
                        .font(AuraFont.display(26, relativeTo: .title))
                        .foregroundStyle(AuraPalette.ink)
                        .padding(.top, 22)

                    Text(Date.now.formatted(.dateTime.weekday(.wide)) + (todaysAura.map { " · \($0.displayName.lowercased()) aura" } ?? ""))
                        .font(AuraFont.text(11.5, weight: .light))
                        .foregroundStyle(AuraPalette.inkDim)

                    GlassCard(padding: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            MonoLabel(text: "Today's Prompt", color: AuraPalette.lavender)
                            Text(todaysPrompt)
                                .font(AuraFont.text(14, weight: .light))
                                .foregroundStyle(AuraPalette.ink.opacity(0.9))
                        }
                    }

                    GlassCard(padding: 16) {
                        TextEditor(text: $text)
                            .focused($editorFocused)
                            .font(AuraFont.text(13.5, weight: .light))
                            .foregroundStyle(AuraPalette.ink.opacity(0.85))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 130)
                            .accessibilityLabel("Journal entry")
                    }

                    HStack(spacing: 8) {
                        ForEach(moods, id: \.self) { mood in
                            let isOn = selectedMoods.contains(mood)
                            Button {
                                Haptics.selection()
                                if isOn { selectedMoods.remove(mood) } else { selectedMoods.insert(mood) }
                            } label: {
                                AuraChip(label: mood, emphasized: isOn)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    PrimaryButton(title: "Save reflection") {
                        save()
                    }
                    .padding(.top, 6)

                    if !pastEntries.isEmpty {
                        MonoLabel(text: "Past Reflections")
                            .padding(.top, 10)
                        ForEach(pastEntries) { entry in
                            GlassCard(padding: 14) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.date, format: .dateTime.weekday(.wide).month().day())
                                        .font(AuraFont.mono(9))
                                        .foregroundStyle(AuraPalette.inkGhost)
                                    Text(entry.text.isEmpty ? entry.prompt : entry.text)
                                        .font(AuraFont.text(12.5, weight: .light))
                                        .foregroundStyle(AuraPalette.ink.opacity(0.8))
                                        .lineLimit(3)
                                }
                            }
                        }
                        if !store.isSubscribed && entries.count > pastEntries.count + 1 {
                            Button {
                                dismiss()
                                appState.isPaywallPresented = true
                            } label: {
                                AuraChip(label: "✦ Older entries · Aura+", dotColor: AuraPalette.gold)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, AuraSpacing.gutter)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            if let existing = todaysEntry {
                text = existing.text
                selectedMoods = Set(existing.moods)
            }
        }
        .presentationDragIndicator(.visible)
    }

    /// Free tier: entries from the last 7 days (excluding today's editor).
    private var pastEntries: [JournalEntry] {
        let past = entries.filter { !Calendar.current.isDateInToday($0.date) }
        if store.isSubscribed { return Array(past.prefix(30)) }
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return past.filter { $0.date >= cutoff }
    }

    private func save() {
        if let existing = todaysEntry {
            existing.text = text
            existing.moods = Array(selectedMoods)
        } else {
            let entry = JournalEntry(
                prompt: todaysPrompt,
                text: text,
                moods: Array(selectedMoods),
                aura: todaysAura
            )
            modelContext.insert(entry)
        }
        try? modelContext.save()
        Haptics.success()
        dismiss()
    }
}

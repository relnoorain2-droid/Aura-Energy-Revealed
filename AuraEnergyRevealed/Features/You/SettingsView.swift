//
//  SettingsView.swift
//  Aura Energy Revealed
//
//  Screen 20 — the settings suite. Grouped, calm, privacy-forward.
//  Includes the ethics statement: interpretations, not measurements.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(StoreService.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @AppStorage("dailyNudgeEnabled") private var dailyNudgeEnabled = true
    @AppStorage("dailyNudgeHour") private var dailyNudgeHour = 9
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    @State private var showAbout = false
    @State private var confirmDelete = false

    var body: some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Settings")
                        .font(AuraFont.display(26, relativeTo: .title))
                        .foregroundStyle(AuraPalette.ink)
                        .padding(.top, 22)

                    // Notifications
                    settingsGroup(title: "🔔 Notifications") {
                        Toggle(isOn: $dailyNudgeEnabled) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Daily reflection nudge")
                                    .font(AuraFont.text(13.5, weight: .medium))
                                    .foregroundStyle(AuraPalette.ink)
                                Text("A gentle reminder, once a day")
                                    .font(AuraFont.text(11, weight: .light))
                                    .foregroundStyle(AuraPalette.inkDim)
                            }
                        }
                        .tint(AuraPalette.emerald)
                        .onChange(of: dailyNudgeEnabled) { _, enabled in
                            if enabled {
                                NotificationService.scheduleDailyReflection(hour: dailyNudgeHour, minute: 0)
                            } else {
                                NotificationService.cancelDailyReflection()
                            }
                        }

                        if dailyNudgeEnabled {
                            Picker("Time", selection: $dailyNudgeHour) {
                                ForEach([7, 8, 9, 12, 18, 20, 21], id: \.self) { hour in
                                    Text("\(hour):00").tag(hour)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(AuraPalette.electricBlue)
                            .onChange(of: dailyNudgeHour) { _, hour in
                                NotificationService.scheduleDailyReflection(hour: hour, minute: 0)
                            }
                        }
                    }

                    // Experience
                    settingsGroup(title: "✨ Experience") {
                        Toggle(isOn: $hapticsEnabled) {
                            Text("Haptics")
                                .font(AuraFont.text(13.5, weight: .medium))
                                .foregroundStyle(AuraPalette.ink)
                        }
                        .tint(AuraPalette.emerald)

                        Text("Reduce Motion and Reduce Transparency follow your iOS accessibility settings automatically.")
                            .font(AuraFont.text(11, weight: .light))
                            .foregroundStyle(AuraPalette.inkFaint)
                    }

                    // Privacy
                    settingsGroup(title: "🔒 Privacy & Data") {
                        Text("Photos are analysed on your device. Readings are stored locally and never leave your iPhone without your consent.")
                            .font(AuraFont.text(12, weight: .light))
                            .foregroundStyle(AuraPalette.inkDim)

                        Button(role: .destructive) {
                            confirmDelete = true
                        } label: {
                            Text("Delete all readings & journal")
                                .font(AuraFont.text(13, weight: .medium))
                                .foregroundStyle(AuraPalette.rose)
                        }
                    }

                    // Subscription
                    settingsGroup(title: "✦ Aura+") {
                        Text(store.isSubscribed ? "You're an Aura+ member. Thank you for supporting the practice." : "Free plan · 1 complimentary scan")
                            .font(AuraFont.text(12.5, weight: .light))
                            .foregroundStyle(AuraPalette.inkDim)
                        Button("Restore purchase") {
                            Task { await store.restorePurchases() }
                        }
                        .font(AuraFont.text(13, weight: .medium))
                        .foregroundStyle(AuraPalette.electricBlue)
                    }

                    // About
                    settingsGroup(title: "✦ About") {
                        Button {
                            showAbout = true
                        } label: {
                            HStack {
                                Text("Our ethics & how readings work")
                                    .font(AuraFont.text(13, weight: .medium))
                                    .foregroundStyle(AuraPalette.ink)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AuraPalette.inkGhost)
                            }
                        }
                        MonoLabel(text: "Version 1.0 · Made with intention", size: 9)
                    }
                }
                .padding(.horizontal, AuraSpacing.gutter)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $showAbout) { aboutSheet }
        .confirmationDialog("Delete everything?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete all data", role: .destructive) { deleteAll() }
            Button("Keep my journey", role: .cancel) {}
        } message: {
            Text("This removes every reading and journal entry from this device. There's no undo.")
        }
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func settingsGroup(title: String, @ViewBuilder content: () -> some View) -> some View {
        GlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(AuraFont.text(14, weight: .semibold))
                    .foregroundStyle(AuraPalette.ink)
                content()
            }
        }
    }

    private var aboutSheet: some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AuraOrbView(style: .brand, size: 90)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 30)

                    Text("Designed to be felt")
                        .font(AuraFont.display(28, relativeTo: .title))
                        .foregroundStyle(AuraPalette.ink)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

                    GlassCard(padding: 18) {
                        VStack(alignment: .leading, spacing: 10) {
                            MonoLabel(text: "Our Ethics", color: AuraPalette.emerald)
                            Text("Aura readings are generated interpretations, not sensor measurements or diagnoses. They're a reflective wellness practice inspired by spiritual traditions — a mirror for your own awareness, interpreted gently by AI.")
                                .font(AuraFont.text(13.5, weight: .light))
                                .foregroundStyle(AuraPalette.ink.opacity(0.85))
                                .lineSpacing(5)
                            Text("Nothing here is medical advice. If something in your life feels heavy, a trusted person or professional is always the right next step.")
                                .font(AuraFont.text(13.5, weight: .light))
                                .foregroundStyle(AuraPalette.ink.opacity(0.85))
                                .lineSpacing(5)
                        }
                    }

                    GlassCard(padding: 18) {
                        VStack(alignment: .leading, spacing: 10) {
                            MonoLabel(text: "Privacy", color: AuraPalette.electricBlue)
                            Text("Scans run on your device using Apple's Vision framework. Your photos and readings stay on your iPhone.")
                                .font(AuraFont.text(13.5, weight: .light))
                                .foregroundStyle(AuraPalette.ink.opacity(0.85))
                                .lineSpacing(5)
                        }
                    }
                }
                .padding(.horizontal, AuraSpacing.gutter)
                .padding(.bottom, 30)
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func deleteAll() {
        try? modelContext.delete(model: AuraReading.self)
        try? modelContext.delete(model: JournalEntry.self)
        try? modelContext.save()
        Haptics.warning()
    }
}

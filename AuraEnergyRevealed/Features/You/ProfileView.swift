//
//  ProfileView.swift
//  Aura Energy Revealed
//
//  Screen 18 — aura avatar + name + membership badge → stat tiles →
//  grouped links to milestones, goals, history, settings.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreService.self) private var store
    @Query(sort: \AuraReading.date, order: .reverse) private var readings: [AuraReading]

    @State private var showHistory = false
    @State private var showMilestones = false
    @State private var showSettings = false
    @State private var editingName = false
    @State private var nameDraft = ""

    private var streak: Int {
        StreakService.currentStreak(readingDates: readings.map(\.date))
    }

    private var unlockedBadges: Int {
        Badge.all.filter { $0.isUnlocked(readings, streak) }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Identity
                VStack(spacing: 10) {
                    AuraOrbView(
                        style: readings.first?.dominant.orbStyle ?? .brand,
                        size: 88
                    )
                    Button {
                        nameDraft = appState.userName
                        editingName = true
                    } label: {
                        Text(appState.userName.isEmpty ? "Add your name" : appState.userName)
                            .font(AuraFont.display(24, relativeTo: .title))
                            .foregroundStyle(AuraPalette.ink)
                    }
                    .buttonStyle(.plain)

                    if store.isSubscribed {
                        AuraChip(label: "✦ Aura+ member", dotColor: AuraPalette.gold, emphasized: true)
                    } else {
                        Button {
                            appState.isPaywallPresented = true
                        } label: {
                            AuraChip(label: "Upgrade to Aura+", dotColor: AuraPalette.gold)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 16)
                .riseFadeIn(index: 0)

                // Stats
                HStack(spacing: 10) {
                    statTile(value: "\(streak)", label: "Day Streak", color: AuraPalette.gold)
                    statTile(value: "\(readings.count)", label: "Readings", color: AuraPalette.electricBlue)
                    statTile(value: "\(unlockedBadges)", label: "Badges", color: AuraPalette.emerald)
                }
                .riseFadeIn(index: 1)

                // Links
                VStack(spacing: 8) {
                    linkRow(emoji: "🕰️", title: "Your Journey", subtitle: "\(readings.count) readings") { showHistory = true }
                    linkRow(emoji: "🏆", title: "Milestones & Badges", subtitle: "\(unlockedBadges) of \(Badge.all.count) unlocked") { showMilestones = true }
                    linkRow(emoji: "⚙️", title: "Settings", subtitle: "Notifications · privacy · about") { showSettings = true }
                }
                .riseFadeIn(index: 2)
            }
            .padding(.horizontal, AuraSpacing.gutter)
            .padding(.bottom, 130)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showHistory) { HistoryView() }
        .sheet(isPresented: $showMilestones) { MilestonesView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .alert("Your name", isPresented: $editingName) {
            TextField("Name", text: $nameDraft)
            Button("Save") { appState.userName = nameDraft }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Used for your daily greeting.")
        }
    }

    private func statTile(value: String, label: String, color: Color) -> some View {
        GlassCard(padding: 14) {
            VStack(spacing: 4) {
                Text(value)
                    .font(AuraFont.display(24, relativeTo: .title2))
                    .foregroundStyle(color)
                MonoLabel(text: label, size: 9)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func linkRow(emoji: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            GlassCard(padding: 15) {
                HStack(spacing: 12) {
                    Text(emoji).font(.system(size: 18))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(title)
                            .font(AuraFont.text(13.5, weight: .semibold))
                            .foregroundStyle(AuraPalette.ink)
                        Text(subtitle)
                            .font(AuraFont.text(11, weight: .light))
                            .foregroundStyle(AuraPalette.inkDim)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(AuraPalette.inkGhost)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Milestones & badges (gamification section)

struct MilestonesView: View {
    @Query(sort: \AuraReading.date, order: .reverse) private var readings: [AuraReading]

    private var streak: Int {
        StreakService.currentStreak(readingDates: readings.map(\.date))
    }

    var body: some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Milestones")
                        .font(AuraFont.display(26, relativeTo: .title))
                        .foregroundStyle(AuraPalette.ink)
                        .padding(.top, 22)

                    // Streak card — forgiving, never shaming
                    GlassCard(padding: 22) {
                        VStack(alignment: .leading, spacing: 14) {
                            MonoLabel(text: "Daily Streak", color: AuraPalette.gold)
                            HStack(spacing: 14) {
                                Text("🔥").font(.system(size: 40))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(streak) days")
                                        .font(AuraFont.display(34, relativeTo: .largeTitle))
                                        .foregroundStyle(AuraPalette.ink)
                                    Text(streak > 0 ? "Glowing bright" : "Your journey is just beginning")
                                        .font(AuraFont.text(12, weight: .light))
                                        .foregroundStyle(AuraPalette.inkDim)
                                }
                            }
                            weekRow
                            Text("One grace day a week keeps your streak alive — this space never shames a missed day.")
                                .font(AuraFont.text(12, weight: .light))
                                .foregroundStyle(AuraPalette.inkFaint)
                        }
                    }
                    .riseFadeIn(index: 0)

                    MonoLabel(text: "Wellness Milestones & Badges")

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                        ForEach(Array(Badge.all.enumerated()), id: \.element.id) { i, badge in
                            let unlocked = badge.isUnlocked(readings, streak)
                            GlassCard(padding: 16) {
                                VStack(spacing: 6) {
                                    Text(badge.emoji).font(.system(size: 28))
                                    Text(badge.name)
                                        .font(AuraFont.text(12, weight: .semibold))
                                        .foregroundStyle(AuraPalette.ink)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Text(unlocked ? badge.caption : "Locked")
                                        .font(AuraFont.text(9.5, weight: .light))
                                        .foregroundStyle(AuraPalette.inkDim)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .opacity(unlocked ? 1 : 0.45)
                            .riseFadeIn(index: i + 1)
                        }
                    }
                }
                .padding(.horizontal, AuraSpacing.gutter)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDragIndicator(.visible)
    }

    private var weekRow: some View {
        let calendar = Calendar.current
        let days = Set(readings.map { calendar.startOfDay(for: $0.date) })
        let gradients: [[Color]] = [
            [AuraPalette.gold, AuraPalette.rose],
            [AuraPalette.lavender, AuraPalette.electricBlue],
            [AuraPalette.emerald, AuraPalette.electricBlue],
            [AuraPalette.rose, AuraPalette.lavender],
            [AuraPalette.gold, AuraPalette.emerald],
            [AuraPalette.electricBlue, AuraPalette.lavender],
            [AuraPalette.emerald, AuraPalette.gold],
        ]
        return HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { offset in
                let day = calendar.date(byAdding: .day, value: offset - 6, to: calendar.startOfDay(for: .now))!
                let hasReading = days.contains(day)
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        hasReading
                            ? AnyShapeStyle(LinearGradient(colors: gradients[offset], startPoint: .topLeading, endPoint: .bottomTrailing))
                            : AnyShapeStyle(Color.white.opacity(0.08))
                    )
                    .frame(height: 34)
                    .overlay {
                        if !hasReading {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(.white.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [3]))
                        }
                    }
            }
        }
    }
}

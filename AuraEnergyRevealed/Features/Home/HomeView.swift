//
//  HomeView.swift
//  Aura Energy Revealed
//
//  Screen 05 — a calm daily landing, not a feed.
//  Greeting + streak → Today's Aura hero → Daily Insight → quick actions
//  → recent readings rail. Cards rise-fade with a 40ms stagger.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreService.self) private var store
    @Query(sort: \AuraReading.date, order: .reverse) private var readings: [AuraReading]

    @State private var presentedReading: AuraReading?
    @State private var showJournal = false
    @State private var showMeditations = false

    private var todaysReading: AuraReading? {
        readings.first { Calendar.current.isDateInToday($0.date) }
    }

    private var streak: Int {
        StreakService.currentStreak(readingDates: readings.map(\.date))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                    .riseFadeIn(index: 0)

                heroCard
                    .riseFadeIn(index: 1)

                insightCard
                    .riseFadeIn(index: 2)

                quickActions
                    .riseFadeIn(index: 3)

                recentRail
                    .riseFadeIn(index: 4)
            }
            .padding(.horizontal, AuraSpacing.gutter)
            .padding(.top, 8)
            .padding(.bottom, 130)
        }
        .scrollIndicators(.hidden)
        .refreshable {
            // Pull-to-refresh renews the daily insight display.
        }
        .sheet(item: $presentedReading) { reading in
            ResultView(reading: reading, isNewReading: false)
        }
        .sheet(isPresented: $showJournal) { JournalView() }
        .sheet(isPresented: $showMeditations) { MeditationLibraryView() }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(appState.greeting)
                    .font(AuraFont.text(12, weight: .light))
                    .foregroundStyle(AuraPalette.inkDim)
                Text(appState.userName.isEmpty ? "Wanderer" : appState.userName)
                    .font(AuraFont.display(26, relativeTo: .title))
                    .foregroundStyle(AuraPalette.ink)
            }
            Spacer()
            AuraChip(label: "🔥 \(streak)")
                .accessibilityLabel("\(streak) day streak")
        }
    }

    // MARK: Today's Aura hero

    @ViewBuilder
    private var heroCard: some View {
        if let reading = todaysReading {
            Button {
                presentedReading = reading
            } label: {
                GlassCard {
                    ZStack(alignment: .topTrailing) {
                        AuraOrbView(style: reading.dominant.orbStyle, size: 130)
                            .opacity(0.85)
                            .offset(x: 30, y: -16)

                        VStack(alignment: .leading, spacing: 0) {
                            MonoLabel(text: "Today's Aura")
                            Text(reading.dominant.displayName)
                                .font(AuraFont.display(30, relativeTo: .title))
                                .foregroundStyle(reading.dominant.titleColor)
                                .padding(.vertical, 4)
                            Text(reading.essence)
                                .font(AuraFont.text(12, weight: .light))
                                .foregroundStyle(AuraPalette.inkDim)
                                .frame(maxWidth: 180, alignment: .leading)
                            AuraChip(label: "View reading →")
                                .padding(.top, 14)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        } else {
            // Empty state: "Take your first reading" with a pulsing orb CTA.
            Button {
                appState.isScanFlowPresented = true
            } label: {
                GlassCard {
                    HStack(spacing: 18) {
                        AuraOrbView(style: .brand, size: 84)
                        VStack(alignment: .leading, spacing: 4) {
                            MonoLabel(text: "Today's Aura")
                            Text(readings.isEmpty ? "Take your first reading" : "Read today's aura")
                                .font(AuraFont.display(22, relativeTo: .title2))
                                .foregroundStyle(AuraPalette.ink)
                            Text("A quiet minute is all it takes.")
                                .font(AuraFont.text(12, weight: .light))
                                .foregroundStyle(AuraPalette.inkDim)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Daily insight

    private var insightCard: some View {
        GlassCard(padding: 18) {
            VStack(alignment: .leading, spacing: 8) {
                MonoLabel(text: "Daily Insight", color: AuraPalette.gold)
                Text("\u{201C}\(DailyInsight.today)\u{201D}")
                    .font(AuraFont.text(14, weight: .light))
                    .foregroundStyle(AuraPalette.ink.opacity(0.85))
                    .lineSpacing(4)
            }
        }
    }

    // MARK: Quick actions

    private var quickActions: some View {
        HStack(spacing: 12) {
            quickAction(emoji: "🌬️", label: "Breathe") { showMeditations = true }
            quickAction(emoji: "📖", label: "Journal") { showJournal = true }
            quickAction(emoji: "🧘", label: "Meditate") { showMeditations = true }
        }
    }

    private func quickAction(emoji: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            VStack(spacing: 6) {
                Text(emoji).font(.system(size: 20))
                Text(label)
                    .font(AuraFont.text(12, weight: .semibold))
                    .foregroundStyle(AuraPalette.ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: AuraRadius.card, style: .continuous)
                    .fill(.white.opacity(0.05))
                RoundedRectangle(cornerRadius: AuraRadius.card, style: .continuous)
                    .strokeBorder(.white.opacity(0.09), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Recent readings rail

    @ViewBuilder
    private var recentRail: some View {
        let visible = store.isSubscribed ? Array(readings.prefix(10)) : Array(readings.prefix(1))
        if !visible.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                MonoLabel(text: "Recent Readings")
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(visible) { reading in
                            Button {
                                presentedReading = reading
                            } label: {
                                recentTile(reading)
                            }
                            .buttonStyle(.plain)
                        }
                        if !store.isSubscribed && readings.count > 1 {
                            Button {
                                appState.isPaywallPresented = true
                            } label: {
                                lockedTile
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private func recentTile(_ reading: AuraReading) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text(reading.dominant.displayName)
                .font(AuraFont.text(12, weight: .semibold))
                .foregroundStyle(.white)
            Text(reading.date, format: .dateTime.weekday(.abbreviated).hour().minute())
                .font(AuraFont.mono(8))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(10)
        .frame(width: 108, height: 70, alignment: .bottomLeading)
        .background(
            LinearGradient(
                colors: [reading.dominant.orbStyle.colors.first ?? .purple,
                         reading.secondary.orbStyle.colors.first ?? .blue],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AuraRadius.button, style: .continuous))
    }

    private var lockedTile: some View {
        VStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .foregroundStyle(AuraPalette.gold)
            Text("Aura+")
                .font(AuraFont.text(11, weight: .semibold))
                .foregroundStyle(AuraPalette.ink.opacity(0.7))
        }
        .frame(width: 108, height: 70)
        .background {
            RoundedRectangle(cornerRadius: AuraRadius.button, style: .continuous)
                .fill(.white.opacity(0.05))
            RoundedRectangle(cornerRadius: AuraRadius.button, style: .continuous)
                .strokeBorder(.white.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [4]))
        }
    }
}

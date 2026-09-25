//
//  PracticeView.swift
//  Aura Energy Revealed
//
//  The Practice world: meditation library, daily journal, AI wellness
//  coach, and the gentle weekly-minutes goal ring.
//

import SwiftUI

struct PracticeView: View {
    @Environment(StoreService.self) private var store
    @State private var showJournal = false
    @State private var showCoach = false
    @State private var showLibrary = false
    @State private var showRitual = false
    @State private var showInsights = false

    @AppStorage("weeklyCalmMinutes") private var weeklyCalmMinutes = 70.0
    private let weeklyGoal = 100.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Practice")
                    .font(AuraFont.display(28, relativeTo: .largeTitle))
                    .foregroundStyle(AuraPalette.ink)
                    .padding(.top, 10)

                ritualCard
                    .riseFadeIn(index: 0)

                goalRing
                    .riseFadeIn(index: 1)

                MonoLabel(text: "Meditations for today")

                ForEach(Array(Meditation.library.prefix(3).enumerated()), id: \.element.id) { i, meditation in
                    NavigationLinkCard(meditation: meditation)
                        .riseFadeIn(index: i + 1)
                }

                Button { showLibrary = true } label: {
                    AuraChip(label: "Full library →")
                }
                .buttonStyle(.plain)

                MonoLabel(text: "Reflection")
                    .padding(.top, 8)

                practiceRow(emoji: "📖", title: "Daily Journal", subtitle: "Pair today's reading with a reflection") {
                    showJournal = true
                }
                .riseFadeIn(index: 4)

                practiceRow(emoji: "💬", title: "Aura Coach", subtitle: store.isSubscribed ? "Your warm conversational guide" : "A daily message · full chats with Aura+") {
                    showCoach = true
                }
                .riseFadeIn(index: 5)

                practiceRow(emoji: "📈", title: "Energy Insights", subtitle: "Patterns across your readings and practice") {
                    showInsights = true
                }
                .riseFadeIn(index: 6)
            }
            .padding(.horizontal, AuraSpacing.gutter)
            .padding(.bottom, 130)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showJournal) { JournalView() }
        .sheet(isPresented: $showCoach) { CoachView() }
        .sheet(isPresented: $showLibrary) { MeditationLibraryView() }
        .sheet(isPresented: $showRitual) { DailyRitualView() }
        .sheet(isPresented: $showInsights) { InsightsView() }
    }

    // MARK: Daily ritual

    private var ritualCard: some View {
        Button { showRitual = true } label: {
            GlassCard(padding: 20, tint: AuraPalette.auroraPurple) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TODAY'S RITUAL")
                            .font(AuraFont.mono(9))
                            .foregroundStyle(AuraPalette.inkGhost)
                        Text("Arrive, breathe, set an intention")
                            .font(AuraFont.display(19))
                            .foregroundStyle(AuraPalette.ink)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("A new four-part practice each day")
                            .font(AuraFont.text(12))
                            .foregroundStyle(AuraPalette.inkDim)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AuraPalette.ink)
                        .frame(width: 40, height: 40)
                        .background { Circle().fill(.white.opacity(0.1)) }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Weekly calm goal

    private var goalRing: some View {
        GlassCard(padding: 22) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.1), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: min(1, weeklyCalmMinutes / weeklyGoal))
                        .stroke(
                            AngularGradient(colors: [AuraPalette.emerald, AuraPalette.electricBlue, AuraPalette.emerald], center: .center),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(weeklyCalmMinutes / weeklyGoal * 100))%")
                        .font(AuraFont.text(17, weight: .bold))
                        .foregroundStyle(AuraPalette.ink)
                }
                .frame(width: 88, height: 88)

                VStack(alignment: .leading, spacing: 3) {
                    MonoLabel(text: "Meditation Goals", color: AuraPalette.emerald)
                    Text("Weekly calm")
                        .font(AuraFont.text(15, weight: .semibold))
                        .foregroundStyle(AuraPalette.ink)
                    Text("\(Int(weeklyCalmMinutes)) of \(Int(weeklyGoal)) min this week")
                        .font(AuraFont.text(12, weight: .light))
                        .foregroundStyle(AuraPalette.inkDim)
                }
            }
        }
    }

    private func practiceRow(emoji: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            GlassCard(padding: 16) {
                HStack(spacing: 14) {
                    Text(emoji).font(.system(size: 22))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(AuraFont.text(14, weight: .semibold))
                            .foregroundStyle(AuraPalette.ink)
                        Text(subtitle)
                            .font(AuraFont.text(11.5, weight: .light))
                            .foregroundStyle(AuraPalette.inkDim)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundStyle(AuraPalette.inkGhost)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Meditation library

struct MeditationLibraryView: View {
    @Environment(StoreService.self) private var store
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Meditations")
                        .font(AuraFont.display(26, relativeTo: .title))
                        .foregroundStyle(AuraPalette.ink)
                        .padding(.top, 22)

                    ForEach(Array(Meditation.library.enumerated()), id: \.element.id) { i, meditation in
                        if meditation.isPremium && !store.isSubscribed {
                            Button {
                                dismiss()
                                appState.isPaywallPresented = true
                            } label: {
                                lockedRow(meditation)
                            }
                            .buttonStyle(.plain)
                            .riseFadeIn(index: i)
                        } else {
                            NavigationLinkCard(meditation: meditation)
                                .riseFadeIn(index: i)
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

    private func lockedRow(_ meditation: Meditation) -> some View {
        GlassCard(padding: 16) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(0.06))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(AuraPalette.gold)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(meditation.title)
                        .font(AuraFont.text(14, weight: .semibold))
                        .foregroundStyle(AuraPalette.ink.opacity(0.7))
                    Text("\(meditation.minutes) min · Aura+")
                        .font(AuraFont.text(11.5, weight: .light))
                        .foregroundStyle(AuraPalette.gold)
                }
                Spacer()
            }
        }
    }
}

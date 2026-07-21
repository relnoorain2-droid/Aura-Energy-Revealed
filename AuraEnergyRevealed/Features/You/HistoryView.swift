//
//  HistoryView.swift
//  Aura Energy Revealed
//
//  Screen 17 — "Your Journey". Energy-over-time chart, then a
//  reverse-chron list of readings with mini auras. Free: last 7 days.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(StoreService.self) private var store
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AuraReading.date, order: .reverse) private var readings: [AuraReading]

    @State private var presentedReading: AuraReading?

    private var visibleReadings: [AuraReading] {
        if store.isSubscribed { return readings }
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return readings.filter { $0.date >= cutoff }
    }

    var body: some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Journey")
                        .font(AuraFont.display(26, relativeTo: .title))
                        .foregroundStyle(AuraPalette.ink)
                        .padding(.top, 22)

                    if let first = readings.last {
                        Text("\(readings.count) readings · since \(first.date.formatted(.dateTime.month(.wide)))")
                            .font(AuraFont.text(11.5, weight: .light))
                            .foregroundStyle(AuraPalette.inkDim)
                    }

                    if readings.count < 3 {
                        emptyState
                    } else {
                        chart
                            .riseFadeIn(index: 0)
                    }

                    ForEach(Array(visibleReadings.enumerated()), id: \.element.persistentModelID) { i, reading in
                        Button {
                            presentedReading = reading
                        } label: {
                            readingRow(reading)
                        }
                        .buttonStyle(.plain)
                        .riseFadeIn(index: i + 1)
                    }

                    if !store.isSubscribed && readings.count > visibleReadings.count {
                        Button {
                            dismiss()
                            appState.isPaywallPresented = true
                        } label: {
                            GlassCard(padding: 16, tint: AuraPalette.gold) {
                                HStack {
                                    Image(systemName: "sparkles").foregroundStyle(AuraPalette.gold)
                                    Text("See your full timeline with Aura+")
                                        .font(AuraFont.text(13, weight: .semibold))
                                        .foregroundStyle(AuraPalette.ink)
                                    Spacer()
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AuraSpacing.gutter)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
        }
        .sheet(item: $presentedReading) { reading in
            ResultView(reading: reading, isNewReading: false)
        }
        .presentationDragIndicator(.visible)
    }

    private var emptyState: some View {
        GlassCard(padding: 24) {
            VStack(spacing: 10) {
                AuraOrbView(style: .brand, size: 80)
                Text("Your journey is just beginning")
                    .font(AuraFont.display(20, relativeTo: .title3))
                    .foregroundStyle(AuraPalette.ink)
                Text("Each reading adds a colour to your timeline. Patterns emerge after a few days.")
                    .font(AuraFont.text(12, weight: .light))
                    .foregroundStyle(AuraPalette.inkDim)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var chart: some View {
        GlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                MonoLabel(text: "Energy Over Time")
                HStack(alignment: .bottom, spacing: 5) {
                    ForEach(Array(visibleReadings.prefix(14).reversed().enumerated()), id: \.offset) { _, reading in
                        let energy = (reading.intuition + reading.calm + reading.vitality) / 3
                        LinearGradient(
                            colors: [reading.dominant.orbStyle.colors.first ?? AuraPalette.lavender, .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                        .frame(height: 24 + 46 * energy)
                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 3, topTrailingRadius: 3))
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 70, alignment: .bottom)
            }
        }
    }

    private func readingRow(_ reading: AuraReading) -> some View {
        GlassCard(padding: 13) {
            HStack(spacing: 12) {
                AuraOrbView(style: reading.dominant.orbStyle, size: 34)
                VStack(alignment: .leading, spacing: 1) {
                    Text(reading.dominant.displayName)
                        .font(AuraFont.text(13, weight: .semibold))
                        .foregroundStyle(AuraPalette.ink)
                    Text(rowTimestamp(reading.date))
                        .font(AuraFont.mono(9))
                        .foregroundStyle(AuraPalette.inkGhost)
                }
                Spacer()
                if reading.mode != .selfAura {
                    Image(systemName: reading.mode.symbol)
                        .font(.system(size: 12))
                        .foregroundStyle(AuraPalette.inkGhost)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(AuraPalette.inkGhost)
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(reading)
                try? modelContext.save()
            } label: {
                Label("Delete reading", systemImage: "trash")
            }
        }
    }

    private func rowTimestamp(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "TODAY · " + date.formatted(date: .omitted, time: .shortened).uppercased()
        }
        if calendar.isDateInYesterday(date) {
            return "YESTERDAY"
        }
        return date.formatted(.dateTime.weekday(.abbreviated).hour().minute()).uppercased()
    }
}

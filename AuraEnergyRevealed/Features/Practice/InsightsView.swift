//
//  InsightsView.swift
//  Auralis
//
//  Energy Insights — what your readings, rituals and journal add up to over time.
//
//  Everything here is computed on-device from data the person created. No
//  scores, no diagnoses: patterns are described in plain language and always
//  framed as prompts for reflection rather than measurements of a person.
//

import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \AuraReading.date, order: .reverse) private var readings: [AuraReading]
    @Query(sort: \JournalEntry.date, order: .reverse) private var journal: [JournalEntry]
    @Query(sort: \RitualCompletion.date, order: .reverse) private var rituals: [RitualCompletion]

    var body: some View {
        ZStack {
            AuraPalette.deepSpace.ignoresSafeArea()
            RadialBloom(color: AuraPalette.electricBlueDeep, center: .init(x: 0.8, y: 0.05), opacity: 0.2)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    if readings.isEmpty && rituals.isEmpty {
                        emptyState
                    } else {
                        statTiles
                        if !observations.isEmpty { observationsCard }
                        if !hueCounts.isEmpty { hueDistribution }
                        if !readings.isEmpty { energyAverages }
                        if !moodCounts.isEmpty { moodCard }
                        footerNote
                    }
                }
                .padding(.horizontal, AuraSpacing.gutter)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Energy Insights")
                    .font(AuraFont.display(27, relativeTo: .largeTitle))
                    .foregroundStyle(AuraPalette.ink)
                Text("Patterns across everything you've logged")
                    .font(AuraFont.text(12))
                    .foregroundStyle(AuraPalette.inkDim)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13))
                    .foregroundStyle(AuraPalette.ink.opacity(0.6))
            }
            .accessibilityLabel("Close")
        }
        .padding(.top, 18)
    }

    private var emptyState: some View {
        GlassCard(padding: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Nothing to show yet")
                    .font(AuraFont.display(19))
                    .foregroundStyle(AuraPalette.ink)
                Text("Take a reading or complete a daily ritual, and patterns will start appearing here — which colours recur, how your energy moves through the week, and what your reflections keep circling back to.")
                    .font(AuraFont.text(13))
                    .foregroundStyle(AuraPalette.inkDim)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: Stats

    private var statTiles: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            statTile(value: "\(readings.count)", label: "READINGS")
            statTile(value: "\(currentStreak)", label: "DAY STREAK")
            statTile(value: "\(rituals.count)", label: "RITUALS")
            statTile(value: practiceMinutesLabel, label: "PRACTISED")
        }
    }

    private func statTile(value: String, label: String) -> some View {
        GlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(AuraFont.display(26))
                    .foregroundStyle(AuraPalette.ink)
                Text(label)
                    .font(AuraFont.mono(9))
                    .foregroundStyle(AuraPalette.inkGhost)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var practiceMinutesLabel: String {
        let total = rituals.reduce(0) { $0 + $1.secondsPracticed }
        return total < 60 ? "\(total)s" : "\(total / 60)m"
    }

    // MARK: Observations (plain-language patterns)

    private var observations: [String] {
        var notes: [String] = []

        if let (hue, count) = hueCounts.first, readings.count >= 3 {
            let share = Int((Double(count) / Double(readings.count) * 100).rounded())
            notes.append("\(hue.displayName) shows up in \(share)% of your readings — more than any other colour. Its themes are \(hue.essence.lowercased()).")
        }

        if readings.count >= 4 {
            let recent = Array(readings.prefix(3))
            let older = Array(readings.dropFirst(3).prefix(5))
            if !older.isEmpty {
                let recentCalm = recent.map(\.calm).reduce(0, +) / Double(recent.count)
                let olderCalm = older.map(\.calm).reduce(0, +) / Double(older.count)
                let delta = recentCalm - olderCalm
                if abs(delta) > 0.08 {
                    notes.append(delta > 0
                        ? "Your recent readings lean calmer than your earlier ones. Whatever you've changed lately seems worth keeping."
                        : "Calm reads lower in your recent readings than it did before. Worth asking what's been asking more of you.")
                }
            }
        }

        if rituals.count >= 3 {
            notes.append("You've completed \(rituals.count) daily rituals. Consistency tends to matter more here than intensity.")
        }

        if let busiest = busiestWeekday, readings.count >= 5 {
            notes.append("You check in most often on \(busiest)s. Noticing when you reach for this is its own kind of insight.")
        }

        if notes.isEmpty && !readings.isEmpty {
            notes.append("Keep going — a few more readings and clearer patterns will surface here.")
        }
        return notes
    }

    private var observationsCard: some View {
        GlassCard(padding: 18, tint: AuraPalette.auroraPurple) {
            VStack(alignment: .leading, spacing: 12) {
                Text("WHAT WE NOTICED")
                    .font(AuraFont.mono(9))
                    .foregroundStyle(AuraPalette.inkGhost)
                ForEach(Array(observations.enumerated()), id: \.offset) { index, note in
                    if index > 0 { Divider().overlay(.white.opacity(0.07)) }
                    Text(note)
                        .font(AuraFont.text(13))
                        .foregroundStyle(AuraPalette.ink)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var busiestWeekday: String? {
        guard !readings.isEmpty else { return nil }
        let calendar = Calendar.current
        var tally: [Int: Int] = [:]
        for reading in readings {
            let day = calendar.component(.weekday, from: reading.date)
            tally[day, default: 0] += 1
        }
        guard let top = tally.max(by: { $0.value < $1.value })?.key else { return nil }
        let symbols = calendar.weekdaySymbols
        guard top >= 1, top <= symbols.count else { return nil }
        return symbols[top - 1]
    }

    // MARK: Colour distribution

    private var hueCounts: [(AuraHue, Int)] {
        var tally: [AuraHue: Int] = [:]
        for reading in readings { tally[reading.dominant, default: 0] += 1 }
        return tally.sorted { lhs, rhs in
            lhs.value == rhs.value ? lhs.key.rawValue < rhs.key.rawValue : lhs.value > rhs.value
        }.map { ($0.key, $0.value) }
    }

    private var hueDistribution: some View {
        GlassCard(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Text("YOUR COLOURS")
                    .font(AuraFont.mono(9))
                    .foregroundStyle(AuraPalette.inkGhost)

                let maxCount = hueCounts.first?.1 ?? 1
                ForEach(hueCounts.prefix(6), id: \.0) { hue, count in
                    HStack(spacing: 10) {
                        Text(hue.displayName)
                            .font(AuraFont.text(12))
                            .foregroundStyle(AuraPalette.ink)
                            .frame(width: 66, alignment: .leading)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(.white.opacity(0.07))
                                Capsule()
                                    .fill(hue.titleColor.opacity(0.85))
                                    .frame(width: max(6, geo.size.width * (Double(count) / Double(maxCount))))
                            }
                        }
                        .frame(height: 8)

                        Text("\(count)")
                            .font(AuraFont.mono(10))
                            .foregroundStyle(AuraPalette.inkGhost)
                            .frame(width: 20, alignment: .trailing)
                    }
                    .frame(height: 18)
                }
            }
        }
    }

    // MARK: Energy averages

    private var energyAverages: some View {
        GlassCard(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                Text("AVERAGE ACROSS READINGS")
                    .font(AuraFont.mono(9))
                    .foregroundStyle(AuraPalette.inkGhost)

                metricBar(title: "Intuition", value: average(\.intuition), color: AuraPalette.auroraPurple)
                metricBar(title: "Calm", value: average(\.calm), color: AuraPalette.electricBlue)
                metricBar(title: "Vitality", value: average(\.vitality), color: AuraPalette.gold)
            }
        }
    }

    private func average(_ keyPath: KeyPath<AuraReading, Double>) -> Double {
        guard !readings.isEmpty else { return 0 }
        return readings.map { $0[keyPath: keyPath] }.reduce(0, +) / Double(readings.count)
    }

    private func metricBar(title: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(AuraFont.text(12))
                    .foregroundStyle(AuraPalette.ink)
                Spacer()
                Text("\(Int((value * 100).rounded()))")
                    .font(AuraFont.mono(10))
                    .foregroundStyle(AuraPalette.inkGhost)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.07))
                    Capsule()
                        .fill(LinearGradient(colors: [color.opacity(0.5), color], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(6, geo.size.width * min(1, max(0, value))))
                }
            }
            .frame(height: 7)
        }
    }

    // MARK: Moods

    private var moodCounts: [(String, Int)] {
        var tally: [String: Int] = [:]
        for entry in journal {
            for mood in entry.moods { tally[mood, default: 0] += 1 }
        }
        return tally.sorted {
            $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value
        }.map { ($0.key, $0.value) }
    }

    private var moodCard: some View {
        GlassCard(padding: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("MOODS YOU LOG MOST")
                    .font(AuraFont.mono(9))
                    .foregroundStyle(AuraPalette.inkGhost)
                FlowLayout(spacing: 7) {
                    ForEach(moodCounts.prefix(10), id: \.0) { mood, count in
                        Text("\(mood) · \(count)")
                            .font(AuraFont.text(11))
                            .foregroundStyle(AuraPalette.ink)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background { Capsule().fill(.white.opacity(0.07)) }
                    }
                }
            }
        }
    }

    private var footerNote: some View {
        Text("These patterns describe what you've recorded, not who you are. Aura readings are reflective prompts — never measurements, diagnoses, or medical advice.")
            .font(AuraFont.text(11))
            .foregroundStyle(AuraPalette.inkGhost)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 4)
    }

    // MARK: Streak

    private var currentStreak: Int {
        let calendar = Calendar.current
        var days = Set(readings.map { calendar.startOfDay(for: $0.date) })
        days.formUnion(rituals.map { calendar.startOfDay(for: $0.date) })
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
}

// MARK: - A simple wrapping layout for mood chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

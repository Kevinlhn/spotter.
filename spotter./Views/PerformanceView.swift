//
//  PerformanceView.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 12/11/25.
//

import SwiftUI

struct PerformanceView: View {
    @StateObject private var workoutVM = WorkoutViewModel()

    // Toggles between short ranges if you want to expand later
    @State private var selectedRange: PerformanceRange = .thisWeek

    var body: some View {
        ZStack {
            SpotterBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    headerSection

                    rangePickerSection

                    spotlightSection

                    metricsRowSection

                    volumeTrendSection

                    musclesBubbleSection

                    aiSummarySection
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            workoutVM.loadWorkouts()
        }
    }
}

// MARK: - Header

private extension PerformanceView {
    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Performance")
                    .font(.system(size: 24, weight: .bold))

                Text("Your training, at a glance.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "bolt.circle.fill")
                .font(.system(size: 28))
                .symbolRenderingMode(.hierarchical)
        }
        .foregroundStyle(.primary)
    }
}

// MARK: - Range Picker

private extension PerformanceView {
    var rangePickerSection: some View {
        HStack(spacing: 8) {
            ForEach(PerformanceRange.allCases, id: \.self) { range in
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        selectedRange = range
                    }
                }) {
                    Text(range.title)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(selectedRange == range
                                      ? Color.white.opacity(0.14)
                                      : Color.white.opacity(0.04))
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(selectedRange == range
                                              ? Color.white.opacity(0.5)
                                              : Color.clear,
                                              lineWidth: 1)
                        )
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }
}

// MARK: - Spotlight PR

private extension PerformanceView {
    var spotlightSection: some View {
        let spotlight = PerformanceAnalyzer.spotlightWorkout(from: workoutVM.workouts)

        return VStack(alignment: .leading, spacing: 10) {
            Text("Spotlight")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.45),
                                Color.blue.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .blendMode(.plusLighter)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(spotlight.title)
                            .font(.headline.weight(.semibold))

                        Spacer()

                        if let status = spotlight.status {
                            Text(status.label)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.15))
                                )
                        }
                    }

                    if let subtitle = spotlight.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let detail = spotlight.detail {
                        Text(detail)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(14)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Metrics Row (This Week at a Glance)

private extension PerformanceView {
    var metricsRowSection: some View {
        let stats = PerformanceAnalyzer.stats(
            from: workoutVM.workouts,
            range: selectedRange
        )

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("This Week at a Glance")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(stats.rangeLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                MetricCard(
                    title: "Workouts",
                    value: "\(stats.workoutCount)",
                    subtitle: stats.workoutDeltaLabel
                )

                MetricCard(
                    title: "Volume",
                    value: "\(stats.totalVolume)",
                    subtitle: "sets*reps (est.)"
                )

                MetricCard(
                    title: "Consistency",
                    value: "\(stats.activeDays)",
                    subtitle: "days trained"
                )
            }
        }
    }
}

// MARK: - Volume Trend

private extension PerformanceView {
    var volumeTrendSection: some View {
        let trend = PerformanceAnalyzer.weeklyVolumeTrend(from: workoutVM.workouts)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Volume Trend")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(trend.count) weeks")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if trend.isEmpty {
                PlaceholderCard(text: "Train a few weeks to see your trend line.")
            } else {
                VolumeLineChart(data: trend)
                    .frame(height: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.black.opacity(0.25))
                    )
            }
        }
    }
}

// MARK: - Muscles Bubble Chart

private extension PerformanceView {
    var musclesBubbleSection: some View {
        let bubbles = PerformanceAnalyzer.muscleBubbles(from: workoutVM.workouts)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Most-Trained Muscles")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if bubbles.isEmpty {
                PlaceholderCard(text: "Once you log exercises with muscle groups, we’ll show your training focus here.")
            } else {
                MuscleBubbleChart(bubbles: bubbles)
                    .frame(height: 160)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.black.opacity(0.25))
                    )
            }
        }
    }
}

// MARK: - AI Summary Card

private extension PerformanceView {
    var aiSummarySection: some View {
        let stats = PerformanceAnalyzer.stats(
            from: workoutVM.workouts,
            range: selectedRange
        )

        return VStack(alignment: .leading, spacing: 8) {
            Text("Your Week in 10 Seconds")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            AISummaryCard(summary: stats.aiSummary)
        }
    }
}

// MARK: - Supporting Views

private struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 20, weight: .bold))
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.25))
        )
    }
}

private struct PlaceholderCard: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .center)
            .padding(.horizontal, 12)
            .multilineTextAlignment(.center)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.2))
            )
    }
}

private struct VolumeLineChart: View {
    let data: [Double]

    var body: some View {
        GeometryReader { geo in
            let maxValue = (data.max() ?? 1)
            let minValue = (data.min() ?? 0)
            let range = max(maxValue - minValue, 1)

            let width = geo.size.width
            let height = geo.size.height
            let stepX = data.count > 1 ? width / CGFloat(data.count - 1) : 0

            ZStack {
                // Baseline grid
                Path { path in
                    let midY = height * 0.75
                    path.move(to: CGPoint(x: 0, y: midY))
                    path.addLine(to: CGPoint(x: width, y: midY))
                }
                .stroke(Color.white.opacity(0.15), lineWidth: 1)

                // Line
                Path { path in
                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) * stepX
                        let normalized = (value - minValue) / range
                        let y = height * (1 - CGFloat(normalized)) * 0.9 + height * 0.05

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.blue.opacity(0.8), lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

private struct MuscleBubbleChart: View {
    let bubbles: [MuscleBubble]

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            ZStack {
                ForEach(Array(bubbles.enumerated()), id: \.element.id) { index, bubble in
                    let angle = Double(index) / Double(max(bubbles.count, 1)) * 2 * Double.pi
                    let radius = min(width, height) / 3.0

                    let centerX = width / 2 + CGFloat(cos(angle)) * radius
                    let centerY = height / 2 + CGFloat(sin(angle)) * radius * 0.6

                    let size = CGFloat(40 + (bubble.intensity * 60))

                    VStack {
                        Text(bubble.label)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                    }
                    .frame(width: size, height: size)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.35))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .position(x: centerX, y: centerY)
                }
            }
        }
    }
}

private struct AISummaryCard: View {
    let summary: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .semibold))

            Text(summary)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.28))
        )
    }
}

// MARK: - Models & Analyzer

private enum PerformanceRange: CaseIterable {
    case thisWeek
    case last4Weeks

    var title: String {
        switch self {
        case .thisWeek: return "This Week"
        case .last4Weeks: return "Last 4 Weeks"
        }
    }
}

private struct PerformanceStats {
    let workoutCount: Int
    let totalVolume: Int
    let activeDays: Int
    let rangeLabel: String
    let workoutDeltaLabel: String
    let aiSummary: String
}

private struct SpotlightWorkout {
    let title: String
    let subtitle: String?
    let detail: String?
    let status: WorkoutStatus?
}

private struct MuscleBubble: Identifiable {
    let id = UUID()
    let label: String
    let intensity: Double  // 0...1
}

private enum PerformanceAnalyzer {
    static func stats(from workouts: [WorkoutEntity], range: PerformanceRange) -> PerformanceStats {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date

        switch range {
        case .thisWeek:
            startDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        case .last4Weeks:
            startDate = calendar.date(byAdding: .day, value: -27, to: now) ?? now
        }

        let filtered = workouts.filter { $0.date >= startDate && $0.date <= now }

        let workoutCount = filtered.count

        let volume = filtered.reduce(0) { partial, workout in
            partial + workout.estimatedVolume  // see extension below
        }

        let uniqueDays = Set(filtered.map { calendar.startOfDay(for: $0.date) })
        let activeDays = uniqueDays.count

        let rangeLabel: String
        switch range {
        case .thisWeek:
            rangeLabel = "This week"
        case .last4Weeks:
            rangeLabel = "Last 4 weeks"
        }

        // Super simple fake delta, you can improve later
        let workoutDeltaLabel = workoutCount == 0 ? "—" : "\(workoutCount) sessions"

        let aiSummary: String
        if workoutCount == 0 {
            aiSummary = "You haven’t logged any workouts in this range yet. Once you do, I’ll break down your training here."
        } else {
            aiSummary = "You logged \(workoutCount) workout\(workoutCount == 1 ? "" : "s") across \(activeDays) day\(activeDays == 1 ? "" : "s"), with an estimated volume of \(volume). Keep building that streak—small consistent pushes add up fast."
        }

        return PerformanceStats(
            workoutCount: workoutCount,
            totalVolume: volume,
            activeDays: activeDays,
            rangeLabel: rangeLabel,
            workoutDeltaLabel: workoutDeltaLabel,
            aiSummary: aiSummary
        )
    }

    static func spotlightWorkout(from workouts: [WorkoutEntity]) -> SpotlightWorkout {
        let completed = workouts.filter { $0.workoutStatus == .completed }
        let target = completed.sorted(by: { $0.date > $1.date }).first ?? workouts.sorted(by: { $0.date > $1.date }).first

        guard let workout = target else {
            return SpotlightWorkout(
                title: "No workouts yet",
                subtitle: "Once you finish a session, it’ll show up here.",
                detail: nil,
                status: nil
            )
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        let title = workout.name
        let subtitle = "\(formatter.string(from: workout.date)) • \(workout.workoutStatus.label)"
        let detail = "Approx. volume: \(workout.estimatedVolume)"

        return SpotlightWorkout(
            title: title,
            subtitle: subtitle,
            detail: detail,
            status: workout.workoutStatus
        )
    }

    static func weeklyVolumeTrend(from workouts: [WorkoutEntity]) -> [Double] {
        let calendar = Calendar.current

        // Last 6 weeks including this one
        let now = Date()
        var weekStarts: [Date] = []
        if let startOfThisWeek = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        ) {
            for offset in (0..<6).reversed() {
                if let week = calendar.date(byAdding: .weekOfYear, value: -offset, to: startOfThisWeek) {
                    weekStarts.append(week)
                }
            }
        }

        var volumes: [Double] = []

        for start in weekStarts {
            let end = calendar.date(byAdding: .day, value: 7, to: start) ?? start
            let inWeek = workouts.filter { $0.date >= start && $0.date < end }
            let volume = inWeek.reduce(0) { $0 + $1.estimatedVolume }
            volumes.append(Double(volume))
        }

        return volumes
    }

    static func muscleBubbles(from workouts: [WorkoutEntity]) -> [MuscleBubble] {
        // This assumes ExerciseEntity has `muscleGroup: String?`
        // Adjust according to your Core Data model.
        var counts: [String: Int] = [:]

        for workout in workouts {
            for exercise in workout.sortedExercises {
                let group = (exercise.value(forKey: "muscleGroup") as? String) ?? "Other"
                counts[group, default: 0] += 1
            }
        }

        guard !counts.isEmpty else { return [] }

        let maxCount = counts.values.max() ?? 1

        return counts
            .sorted { $0.value > $1.value }
            .prefix(6)
            .map { (label, value) in
                MuscleBubble(
                    label: label,
                    intensity: Double(value) / Double(maxCount)
                )
            }
    }
}

// MARK: - Extensions

private extension WorkoutEntity {
    /// Very rough volume estimate. Replace with real sets*reps*weight logic once you have it.
    var estimatedVolume: Int {
        sortedExercises.count
    }
}
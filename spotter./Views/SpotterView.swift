//
//  SpotterView.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 12/11/25.
//

import SwiftUI

struct SpotterView: View {
    @StateObject private var workoutVM = WorkoutViewModel()

    @State private var mode: TrainingMode = .balanced
    @State private var userQuestion: String = ""
    @State private var lastCoachReply: String = "I’ll start giving you tailored coaching once you log a few workouts."

    var body: some View {
        ZStack {
            SpotterBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {

                    headerSection

                    modeChipsSection

                    todaysPlanSection

                    smartRecommendationsSection

                    focusAreasSection

                    askSpotterSection
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            workoutVM.loadWorkouts()
            lastCoachReply = CoachBrain.generateInitialSummary(
                workouts: workoutVM.workouts,
                mode: mode
            )
        }
    }
}

// MARK: - Header

private extension SpotterView {
    var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Spotter")
                    .font(.system(size: 24, weight: .bold))

                Text("Your AI coach, on call.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 28, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
        }
        .foregroundStyle(.primary)
    }
}

// MARK: - Mode Chips

private extension SpotterView {
    var modeChipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Training focus")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TrainingMode.allCases, id: \.self) { option in
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                mode = option
                                lastCoachReply = CoachBrain.generateInitialSummary(
                                    workouts: workoutVM.workouts,
                                    mode: mode
                                )
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: option.icon)
                                    .font(.caption2)
                                Text(option.title)
                                    .font(.caption.weight(.semibold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(mode == option
                                          ? Color.white.opacity(0.16)
                                          : Color.white.opacity(0.04))
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        mode == option
                                        ? Color.white.opacity(0.6)
                                        : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                            .foregroundColor(.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Today’s Plan

private extension SpotterView {
    var todaysPlanSection: some View {
        let plan = CoachBrain.todaysPlan(
            workouts: workoutVM.workouts,
            mode: mode
        )

        return VStack(alignment: .leading, spacing: 8) {
            Text("Today’s plan")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.5),
                                Color.purple.opacity(0.3),
                                Color.cyan.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .blendMode(.plusLighter)
                    )

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: plan.icon)
                                .font(.system(size: 18, weight: .semibold))
                            Text(plan.title)
                                .font(.headline.weight(.semibold))
                        }

                        if let subtitle = plan.subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let detail = plan.detail {
                            Text(detail)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer()
                }
                .padding(14)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Smart Recommendations

private extension SpotterView {
    var smartRecommendationsSection: some View {
        let recs = CoachBrain.recommendations(
            workouts: workoutVM.workouts,
            mode: mode
        )

        return VStack(alignment: .leading, spacing: 8) {
            Text("Smart recommendations")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                ForEach(recs.indices, id: \.self) { index in
                    let rec = recs[index]
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: rec.icon)
                            .font(.system(size: 13, weight: .semibold))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(rec.title)
                                .font(.caption.weight(.semibold))
                            Text(rec.detail)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.black.opacity(0.22))
                    )
                }
            }
        }
    }
}

// MARK: - Focus Areas

private extension SpotterView {
    var focusAreasSection: some View {
        let focus = CoachBrain.focusAreas(from: workoutVM.workouts)

        return VStack(alignment: .leading, spacing: 8) {
            Text("Focus areas")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                if focus.undertrained.isEmpty && focus.overtrained.isEmpty {
                    Text("Once you log exercises with muscle groups, I’ll tell you what needs more love — and what’s getting plenty.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.black.opacity(0.22))
                        )
                } else {
                    if !focus.undertrained.isEmpty {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "arrow.up.right")
                                .font(.caption2.weight(.semibold))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Could use more attention")
                                    .font(.caption.weight(.semibold))
                                Text(focus.undertrained.joined(separator: " • "))
                                    .font(.caption2)
                            }
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.black.opacity(0.22))
                        )
                    }

                    if !focus.overtrained.isEmpty {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "arrow.down.right")
                                .font(.caption2.weight(.semibold))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("You’re hitting these a lot")
                                    .font(.caption.weight(.semibold))
                                Text(focus.overtrained.joined(separator: " • "))
                                    .font(.caption2)
                            }
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.black.opacity(0.22))
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Ask Spotter

private extension SpotterView {
    var askSpotterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ask Spotter")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))

                    Text(lastCoachReply)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.black.opacity(0.26))
                )

                HStack(spacing: 8) {
                    TextField("Ask about your plan, recovery, or progress…", text: $userQuestion)
                        .font(.caption)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.black.opacity(0.18))
                        )

                    Button(action: {
                        let trimmed = userQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }

                        // For now: local / fake reply. Later: send to real LLM.
                        lastCoachReply = CoachBrain.generateReply(
                            question: trimmed,
                            workouts: workoutVM.workouts,
                            mode: mode
                        )
                        userQuestion = ""
                    }) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.9))
                            )
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Models / Brain

private enum TrainingMode: CaseIterable {
    case balanced
    case strength
    case hypertrophy
    case weightLoss

    var title: String {
        switch self {
        case .balanced: return "Balanced"
        case .strength: return "Strength"
        case .hypertrophy: return "Hypertrophy"
        case .weightLoss: return "Weight loss"
        }
    }

    var icon: String {
        switch self {
        case .balanced: return "circle.grid.2x2"
        case .strength: return "bolt.fill"
        case .hypertrophy: return "dumbbell.fill"
        case .weightLoss: return "flame.fill"
        }
    }
}

private struct TodaysPlanCard {
    let icon: String
    let title: String
    let subtitle: String?
    let detail: String?
}

private struct CoachRecommendation {
    let icon: String
    let title: String
    let detail: String
}

private struct FocusAreas {
    let undertrained: [String]
    let overtrained: [String]
}

private enum CoachBrain {
    static func todaysPlan(workouts: [WorkoutEntity], mode: TrainingMode) -> TodaysPlanCard {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let todaysWorkouts = workouts.filter { calendar.isDate($0.date, inSameDayAs: today) }
        let recentCompleted = workouts
            .filter { $0.workoutStatus == .completed }
            .sorted(by: { $0.date > $1.date })
            .first

        if !todaysWorkouts.isEmpty {
            return TodaysPlanCard(
                icon: "checkmark.circle.fill",
                title: "You’re scheduled to train today",
                subtitle: "You already have \(todaysWorkouts.count) workout\(todaysWorkouts.count == 1 ? "" : "s") planned.",
                detail: "Open Today to start your next session when you’re ready."
            )
        }

        if let last = recentCompleted {
            let daysAgo = calendar.dateComponents([.day], from: calendar.startOfDay(for: last.date), to: today).day ?? 0

            if daysAgo <= 1 {
                return TodaysPlanCard(
                    icon: "figure.walk.motion",
                    title: "Active recovery day",
                    subtitle: "You trained recently.",
                    detail: "Light movement, steps, and mobility will help you recover while staying on track."
                )
            } else if daysAgo >= 4 {
                return TodaysPlanCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "Time to get moving",
                    subtitle: "It’s been \(daysAgo) days since your last logged workout.",
                    detail: "A short, focused session today will restart your momentum. Even 20–30 minutes counts."
                )
            }
        }

        // No workouts logged yet
        let title: String
        switch mode {
        case .balanced:
            title = "Let’s build your first week"
        case .strength:
            title = "Let’s build your strength split"
        case .hypertrophy:
            title = "Let’s build your volume plan"
        case .weightLoss:
            title = "Let’s start your cut smoothly"
        }

        return TodaysPlanCard(
            icon: "sparkles",
            title: title,
            subtitle: "No sessions logged yet.",
            detail: "Use the Today tab to create your first workout. I’ll start adapting to your training as you go."
        )
    }

    static func recommendations(workouts: [WorkoutEntity], mode: TrainingMode) -> [CoachRecommendation] {
        var recs: [CoachRecommendation] = []

        let stats = simpleStats(from: workouts)
        let calendar = Calendar.current
        let today = Date()

        // 1) Frequency
        if stats.sessionsThisWeek == 0 {
            recs.append(
                CoachRecommendation(
                    icon: "calendar.badge.exclamationmark",
                    title: "No sessions logged this week yet",
                    detail: "Aim for at least 2–3 workouts this week. Even short sessions count — consistency beats perfection."
                )
            )
        } else if stats.sessionsThisWeek < 3 {
            recs.append(
                CoachRecommendation(
                    icon: "calendar.badge.clock",
                    title: "You’re warming up",
                    detail: "You’ve logged \(stats.sessionsThisWeek) workout\(stats.sessionsThisWeek == 1 ? "" : "s") this week. One or two more will solidify your routine."
                )
            )
        } else {
            recs.append(
                CoachRecommendation(
                    icon: "flame.fill",
                    title: "Nice consistency",
                    detail: "You’ve already hit \(stats.sessionsThisWeek)+ sessions this week. Keep the streak alive with one more intentional workout."
                )
            )
        }

        // 2) Mode-specific nudge
        switch mode {
        case .strength:
            recs.append(
                CoachRecommendation(
                    icon: "bolt.fill",
                    title: "Prioritize your big lifts",
                    detail: "Center your next session around squat, bench, or deadlift. Keep accessories tight and supportive."
                )
            )
        case .hypertrophy:
            recs.append(
                CoachRecommendation(
                    icon: "dumbbell.fill",
                    title: "Chase good pumps, not failure",
                    detail: "Stay 1–3 reps from failure on most sets and control your tempo. Your joints will thank you later."
                )
            )
        case .weightLoss:
            recs.append(
                CoachRecommendation(
                    icon: "flame.fill",
                    title: "Stack movement on top of lifting",
                    detail: "Add 15–20 minutes of walking before or after your session to gently increase your daily burn."
                )
            )
        case .balanced:
            recs.append(
                CoachRecommendation(
                    icon: "figure.strengthtraining.traditional",
                    title: "Blend strength and movement",
                    detail: "Alternate heavier, lower-rep days with lighter, higher-rep or conditioning days to stay well-rounded."
                )
            )
        }

        // 3) Recovery or “get moving” based on last completed
        if let last = stats.lastCompleted {
            let daysAgo = calendar.dateComponents([.day], from: calendar.startOfDay(for: last.date), to: calendar.startOfDay(for: today)).day ?? 0

            if daysAgo >= 4 {
                recs.append(
                    CoachRecommendation(
                        icon: "exclamationmark.circle.fill",
                        title: "Don’t overthink the restart",
                        detail: "After a few days off, your main job is to show up. Keep the first session back simple and manageable."
                    )
                )
            } else if daysAgo <= 1 {
                recs.append(
                    CoachRecommendation(
                        icon: "moon.zzz.fill",
                        title: "Protect your sleep",
                        detail: "Recovery happens when you’re off the gym floor. Try to give yourself a solid sleep window tonight."
                    )
                )
            }
        }

        return recs
    }

    static func focusAreas(from workouts: [WorkoutEntity]) -> FocusAreas {
        // Very rough: look at muscleGroup counts over recent workouts
        var counts: [String: Int] = [:]

        let calendar = Calendar.current
        let now = Date()
        let fourWeeksAgo = calendar.date(byAdding: .day, value: -28, to: now) ?? now

        let recent = workouts.filter { $0.date >= fourWeeksAgo }

        for workout in recent {
            for exercise in workout.sortedExercises {
                let group = (exercise.value(forKey: "muscleGroup") as? String) ?? "Other"
                counts[group, default: 0] += 1
            }
        }

        guard !counts.isEmpty else {
            return FocusAreas(undertrained: [], overtrained: [])
        }

        let values = counts.values.sorted()
        let minCount = values.first ?? 0
        let maxCount = values.last ?? 0

        // Simple thresholds
        let undertrained = counts
            .filter { $0.value == minCount && $0.value < max(2, maxCount) }
            .map { $0.key }
            .sorted()

        let overtrained = counts
            .filter { $0.value == maxCount && maxCount > minCount }
            .map { $0.key }
            .sorted()

        return FocusAreas(undertrained: undertrained, overtrained: overtrained)
    }

    static func generateInitialSummary(workouts: [WorkoutEntity], mode: TrainingMode) -> String {
        let stats = simpleStats(from: workouts)

        if stats.totalSessions == 0 {
            switch mode {
            case .balanced:
                return "Once you log your first few workouts, I’ll start building a plan around your schedule, recovery, and goals."
            case .strength:
                return "Log your next strength sessions — I’ll help you organize your heavy days, recovery, and progress over time."
            case .hypertrophy:
                return "Track your volume and exercises. I’ll help you balance muscles, manage fatigue, and keep progress moving."
            case .weightLoss:
                return "As you log lifting and movement, I’ll help you keep a sustainable pace instead of sprinting into burnout."
            }
        }

        return "You’ve logged \(stats.totalSessions) workout\(stats.totalSessions == 1 ? "" : "s") so far, with \(stats.sessionsThisWeek) this week. I’ll keep nudging you toward consistency while balancing effort and recovery."
    }

    static func generateReply(question: String, workouts: [WorkoutEntity], mode: TrainingMode) -> String {
        let stats = simpleStats(from: workouts)

        // This is intentionally “local fake AI” so you can wire a real backend later.
        if question.localizedCaseInsensitiveContains("how many times") ||
            question.localizedCaseInsensitiveContains("often") {
            return "Right now you’re averaging about \(max(stats.avgPerWeek, 1)) session\(stats.avgPerWeek == 1 ? "" : "s") per week. A great target for your current mode is 3–4, as long as you can recover between days."
        }

        if question.localizedCaseInsensitiveContains("rest") ||
            question.localizedCaseInsensitiveContains("recovery") {
            return "Good recovery means your next sessions feel heavy but doable — not like you’re dragging a truck. If you’re still sore 3+ days after a session, pull back volume slightly or add an easy movement day instead of another hard lift."
        }

        if question.localizedCaseInsensitiveContains("weight") ||
            question.localizedCaseInsensitiveContains("loss") ||
            question.localizedCaseInsensitiveContains("cut") {
            return "For weight loss, your lifting should support muscle retention: 2–4 strength-oriented sessions per week, staying 1–3 reps from failure. Pair that with steady movement (like walking) and nutrition you can actually keep up for months, not days."
        }

        return "Here’s how I use your data: I look at how often you’re training, how recently you’ve lifted, and which muscles you’ve hit the most. Then I nudge you toward consistency and balance — not punishment. As you log more workouts, my guidance will get more specific."
    }

    // MARK: - Simple stats

    private struct SimpleStats {
        let totalSessions: Int
        let sessionsThisWeek: Int
        let avgPerWeek: Int
        let lastCompleted: WorkoutEntity?
    }

    private static func simpleStats(from workouts: [WorkoutEntity]) -> SimpleStats {
        let calendar = Calendar.current
        let now = Date()

        let totalSessions = workouts.count

        // This week
        let startOfWeek = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        ) ?? now

        let sessionsThisWeek = workouts.filter { $0.date >= startOfWeek && $0.date <= now }.count

        // Rough average over last 8 weeks
        let eightWeeksAgo = calendar.date(byAdding: .day, value: -56, to: now) ?? now
        let recent = workouts.filter { $0.date >= eightWeeksAgo }
        let weeks = max(
            1,
            calendar.dateComponents([.weekOfYear], from: eightWeeksAgo, to: now).weekOfYear ?? 1
        )
        let avgPerWeek = weeks > 0 ? max(0, recent.count / weeks) : recent.count

        let lastCompleted = workouts
            .filter { $0.workoutStatus == .completed }
            .sorted(by: { $0.date > $1.date })
            .first

        return SimpleStats(
            totalSessions: totalSessions,
            sessionsThisWeek: sessionsThisWeek,
            avgPerWeek: avgPerWeek,
            lastCompleted: lastCompleted
        )
    }
}
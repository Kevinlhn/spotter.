import Foundation

struct TrainingWeek: Identifiable {
    var id: Date { date }
    let date: Date
    let count: Int
}

struct ExerciseProgressPoint: Identifiable {
    let id: UUID
    let date: Date
    let value: Double
}

/// Read-only projections shared by the progress views. Inputs are completed sessions.
enum TrainingProgress {
    static func weeks(_ workouts: [WorkoutEntity], now: Date = Date(), calendar: Calendar = .current) -> [TrainingWeek] {
        let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        return (-5...0).compactMap { offset in
            guard let date = calendar.date(byAdding: .weekOfYear, value: offset, to: start),
                  let end = calendar.date(byAdding: .day, value: 7, to: date) else { return nil }
            return TrainingWeek(date: date, count: workouts.filter { $0.date >= date && $0.date < end }.count)
        }
    }

    static func exerciseNames(_ workouts: [WorkoutEntity]) -> [String] {
        var names: [String: String] = [:]
        for exercise in workouts.flatMap(\.sortedExercises) where !exercise.sortedSets.isEmpty {
            let key = ExerciseCatalog.key(exercise.name)
            if names[key] == nil { names[key] = exercise.name }
        }
        return names.values.sorted()
    }

    static func units(_ workouts: [WorkoutEntity], exerciseName: String) -> [String] {
        Set(workouts.filter { $0.sortedExercises.contains { $0.name == exerciseName && !$0.sortedSets.isEmpty } }
            .map { $0.weightUnit ?? "unspecified" }).sorted()
    }

    static func points(_ workouts: [WorkoutEntity], exerciseName: String, unit: String, metric: String) -> [ExerciseProgressPoint] {
        workouts.sorted { $0.date == $1.date ? $0.id.uuidString < $1.id.uuidString : $0.date < $1.date }.compactMap { workout in
            guard (workout.weightUnit ?? "unspecified") == unit else { return nil }
            let sets = workout.sortedExercises.filter { $0.name == exerciseName }.flatMap(\.sortedSets)
            guard !sets.isEmpty else { return nil }
            let value: Double
            switch metric {
            case "reps": value = Double(sets.reduce(0) { $0 + Int($1.reps) })
            case "sets": value = Double(sets.count)
            default: value = sets.map(\.weight).max() ?? 0
            }
            return ExerciseProgressPoint(id: workout.id, date: workout.date, value: value)
        }
    }
}

/// Read-only insights use valid, completed records. Unknown units never enter load totals.
extension TrainingProgress {
    enum Range: String, CaseIterable, Identifiable {
        case month = "4 weeks", quarter = "12 weeks", year = "1 year", all = "All time"
        var id: String { rawValue }
        var days: Int? { switch self { case .month: 28; case .quarter: 84; case .year: 365; case .all: nil } }
        func start(now: Date = .now, calendar: Calendar = .current) -> Date {
            days.flatMap { calendar.date(byAdding: .day, value: -$0, to: now) } ?? .distantPast
        }
    }
    struct Session: Identifiable {
        var id: UUID
        var date: Date
        var sets: [ExercisePerformance.SetResult]
        var volume: Double { sets.reduce(0) { $0 + $1.weight * Double($1.reps) } }
        var bestWeight: Double { sets.map(\.weight).max() ?? 0 }
        var reps: Int { sets.reduce(0) { $0 + $1.reps } }
        var estimatedMax: Double? { sets.compactMap { TrainingProgress.estimatedMax(weight: $0.weight, reps: $0.reps) }.max() }
        var bestSet: ExercisePerformance.SetResult? { sets.max { $0.weight == $1.weight ? $0.reps < $1.reps : $0.weight < $1.weight } }
        func value(metric: String) -> Double? {
            switch metric { case "reps": Double(reps); case "sets": Double(sets.count); case "volume": volume; case "estimate": estimatedMax; default: bestWeight }
        }
    }
    struct Muscle: Identifiable { var id: String { name }; var name: String; var sets: Int }
    struct Record: Identifiable { var id: String { "\(workoutID)-\(name)" }; var workoutID: UUID; var name: String; var date: Date; var weight: Double; var reps: Int }
    static func validSets(_ workout: WorkoutEntity) -> [WorkoutSetEntity] {
        workout.sortedExercises.flatMap(\.sortedSets).filter { ExercisePerformance.SetResult(weight: $0.weight, reps: Int($0.reps)).isValid }
    }
    static func filtered(_ workouts: [WorkoutEntity], range: Range, now: Date = .now) -> [WorkoutEntity] {
        workouts.filter { $0.workoutStatus == .completed && $0.date <= now && $0.date >= range.start(now: now) }
    }
    static func factor(from: String?, to: String) -> Double? {
        if to == "unspecified" { return from == nil ? 1 : nil }
        guard ["lb", "kg"].contains(to), let from, ["lb", "kg"].contains(from) else { return nil }
        return from == to ? 1 : to == "kg" ? 1 / 2.2046226218 : 2.2046226218
    }
    static func estimatedMax(weight: Double, reps: Int) -> Double? {
        guard weight.isFinite, weight > 0, (1...12).contains(reps) else { return nil }
        return reps == 1 ? weight : weight * (1 + Double(reps) / 30)
    }
    static func sessions(_ workouts: [WorkoutEntity], name: String, unit: String) -> [Session] {
        workouts.filter { $0.workoutStatus == .completed }.sorted { $0.date < $1.date }.compactMap { workout in
            guard let factor = factor(from: workout.weightUnit, to: unit) else { return nil }
            let sets = workout.sortedExercises.filter { ExerciseCatalog.key($0.name) == ExerciseCatalog.key(name) }
                .flatMap(\.sortedSets).map { ExercisePerformance.SetResult(weight: $0.weight * factor, reps: Int($0.reps)) }.filter(\.isValid)
            return sets.isEmpty ? nil : Session(id: workout.id, date: workout.date, sets: sets)
        }
    }
    static func volume(_ workouts: [WorkoutEntity], unit: String) -> Double {
        workouts.reduce(0) { sum, workout in
            guard let factor = factor(from: workout.weightUnit, to: unit) else { return sum }
            return sum + validSets(workout).reduce(0) { $0 + $1.weight * factor * Double($1.reps) }
        }
    }
    static func muscles(_ workouts: [WorkoutEntity]) -> [Muscle] {
        var counts: [String: Int] = [:]
        for workout in workouts {
            for exercise in workout.sortedExercises {
                let count = exercise.sortedSets.filter { ExercisePerformance.SetResult(weight: $0.weight, reps: Int($0.reps)).isValid }.count
                counts[exercise.muscleGroup ?? "Other", default: 0] += count
            }
        }
        return counts.filter { $0.value > 0 }.map { Muscle(name: $0.key, sets: $0.value) }.sorted { $0.sets == $1.sets ? $0.name < $1.name : $0.sets > $1.sets }
    }
    /// No finish timestamp exists: this is elapsed time to the last logged set, not workout duration.
    static func loggingMinutes(_ workout: WorkoutEntity) -> Double? {
        guard let last = validSets(workout).compactMap(\.timestamp).max(), last >= workout.date else { return nil }
        return last.timeIntervalSince(workout.date) / 60
    }
    static func records(_ workouts: [WorkoutEntity], since: Date, unit: String) -> [Record] {
        var result: [Record] = []
        for name in exerciseNames(workouts) {
            var best: Double?
            for session in sessions(workouts, name: name, unit: unit) {
                if let previous = best, let set = session.bestSet, set.weight > previous + 0.01, session.date >= since {
                    result.append(Record(workoutID: session.id, name: name, date: session.date, weight: set.weight, reps: set.reps))
                }
                best = max(best ?? 0, session.bestWeight)
            }
        }
        return result.sorted { $0.date > $1.date }
    }
    static func trend(_ sessions: [Session]) -> String {
        guard sessions.count >= 2, let last = sessions.last else { return "Finish another session to establish a trend." }
        let previous = sessions[sessions.count - 2]
        if let current = last.estimatedMax, let before = previous.estimatedMax, before > 0 {
            let percent = (current / before - 1) * 100
            if abs(percent) >= 2.5 { return "Estimated strength is \(abs(percent).formatted(.number.precision(.fractionLength(0))))% \(percent > 0 ? "higher" : "lower") than the previous session. Compare similar sets and technique." }
        }
        let recent = Array(sessions.suffix(3))
        if recent.count == 3, last.date.timeIntervalSince(recent[0].date) >= 14 * 86400,
           let first = recent.first?.estimatedMax, first > 0,
           recent.allSatisfy({ $0.estimatedMax.map { abs($0 / first - 1) < 0.025 } ?? false }) {
            return "Estimated strength has been steady across three sessions over at least two weeks. Review recovery and targets before adding load."
        }
        return "Recent performance is steady. Keep logging comparable sessions before drawing conclusions."
    }
}

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
        Set(workouts.flatMap(\.sortedExercises).filter { !$0.sortedSets.isEmpty }.map(\.name)).sorted()
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

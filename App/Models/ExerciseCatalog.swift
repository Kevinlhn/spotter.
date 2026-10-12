import Foundation

/// One catalog for browsing, workout selection, and coaching. Historical names remain intact.
enum ExerciseCatalog {
    static func key(_ name: String) -> String { name.split(whereSeparator: \.isWhitespace).joined(separator: " ").lowercased() }
    static func moves(custom: [ExerciseTemplateEntity], workouts: [WorkoutEntity]) -> [TrainingMove] {
        var unique: [String: TrainingMove] = [:]
        for exercise in workouts.flatMap(\.sortedExercises) { unique[key(exercise.name)] = TrainingMove(exercise: exercise) }
        for move in TrainingRoutine.starters.flatMap(\.moves) { unique[key(move.name)] = move }
        for move in custom { unique[key(move.name)] = TrainingMove(id: move.id, name: move.name, muscle: move.primaryMuscle ?? "Other") }
        return unique.values.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}

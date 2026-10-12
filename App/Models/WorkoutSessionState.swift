import Foundation

/// Only UI cursor/input and a deadline live here; completed sets remain WorkoutSetEntity records.
/// Stored on the workout so a command and its revision commit in one Core Data transaction.
struct WorkoutSessionState: Codable, Equatable {
    var revision: String
    var exerciseID: UUID?
    var selectedSetID: UUID?
    var weight: Double = 0
    var reps: Int = 8
    var restUntil: Double = 0
}

extension WorkoutEntity {
    var sessionState: WorkoutSessionState {
        get {
            if let sessionData, let value = try? JSONDecoder().decode(WorkoutSessionState.self, from: sessionData) { return value }
            let exercise = sortedExercises.first
            return WorkoutSessionState(revision: id.uuidString, exerciseID: exercise?.id,
                                       weight: exercise?.sortedSets.last?.weight ?? 0,
                                       reps: Int(exercise?.sortedSets.last?.reps ?? Int16(exercise?.plannedReps ?? 8)))
        }
        set { sessionData = try? JSONEncoder().encode(newValue) }
    }
}

/// Conservative physical load steps. Unknown equipment uses the user's configured step.
enum EquipmentLoadStep {
    static func value(name: String, unit: String?, preferred: Double = 2.5) -> Double {
        let fallback = preferred.isFinite && preferred > 0 && preferred <= 20 ? preferred : 2.5
        guard unit == "kg" || unit == "lb" else { return fallback }
        let name = name.lowercased()
        if name.contains("barbell") { return unit == "kg" ? 2.5 : 5 }
        if name.contains("dumbbell") { return unit == "kg" ? 1 : 2.5 }
        return fallback
    }
}

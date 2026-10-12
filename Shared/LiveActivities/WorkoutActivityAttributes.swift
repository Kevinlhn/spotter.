import ActivityKit
import Foundation

/// The small, persisted snapshot shared by the app and its Live Activity extension.
/// It deliberately contains no Core Data objects or private notes.
nonisolated struct WorkoutActivityAttributes: ActivityAttributes {
    nonisolated struct ContentState: Codable, Hashable {
        var exerciseName: String
        var exerciseNumber: Int
        var exerciseCount: Int
        var loggedSets: Int
        var targetSets: Int
        var sessionSets: Int
        var restEndsAt: Date?
        var lastSet: String?
        var revision: String? = nil
        var currentWeight: Double? = nil
        var currentReps: Int? = nil
        var weightUnit: String? = nil
        var setNumber: Int? = nil
        var editingSet: Bool? = nil
        var targetReps: String? = nil

        var finishedExercise: Bool { targetSets > 0 && loggedSets >= targetSets && editingSet != true }
        func isResting(now: Date = .now, isStale: Bool = false) -> Bool {
            guard let restEndsAt else { return false }
            return !isStale && restEndsAt > now
        }
    }

    var workoutID: UUID
    var workoutName: String
    var startedAt: Date

    static func resumeURL(workoutID: UUID) -> URL {
        URL(string: "spotter://workout/\(workoutID.uuidString)")!
    }
}

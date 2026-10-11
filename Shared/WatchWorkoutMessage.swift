import Foundation

/// Versioned values only. The iPhone remains the sole owner of recorded sets.
nonisolated struct WatchWorkoutSnapshot: Codable, Equatable, Sendable {
    var workoutID: UUID
    var revision: String
    var workoutName: String
    var exerciseName: String
    var exerciseNumber: Int
    var exerciseCount: Int
    var loggedSets: Int
    var targetSets: Int
    var sessionSets: Int
    var weight: Double
    var reps: Int
    var unit: String
    var restEndsAt: Date?
    var editingSet: Bool

    var finishedExercise: Bool { loggedSets >= targetSets }
    func isResting(at date: Date) -> Bool { restEndsAt.map { $0 > date } ?? false }
}

nonisolated enum WatchWorkoutAction: String, Codable, Sendable {
    case complete, undo, skipRest, nextExercise, previousExercise
    case weightUp, weightDown, repsUp, repsDown
}

nonisolated struct WatchWorkoutRequest: Codable, Sendable {
    var version = 1
    var id = UUID()
    var workoutID: UUID?
    var revision: String?
    /// nil requests a fresh snapshot without changing the workout.
    var action: WatchWorkoutAction?
}

nonisolated struct WatchWorkoutEnvelope: Codable, Equatable, Sendable {
    var version = 1
    var installationID: String
    var sequence: Int
    var updatedAt: Date
    var workout: WatchWorkoutSnapshot?

    func supersedes(_ previous: Self?) -> Bool {
        guard version == 1 else { return false }
        guard let previous else { return true }
        return installationID != previous.installationID || sequence >= previous.sequence
    }
}

nonisolated struct WatchWorkoutReply: Codable, Sendable {
    enum Outcome: String, Codable, Sendable { case refreshed, applied, stale, failed }
    var requestID: UUID
    var outcome: Outcome
    var envelope: WatchWorkoutEnvelope?
    var message: String?
}

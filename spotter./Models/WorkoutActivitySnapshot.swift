import Foundation
import CoreData

/// A small, immutable projection of the active workout. ActivityKit never receives managed objects.
struct WorkoutActivitySnapshot: Hashable {
    let workoutID: UUID
    let workoutName: String
    let startedAt: Date
    let content: WorkoutActivityAttributes.ContentState

    var attributes: WorkoutActivityAttributes {
        WorkoutActivityAttributes(workoutID: workoutID, workoutName: workoutName, startedAt: startedAt)
    }

    @MainActor
    static func make(
        workout: WorkoutEntity?, selectedExerciseID: UUID? = nil,
        restUntil: TimeInterval? = nil, now: Date = .now
    ) -> Self? {
        guard let workout, !workout.isDeleted, workout.managedObjectContext != nil,
              workout.workoutStatus == .active else { return nil }
        let exercises = workout.sortedExercises
        let session = workout.sessionState
        let index = exercises.firstIndex { $0.id == (selectedExerciseID ?? session.exerciseID) } ?? 0
        let exercise = exercises.indices.contains(index) ? exercises[index] : nil
        let lastSet = exercise?.sortedSets.last.map { set in
            let load = set.weight == 0 ? "Bodyweight" : "\(set.weight.formatted(.number.precision(.fractionLength(0...2)))) \(workout.weightLabel)"
            return "\(load) × \(set.reps) reps"
        }
        let restUntil = restUntil ?? session.restUntil
        let restEndsAt = restUntil.isFinite && restUntil > now.timeIntervalSince1970
            ? Date(timeIntervalSince1970: restUntil) : nil
        return Self(
            workoutID: workout.id, workoutName: workout.name, startedAt: workout.date,
            content: .init(
                exerciseName: exercise?.name ?? "Workout in progress",
                exerciseNumber: exercise == nil ? 0 : index + 1,
                exerciseCount: exercises.count,
                loggedSets: exercise?.sortedSets.count ?? 0,
                targetSets: exercise?.plannedSets ?? 0,
                sessionSets: exercises.reduce(0) { $0 + $1.sortedSets.count },
                restEndsAt: restEndsAt, lastSet: lastSet,
                revision: session.revision, currentWeight: session.weight, currentReps: session.reps,
                weightUnit: workout.weightLabel,
                setNumber: exercise?.sortedSets.firstIndex(where: { $0.id == session.selectedSetID }).map { $0 + 1 } ?? (exercise?.sortedSets.count ?? 0) + 1,
                editingSet: session.selectedSetID != nil,
                targetReps: exercise.map { $0.repRange.lowerBound == $0.repRange.upperBound ? "\($0.plannedReps)" : "\($0.repRange.lowerBound)–\($0.repRange.upperBound)" }
            )
        )
    }
}

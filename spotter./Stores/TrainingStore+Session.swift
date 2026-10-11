import Foundation
import CoreData

extension TrainingStore {
    enum CommandResult { case applied, stale, failed }

    /// No suspension between revision validation, mutation and save. Retries of an old
    /// rendered button cannot log twice, undo twice, or adjust a newly selected exercise.
    @discardableResult
    func performWorkoutAction(_ action: WorkoutAction, workout: WorkoutEntity,
                              expectedRevision: String, now: Date = .now,
                              preferences suppliedPreferences: TrainingPreferences? = nil) -> CommandResult {
        guard workout.managedObjectContext === context, !workout.isDeleted,
              workout.workoutStatus == .active, workout.sessionState.revision == expectedRevision else { return .stale }
        let preferences = suppliedPreferences ?? TrainingPreferences.load()
        var state = workout.sessionState
        let exercises = workout.sortedExercises
        guard let index = exercises.firstIndex(where: { $0.id == state.exerciseID }) ?? (exercises.isEmpty ? nil : 0) else { return .stale }
        let exercise = exercises[index]
        let sets = exercise.sortedSets
        state.exerciseID = exercise.id
        switch action {
        case .complete:
            guard state.weight.isFinite, (0...10000).contains(state.weight), (1...999).contains(state.reps) else { return .failed }
            if let id = state.selectedSetID {
                guard let set = sets.first(where: { $0.id == id }) else { return .stale }
                set.weight = state.weight; set.reps = Int16(state.reps)
            } else {
                let set = WorkoutSetEntity.insert(in: context)
                set.id = UUID(); set.exercise = exercise; set.weight = state.weight; set.reps = Int16(state.reps)
                set.timestamp = max(now, (sets.last?.timestamp ?? .distantPast).addingTimeInterval(0.001))
            }
            state.selectedSetID = nil
            let rest = exercise.restOverrideSeconds ?? preferences.restSeconds
            state.restUntil = rest > 0 ? now.timeIntervalSince1970 + Double(rest) : 0
        case .undo:
            guard let last = exercises.flatMap(\.sortedSets).max(by: { ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast) }),
                  let owner = last.exercise else { return .stale }
            state.exerciseID = owner.id; state.selectedSetID = nil
            state.weight = last.weight; state.reps = Int(last.reps); state.restUntil = 0
            context.delete(last)
        case .previousExercise, .nextExercise:
            let newIndex = index + (action == .nextExercise ? 1 : -1)
            guard exercises.indices.contains(newIndex) else { return .stale }
            state = entryState(for: exercises[newIndex], keeping: state)
        case .previousSet, .nextSet:
            let position = sets.firstIndex(where: { $0.id == state.selectedSetID }) ?? sets.count
            let next = min(sets.count, max(0, position + (action == .nextSet ? 1 : -1)))
            if next < sets.count {
                state.selectedSetID = sets[next].id; state.weight = sets[next].weight; state.reps = Int(sets[next].reps)
            } else { state.selectedSetID = nil }
        case .rest:
            let rest = exercise.restOverrideSeconds ?? preferences.restSeconds
            state.restUntil = rest > 0 ? now.timeIntervalSince1970 + Double(rest) : 0
        case .skipRest: state.restUntil = 0
        case .weightDown, .weightUp:
            let step = EquipmentLoadStep.value(name: exercise.name, unit: workout.weightUnit, preferred: preferences.weightStep)
            state.weight = min(10000, max(0, ((state.weight + (action == .weightUp ? step : -step)) * 100).rounded() / 100))
        case .repsDown, .repsUp: state.reps = min(999, max(1, state.reps + (action == .repsUp ? 1 : -1)))
        }
        workout.sessionState = state
        return persist() ? .applied : .failed
    }

    func selectExercise(_ id: UUID, workout: WorkoutEntity) {
        guard workout.managedObjectContext === context, !workout.isDeleted, workout.workoutStatus == .active, let exercise = workout.sortedExercises.first(where: { $0.id == id }) else { return }
        workout.sessionState = entryState(for: exercise, keeping: workout.sessionState)
        persist()
    }

    func setEntry(workout: WorkoutEntity, weight: Double, reps: Int) {
        guard workout.managedObjectContext === context, !workout.isDeleted, workout.workoutStatus == .active, weight.isFinite, (0...10000).contains(weight), (1...999).contains(reps) else { return }
        var state = workout.sessionState
        guard state.weight != weight || state.reps != reps else { return }
        state.weight = weight; state.reps = reps; workout.sessionState = state
        persist()
    }

    func setRest(workout: WorkoutEntity, until: Double) {
        guard workout.managedObjectContext === context, !workout.isDeleted, workout.workoutStatus == .active, until.isFinite else { return }
        var state = workout.sessionState
        state.restUntil = max(0, until); workout.sessionState = state
        persist()
    }

    func entryState(for exercise: ExerciseEntity, keeping state: WorkoutSessionState) -> WorkoutSessionState {
        var result = state
        result.exerciseID = exercise.id; result.selectedSetID = nil
        let previous = exercise.sortedSets.last ?? previousSet(for: exercise)
        result.weight = exercise.sortedSets.last?.weight ?? exercise.targetWeight?.doubleValue ?? previous?.weight ?? 0
        result.reps = exercise.targetWeight != nil ? exercise.repRange.lowerBound : previous.map { Int($0.reps) } ?? exercise.plannedReps
        return result
    }
}

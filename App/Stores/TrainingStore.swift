import Foundation
import CoreData
import Combine

@MainActor
final class TrainingStore: ObservableObject {
    @Published private(set) var workouts: [WorkoutEntity] = []
    @Published private(set) var library: [ExerciseTemplateEntity] = []
    @Published var error: String?
    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext? = nil) {
        self.context = context ?? Persistence.shared.container.viewContext
        reload()
    }

    var templates: [WorkoutEntity] {
        workouts.filter { $0.workoutStatus == .template }.sorted {
            let comparison = $0.name.localizedCaseInsensitiveCompare($1.name)
            return comparison == .orderedSame ? $0.id.uuidString < $1.id.uuidString : comparison == .orderedAscending
        }
    }
    var completed: [WorkoutEntity] { workouts.filter { $0.workoutStatus == .completed && $0.date <= Date() } }
    var active: WorkoutEntity? { workouts.first { $0.workoutStatus == .active } }
    var scheduled: [WorkoutEntity] {
        workouts.filter { $0.workoutStatus == .scheduled }.sorted {
            $0.calendarDate == $1.calendarDate ? $0.id.uuidString < $1.id.uuidString : $0.calendarDate < $1.calendarDate
        }
    }
    var thisWeek: [WorkoutEntity] {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: Date()) else { return [] }
        return completed.filter { interval.contains($0.date) }
    }
    var totalSets: Int { completed.reduce(0) { $0 + $1.sortedExercises.reduce(0) { $0 + $1.sortedSets.count } } }

    func entries(on date: Date, calendar: Calendar = .current) -> [WorkoutEntity] {
        workouts.filter { $0.workoutStatus != .template && calendar.isDate($0.calendarDate, inSameDayAs: date) }
            .sorted {
                if $0.calendarDate != $1.calendarDate { return $0.calendarDate < $1.calendarDate }
                return $0.id.uuidString < $1.id.uuidString
            }
    }

    func reload() {
        do {
            let request = WorkoutEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            request.relationshipKeyPathsForPrefetching = ["exercises", "exercises.sets"]
            workouts = try context.fetch(request).sorted {
                $0.date == $1.date ? $0.id.uuidString < $1.id.uuidString : $0.date > $1.date
            }
            let templates = ExerciseTemplateEntity.fetchRequest()
            templates.sortDescriptors = [NSSortDescriptor(key: "isFavorite", ascending: false), NSSortDescriptor(key: "name", ascending: true)]
            library = try context.fetch(templates)
        } catch { self.error = "Couldn’t load your training data. \(error.localizedDescription)" }
    }

    @discardableResult
    func persist() -> Bool {
        do {
            for workout in workouts where !workout.isDeleted && workout.workoutStatus == .active {
                var state = workout.sessionState
                state.revision = UUID().uuidString
                workout.sessionState = state
            }
            try context.save(); error = nil; reload(); return true
        }
        catch { context.rollback(); reload(); self.error = "Your change couldn’t be saved. Please try again. \(error.localizedDescription)"; return false }
    }

    /// Dates belong to workout instances; reusable templates never acquire a schedule.
    func save(_ draft: TrainingDraft, start: Bool) -> WorkoutEntity? {
        save(draft, status: start ? .active : .scheduled)
    }

    func saveTemplate(_ draft: TrainingDraft) -> WorkoutEntity? {
        save(draft, status: .template)
    }

    private func save(_ draft: TrainingDraft, status: WorkoutStatus) -> WorkoutEntity? {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !draft.moves.isEmpty,
              draft.moves.allSatisfy({ !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
              Set(draft.moves.map(\.id)).count == draft.moves.count else {
            error = "Give your workout a name and add an exercise before saving."
            return nil
        }
        guard draft.moves.allSatisfy({ validPrescription($0) && validTargets(sets: $0.targetSets, reps: $0.targetReps, restSeconds: $0.restSeconds) }) else {
            error = "Choose between 1 and 20 sets, 1 and 999 reps, and a rest time up to 10 minutes."
            return nil
        }
        if status == .active, active != nil { error = "You already have a session in progress. Resume or finish it before starting another."; return nil }
        let editableStatus: WorkoutStatus = status == .template ? .template : .scheduled
        if let existing = draft.existing, !owns(existing) || existing.workoutStatus != editableStatus {
            error = status == .template ? "Only saved workouts can be edited as templates." : "Only planned workouts can be edited here."
            return nil
        }
        let workout = draft.existing ?? WorkoutEntity.insert(in: context)
        if draft.existing == nil { workout.id = UUID(); workout.weightUnit = draft.weightUnit }
        workout.name = name
        workout.notes = draft.notes.isEmpty ? nil : draft.notes
        if status == .scheduled {
            workout.scheduledDate = draft.date
            workout.date = draft.date
        } else if status == .active {
            // An edited plan keeps its assigned date even when started on another day.
            workout.scheduledDate = draft.existing == nil ? nil : draft.date
            workout.date = Date()
        } else {
            workout.scheduledDate = nil
            if draft.existing == nil { workout.date = Date() }
        }
        workout.workoutStatus = status
        let retainedIDs = Set(draft.moves.map(\.id))
        let old = workout.sortedExercises
        let lineupStart = Date()
        for exercise in old where !retainedIDs.contains(exercise.id) { context.delete(exercise) }
        for (index, move) in draft.moves.enumerated() {
            let exercise = old.first { $0.id == move.id } ?? ExerciseEntity.insert(in: context)
            if exercise.isInserted { exercise.id = move.id }
            exercise.name = move.name.trimmingCharacters(in: .whitespacesAndNewlines)
            exercise.muscleGroup = move.muscle
            exercise.targetSets = Int16(move.targetSets)
            exercise.targetReps = Int16(move.targetReps)
            exercise.targetWeight = move.targetWeight.map(NSNumber.init(value:))
            exercise.targetRepMinimum = Int16(move.targetRepMinimum ?? 0)
            exercise.restSeconds = Int16(move.restSeconds ?? -1)
            exercise.createdAt = lineupStart.addingTimeInterval(Double(index) * 0.001)
            exercise.workout = workout
            exercise.isCustom = true
        }
        if status == .active, workout.sessionData == nil, let first = workout.sortedExercises.first {
            workout.sessionState = entryState(for: first, keeping: workout.sessionState)
        }
        return persist() ? workout : nil
    }

    func begin(_ workout: WorkoutEntity) -> Bool {
        guard owns(workout) else { error = "This workout is no longer available."; return false }
        if let active, active != workout { error = "Finish your current session before starting another."; return false }
        if workout.workoutStatus == .active { error = nil; return true }
        guard workout.workoutStatus == .scheduled else {
            error = "Create a new copy of this workout before starting it."
            return false
        }
        guard !workout.sortedExercises.isEmpty else {
            error = "Add an exercise to this workout in Plan before starting it."
            return false
        }
        workout.scheduledDate = workout.scheduledDate ?? workout.date
        workout.workoutStatus = .active
        workout.date = Date()
        if let first = workout.sortedExercises.first { workout.sessionState = entryState(for: first, keeping: workout.sessionState) }
        return persist()
    }

    func finish(_ workout: WorkoutEntity) -> Bool {
        guard owns(workout), workout.workoutStatus == .active else { error = "Start this workout before finishing it."; return false }
        let sets = workout.sortedExercises.flatMap(\.sortedSets)
        guard !sets.isEmpty else { error = "Log at least one set before finishing your workout."; return false }
        guard sets.allSatisfy({ validSet(weight: $0.weight, reps: Int($0.reps)) }) else {
            error = "Correct or remove sets with an invalid weight or rep count before finishing."
            return false
        }
        var state = workout.sessionState
        state.restUntil = 0; workout.sessionState = state
        workout.workoutStatus = .completed
        return persist()
    }

    @discardableResult
    func delete(_ workout: WorkoutEntity) -> Bool {
        guard owns(workout) else { error = "This workout is no longer available."; return false }
        context.delete(workout)
        return persist()
    }

    @discardableResult
    func deleteSet(_ set: WorkoutSetEntity) -> Bool {
        guard owns(set), let workout = set.exercise?.workout, owns(workout), workout.workoutStatus == .active else {
            error = "Resume this workout before removing a set."
            return false
        }
        context.delete(set)
        return persist()
    }

    @discardableResult
    func updateSet(_ set: WorkoutSetEntity, weight: Double, reps: Int) -> Bool {
        guard owns(set), let workout = set.exercise?.workout, owns(workout), workout.workoutStatus == .active else {
            error = "Resume this workout before editing a set."
            return false
        }
        guard validSet(weight: weight, reps: reps) else {
            error = "Enter a weight of 0 or more and between 1 and 999 reps."
            return false
        }
        set.weight = weight
        set.reps = Int16(reps)
        return persist()
    }

    func logSet(exercise: ExerciseEntity, weight: Double, reps: Int) -> Bool {
        guard owns(exercise), let workout = exercise.workout, owns(workout), workout.workoutStatus == .active else {
            error = "Start or resume this workout before logging a set."
            return false
        }
        guard validSet(weight: weight, reps: reps) else { error = "Enter a weight of 0 or more and between 1 and 999 reps."; return false }
        let set = WorkoutSetEntity.insert(in: context)
        set.id = UUID()
        set.timestamp = max(Date(), (exercise.sortedSets.last?.timestamp ?? .distantPast).addingTimeInterval(0.001))
        set.weight = weight; set.reps = Int16(reps); set.exercise = exercise
        return persist()
    }

    func addMove(_ move: TrainingMove, to workout: WorkoutEntity) {
        let name = move.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard owns(workout), workout.workoutStatus == .active, !name.isEmpty else { return }
        guard validPrescription(move), validTargets(sets: move.targetSets, reps: move.targetReps, restSeconds: move.restSeconds) else {
            error = "Choose between 1 and 20 sets, 1 and 999 reps, and a rest time up to 10 minutes."
            return
        }
        let appendedAt = max(Date(), (workout.sortedExercises.last?.createdAt ?? .distantPast).addingTimeInterval(0.001))
        let exercise = ExerciseEntity.insert(in: context)
        exercise.id = UUID(); exercise.name = name; exercise.muscleGroup = move.muscle
        exercise.targetSets = Int16(move.targetSets); exercise.targetReps = Int16(move.targetReps)
        exercise.targetWeight = move.targetWeight.map(NSNumber.init(value:))
        exercise.targetRepMinimum = Int16(move.targetRepMinimum ?? 0)
        exercise.restSeconds = Int16(move.restSeconds ?? -1)
        exercise.createdAt = appendedAt; exercise.workout = workout; exercise.isCustom = true
        persist()
    }

    @discardableResult
    func updateExerciseTargets(_ exercise: ExerciseEntity, sets: Int, reps: Int, restSeconds: Int?, minimumReps: Int? = nil, targetWeight: Double? = nil) -> Bool {
        guard owns(exercise), let workout = exercise.workout, owns(workout), workout.workoutStatus == .active else {
            error = "Start or resume this workout before changing its targets."
            return false
        }
        guard validTargets(sets: sets, reps: reps, restSeconds: restSeconds) else {
            error = "Choose between 1 and 20 sets, 1 and 999 reps, and a rest time up to 10 minutes."
            return false
        }
        guard targetWeight.map({ $0.isFinite && (0...10000).contains($0) }) ?? true else {
            error = "Enter a valid planned weight."; return false
        }
        exercise.targetWeight = targetWeight.map(NSNumber.init(value:))
        exercise.targetSets = Int16(sets)
        exercise.targetReps = Int16(reps)
        exercise.targetRepMinimum = Int16(min(max(minimumReps ?? 0, 0), reps))
        exercise.restSeconds = Int16(restSeconds ?? -1)
        return persist()
    }

    func saveToLibrary(_ move: TrainingMove) {
        let name = move.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { error = "Give your exercise a name before saving."; return }
        guard !library.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) else { error = nil; return }
        let template = ExerciseTemplateEntity.insert(in: context)
        template.id = UUID(); template.name = name; template.primaryMuscle = move.muscle
        template.createdAt = Date(); template.isCustom = true; template.isFavorite = false
        persist()
    }

    @discardableResult
    func updateLibraryExercise(_ exercise: ExerciseTemplateEntity, name: String, muscle: String) -> Bool {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard owns(exercise), exercise.isCustom, !name.isEmpty else { error = "Enter an exercise name."; return false }
        guard !library.contains(where: { $0 != exercise && ExerciseCatalog.key($0.name) == ExerciseCatalog.key(name) }) else {
            error = "An exercise with this name already exists."; return false
        }
        exercise.name = name; exercise.primaryMuscle = muscle
        return persist()
    }

    func previousSet(for exercise: ExerciseEntity) -> WorkoutSetEntity? {
        for workout in completed where workout != exercise.workout && workout.weightUnit == exercise.workout?.weightUnit {
            let sets = workout.sortedExercises
                .filter { $0.name.caseInsensitiveCompare(exercise.name) == .orderedSame }
                .flatMap(\.sortedSets)
                .filter { validSet(weight: $0.weight, reps: Int($0.reps)) }
            if let latest = sets.max(by: {
                let left = $0.timestamp ?? .distantPast
                let right = $1.timestamp ?? .distantPast
                return left == right ? $0.id.uuidString < $1.id.uuidString : left < right
            }) { return latest }
        }
        return nil
    }

    private func owns(_ object: NSManagedObject) -> Bool {
        object.managedObjectContext === context && !object.isDeleted
    }

    private func validSet(weight: Double, reps: Int) -> Bool {
        weight.isFinite && weight >= 0 && (1...999).contains(reps)
    }

    private func validPrescription(_ move: TrainingMove) -> Bool {
        (move.targetWeight.map { $0.isFinite && (0...10000).contains($0) } ?? true) &&
        (move.targetRepMinimum.map { $0 >= 1 && $0 <= move.targetReps } ?? true)
    }

    private func validTargets(sets: Int, reps: Int, restSeconds: Int?) -> Bool {
        (1...20).contains(sets) && (1...999).contains(reps) && (restSeconds.map { (0...600).contains($0) } ?? true)
    }
}

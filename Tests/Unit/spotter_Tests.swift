import Testing
import CoreData
@testable import spotter_

@MainActor
struct spotter_Tests {
    @Test func launchPreloadOpensAnIsolatedStore() async throws {
        let persistence = try await Persistence.load(inMemory: true)
        let store = TrainingStore(context: persistence.container.viewContext)
        #expect(store.error == nil)
        #expect(store.workouts.isEmpty)
        #expect(store.library.isEmpty)
    }

    func makeStore() -> TrainingStore { TrainingStore(context: Persistence(inMemory: true).container.viewContext) }

    @Test func draftDoesNotCreateRecordUntilSaved() {
        let store = makeStore()
        _ = TrainingDraft(routine: TrainingRoutine.starters[0])
        #expect(store.workouts.isEmpty)
    }

    @Test func workoutLifecycleAndResumePreserveSets() throws {
        let store = makeStore()
        let draft = TrainingDraft(routine: TrainingRoutine.starters[0])
        let workout = try #require(store.save(draft, start: true))
        #expect(store.active == workout)
        #expect(store.completed.isEmpty)
        #expect(!store.finish(workout))
        store.error = nil
        let exercise = try #require(workout.sortedExercises.first)
        #expect(store.logSet(exercise: exercise, weight: 20, reps: 8))
        store.reload()
        #expect(store.active?.sortedExercises.first?.sortedSets.count == 1)
        #expect(store.finish(workout))
        #expect(store.completed.count == 1)
        #expect(store.totalSets == 1)
        #expect(store.active == nil)
    }

    @Test func repeatCreatesFreshExerciseIDsAndNoCopiedSets() throws {
        let store = makeStore()
        let first = try #require(store.save(TrainingDraft(routine: TrainingRoutine.starters[0]), start: true))
        let exercise = try #require(first.sortedExercises.first)
        #expect(store.logSet(exercise: exercise, weight: 12, reps: 10))
        #expect(store.finish(first))
        let repeated = try #require(store.save(TrainingDraft(workout: first, repeatWorkout: true), start: true))
        #expect(first.id != repeated.id)
        #expect(Set(first.sortedExercises.map(\.id)).isDisjoint(with: repeated.sortedExercises.map(\.id)))
        #expect(repeated.sortedExercises.allSatisfy { $0.sortedSets.isEmpty })
        #expect(first.sortedExercises.first?.sortedSets.count == 1)
    }

    @Test func editingPlanPreservesRetainedExercisesAndSets() throws {
        let store = makeStore()
        let workout = try #require(store.save(TrainingDraft(routine: TrainingRoutine.starters[0]), start: false))
        let exercise = try #require(workout.sortedExercises.first)
        // Older versions allowed sets on a plan. Editing must retain that data.
        let legacySet = WorkoutSetEntity.insert(in: store.context)
        legacySet.id = UUID(); legacySet.timestamp = Date(); legacySet.weight = 10
        legacySet.reps = 8; legacySet.exercise = exercise
        #expect(store.persist())
        var edit = TrainingDraft(workout: workout)
        edit.name = "Updated plan"
        edit.moves.reverse()
        #expect(store.save(edit, start: false) != nil)
        #expect(workout.sortedExercises.map(\.id) == edit.moves.map(\.id))
        #expect(workout.sortedExercises.last?.id == exercise.id)
        #expect(exercise.sortedSets.count == 1)
        #expect(exercise.sortedSets.first == legacySet)
        #expect(store.completed.isEmpty)
    }

    @Test func invalidSetsAndSecondActiveWorkoutAreRejected() throws {
        let store = makeStore()
        let workout = try #require(store.save(TrainingDraft(routine: TrainingRoutine.starters[0]), start: true))
        let exercise = try #require(workout.sortedExercises.first)
        #expect(!store.logSet(exercise: exercise, weight: -1, reps: 8))
        #expect(!store.logSet(exercise: exercise, weight: .infinity, reps: 8))
        #expect(!store.logSet(exercise: exercise, weight: 10, reps: 0))
        #expect(!store.logSet(exercise: exercise, weight: 10, reps: 1000))
        #expect(store.save(TrainingDraft(routine: TrainingRoutine.starters[1]), start: true) == nil)
        #expect(store.workouts.count == 1)
        #expect(exercise.sortedSets.isEmpty)
    }

    @Test func onlyActiveWorkoutsAcceptSetsOrCanFinish() throws {
        let store = makeStore()
        let workout = try #require(store.save(TrainingDraft(routine: TrainingRoutine.starters[0]), start: false))
        let exercise = try #require(workout.sortedExercises.first)
        #expect(!store.logSet(exercise: exercise, weight: 0, reps: 10))
        #expect(!store.finish(workout))
        #expect(workout.workoutStatus == .scheduled)
        #expect(store.begin(workout))
        #expect(store.logSet(exercise: exercise, weight: 0, reps: 10))
        #expect(store.finish(workout))
        #expect(!store.logSet(exercise: exercise, weight: 10, reps: 10))
        #expect(!store.finish(workout))
        #expect(exercise.sortedSets.count == 1)
    }

    @Test func resumingDoesNotResetSessionDate() throws {
        let store = makeStore()
        let workout = try #require(store.save(TrainingDraft(routine: TrainingRoutine.starters[0]), start: true))
        let started = Date().addingTimeInterval(-300)
        workout.date = started
        #expect(store.persist())
        #expect(store.begin(workout))
        #expect(workout.date == started)
    }

    @Test func addingMoveAppendsAfterLineupEvenWhenItsDatesAreInTheFuture() throws {
        let store = makeStore()
        let workout = try #require(store.save(TrainingDraft(routine: TrainingRoutine.starters[0]), start: true))
        let originalIDs = workout.sortedExercises.map(\.id)
        for (index, exercise) in workout.sortedExercises.enumerated() {
            exercise.createdAt = Date().addingTimeInterval(60 + Double(index))
        }
        #expect(store.persist())
        store.addMove(TrainingMove(name: "Bicep Curl", muscle: "Biceps"), to: workout)
        #expect(Array(workout.sortedExercises.dropLast().map(\.id)) == originalIDs)
        #expect(workout.sortedExercises.last?.name == "Bicep Curl")
        store.reload()
        #expect(workout.sortedExercises.last?.name == "Bicep Curl")
    }

    @Test func finishRejectsInvalidLegacySetsUntilCorrected() throws {
        let store = makeStore()
        let workout = try #require(store.save(TrainingDraft(routine: TrainingRoutine.starters[0]), start: true))
        let exercise = try #require(workout.sortedExercises.first)
        #expect(store.logSet(exercise: exercise, weight: 0, reps: 10))
        let set = try #require(exercise.sortedSets.first)
        set.reps = 0
        #expect(store.persist())
        #expect(!store.finish(workout))
        #expect(workout.workoutStatus == .active)
        set.reps = 10
        #expect(store.finish(workout))
    }

    @Test func successfulSaveClearsEarlierError() throws {
        let store = makeStore()
        let workout = try #require(store.save(TrainingDraft(routine: TrainingRoutine.starters[0]), start: true))
        #expect(!store.finish(workout))
        #expect(store.error != nil)
        store.saveToLibrary(TrainingMove(name: "  Custom row  ", muscle: "Back"))
        #expect(store.error == nil)
        #expect(store.library.first?.name == "Custom row")
        store.error = "Earlier error"
        store.saveToLibrary(TrainingMove(name: "Custom row", muscle: "Back"))
        #expect(store.error == nil)
        #expect(store.library.count == 1)
    }

    @Test func unitIsRetainedWhenEditingAndRepeatingAndLastSetMatchesUnit() throws {
        let store = makeStore()
        var draft = TrainingDraft(routine: TrainingRoutine.starters[0])
        draft.weightUnit = "kg"
        let workout = try #require(store.save(draft, start: false))
        var edited = TrainingDraft(workout: workout)
        edited.weightUnit = "lb"
        #expect(store.save(edited, start: true) == workout)
        #expect(workout.weightUnit == "kg")
        let exercise = try #require(workout.sortedExercises.first)
        #expect(store.logSet(exercise: exercise, weight: 20, reps: 8))
        #expect(store.finish(workout))
        var repeatDraft = TrainingDraft(workout: workout, repeatWorkout: true)
        #expect(repeatDraft.weightUnit == "kg")
        repeatDraft.weightUnit = "lb"
        let repeated = try #require(store.save(repeatDraft, start: true))
        let repeatedExercise = try #require(repeated.sortedExercises.first)
        #expect(store.previousSet(for: repeatedExercise) == nil)
        repeated.weightUnit = "kg"
        #expect(store.previousSet(for: repeatedExercise) == exercise.sortedSets.last)
    }

    @Test func removingPlannedExerciseDeletesOnlyItsSets() throws {
        let store = makeStore()
        let workout = try #require(store.save(TrainingDraft(routine: TrainingRoutine.starters[0]), start: false))
        let removed = try #require(workout.sortedExercises.first)
        let removedID = removed.id
        let legacySet = WorkoutSetEntity.insert(in: store.context)
        legacySet.id = UUID(); legacySet.timestamp = Date(); legacySet.weight = 10
        legacySet.reps = 8; legacySet.exercise = removed
        #expect(store.persist())
        var edited = TrainingDraft(workout: workout)
        edited.moves.removeFirst()
        #expect(store.save(edited, start: false) == workout)
        #expect(!workout.sortedExercises.contains { $0.id == removedID })
        #expect(workout.sortedExercises.map(\.id) == edited.moves.map(\.id))
        #expect(try store.context.count(for: WorkoutSetEntity.fetchRequest()) == 0)
    }

    @Test func previousSetUsesLatestSetAcrossRepeatedExerciseEntries() throws {
        let store = makeStore()
        var draft = TrainingDraft()
        draft.name = "Rows"
        draft.moves = [TrainingMove(name: "Dumbbell Row", muscle: "Back"), TrainingMove(name: "Dumbbell Row", muscle: "Back")]
        let workout = try #require(store.save(draft, start: true))
        let first = try #require(workout.sortedExercises.first)
        let second = try #require(workout.sortedExercises.last)
        #expect(store.logSet(exercise: first, weight: 10, reps: 8))
        #expect(store.logSet(exercise: second, weight: 15, reps: 8))
        first.sortedSets.first?.timestamp = Date().addingTimeInterval(-60)
        #expect(store.finish(workout))
        let repeated = try #require(store.save(TrainingDraft(workout: workout, repeatWorkout: true), start: true))
        let repeatedExercise = try #require(repeated.sortedExercises.first)
        #expect(store.previousSet(for: repeatedExercise)?.weight == 15)
    }

    @Test func exerciseTargetsSurviveSavingEditingAndRepeatingWithoutCopyingLoggedSets() throws {
        let store = makeStore()
        var draft = TrainingDraft()
        draft.name = "Custom training"
        draft.moves = [TrainingMove(name: "Squat", muscle: "Legs", targetSets: 5, targetReps: 6, restSeconds: 180)]
        let planned = try #require(store.save(draft, start: false))
        let workoutID = planned.id
        // Refetch from persisted storage, rather than just inspecting changed objects.
        store.context.reset()
        store.reload()
        let workout = try #require(store.workouts.first { $0.id == workoutID })
        let exercise = try #require(workout.sortedExercises.first)
        #expect(exercise.plannedSets == 5)
        #expect(exercise.plannedReps == 6)
        #expect(exercise.restOverrideSeconds == 180)
        var edit = TrainingDraft(workout: workout)
        #expect(edit.moves.first?.targetSets == 5)
        #expect(edit.moves.first?.targetReps == 6)
        #expect(edit.moves.first?.restSeconds == 180)
        edit.moves[0].targetSets = 4
        #expect(store.save(edit, start: true) == workout)
        #expect(exercise.plannedSets == 4)
        #expect(store.logSet(exercise: exercise, weight: 60, reps: 6))
        #expect(store.finish(workout))
        let repeated = try #require(store.save(TrainingDraft(workout: workout, repeatWorkout: true), start: true))
        let repeatedExercise = try #require(repeated.sortedExercises.first)
        #expect(repeatedExercise.id != exercise.id)
        #expect(repeatedExercise.plannedSets == 4)
        #expect(repeatedExercise.plannedReps == 6)
        #expect(repeatedExercise.restOverrideSeconds == 180)
        #expect(repeatedExercise.sortedSets.isEmpty)
        #expect(exercise.sortedSets.count == 1)
    }

    @Test func activeTargetsPersistAndDistinguishGlobalRestFromRestOff() throws {
        let store = makeStore()
        let workout = try #require(store.save(TrainingDraft(routine: TrainingRoutine.starters[0]), start: true))
        let exercise = try #require(workout.sortedExercises.first)
        #expect(exercise.plannedSets == 3)
        #expect(exercise.plannedReps == 8)
        #expect(exercise.restOverrideSeconds == nil)
        #expect(store.updateExerciseTargets(exercise, sets: 20, reps: 999, restSeconds: 600))
        #expect(exercise.plannedSets == 20)
        #expect(exercise.plannedReps == 999)
        #expect(exercise.restOverrideSeconds == 600)
        #expect(store.updateExerciseTargets(exercise, sets: 1, reps: 1, restSeconds: 0))
        #expect(exercise.restSeconds == 0)
        #expect(exercise.restOverrideSeconds == 0)
        #expect(store.updateExerciseTargets(exercise, sets: 3, reps: 12, restSeconds: nil))
        let exerciseID = exercise.id
        store.context.reset()
        store.reload()
        let saved = try #require(store.active?.sortedExercises.first { $0.id == exerciseID })
        #expect(saved.plannedSets == 3)
        #expect(saved.plannedReps == 12)
        #expect(saved.restSeconds == -1)
        #expect(saved.restOverrideSeconds == nil)
        store.addMove(TrainingMove(name: "Plank", muscle: "Core", targetSets: 2, targetReps: 1, restSeconds: 0), to: try #require(store.active))
        #expect(store.active?.sortedExercises.last?.plannedSets == 2)
        #expect(store.active?.sortedExercises.last?.plannedReps == 1)
        #expect(store.active?.sortedExercises.last?.restOverrideSeconds == 0)
    }

    @Test func invalidTargetsDoNotCreateOrPartiallyChangeExercises() throws {
        let store = makeStore()
        let workout = try #require(store.save(TrainingDraft(routine: TrainingRoutine.starters[0]), start: true))
        let exercise = try #require(workout.sortedExercises.first)
        let invalidTargets: [(Int, Int, Int?)] = [
            (0, 8, nil), (21, 8, nil), (Int.max, 8, nil),
            (3, 0, nil), (3, 1000, nil), (3, Int.max, nil),
            (3, 8, -1), (3, 8, 601), (3, 8, Int.max)
        ]
        for (sets, reps, rest) in invalidTargets {
            #expect(!store.updateExerciseTargets(exercise, sets: sets, reps: reps, restSeconds: rest))
            #expect(exercise.targetSets == 3)
            #expect(exercise.targetReps == 8)
            #expect(exercise.restSeconds == -1)
            var invalidDraft = TrainingDraft()
            invalidDraft.name = "Invalid target"
            invalidDraft.moves = [TrainingMove(name: "Row", muscle: "Back", targetSets: sets, targetReps: reps, restSeconds: rest)]
            #expect(store.save(invalidDraft, start: false) == nil)
            store.addMove(invalidDraft.moves[0], to: workout)
        }
        #expect(store.workouts.count == 1)
        #expect(workout.sortedExercises.count == TrainingRoutine.starters[0].moves.count)
        #expect(!store.context.hasChanges)
    }

    @Test func onlyOwnedActiveExercisesAllowLiveTargetUpdates() throws {
        let store = makeStore()
        let workout = try #require(store.save(TrainingDraft(routine: TrainingRoutine.starters[0]), start: false))
        let exercise = try #require(workout.sortedExercises.first)
        #expect(!store.updateExerciseTargets(exercise, sets: 4, reps: 10, restSeconds: 90))
        #expect(store.begin(workout))
        let otherStore = makeStore()
        #expect(!otherStore.updateExerciseTargets(exercise, sets: 4, reps: 10, restSeconds: 90))
        #expect(store.updateExerciseTargets(exercise, sets: 4, reps: 10, restSeconds: 90))
        #expect(store.logSet(exercise: exercise, weight: 20, reps: 10))
        #expect(store.finish(workout))
        #expect(!store.updateExerciseTargets(exercise, sets: 5, reps: 10, restSeconds: 90))
        #expect(exercise.plannedSets == 4)
    }

    @Test func exportPreservesTargetsRestModesAndMultipleSetsInLoggingOrder() throws {
        let store = makeStore()
        var draft = TrainingDraft()
        draft.name = "Export session"
        draft.moves = [
            TrainingMove(name: "Row", muscle: "Back", targetSets: 4, targetReps: 10, restSeconds: 120),
            TrainingMove(name: "Plank", muscle: "Core", targetSets: 2, targetReps: 1, restSeconds: 0),
            TrainingMove(name: "Curl", muscle: "Biceps")
        ]
        let workout = try #require(store.save(draft, start: true))
        let exercise = try #require(workout.sortedExercises.first)
        #expect(store.logSet(exercise: exercise, weight: 10, reps: 10))
        #expect(store.logSet(exercise: exercise, weight: 15, reps: 8))
        let loggedAt = Date(timeIntervalSince1970: 1_700_000_000)
        exercise.sortedSets.first?.timestamp = loggedAt
        #expect(store.persist())
        let file = try SpotterExportManager.shared.exportJSONFile(from: store.context)
        defer { try? FileManager.default.removeItem(at: file) }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(SpotterExportManager.ExportPayload.self, from: Data(contentsOf: file))
        #expect(payload.version == 4)
        let exported = try #require(payload.workouts.first)
        #expect(exported.exercises.map(\.name) == draft.moves.map(\.name))
        #expect(exported.exercises.map(\.targetSets) == [4, 2, 3])
        #expect(exported.exercises.map(\.targetReps) == [10, 1, 8])
        #expect(exported.exercises.map(\.restSeconds) == [120, 0, nil])
        #expect(exported.exercises.first?.sets.map(\.weight) == [10, 15])
        #expect(exported.exercises.first?.sets.map(\.reps) == [10, 8])
        #expect(exported.exercises.first?.sets.first?.timestamp == loggedAt)
    }

    @Test(arguments: ["spotter_", "SpotterV2", "SpotterV3", "SpotterV4", "SpotterV5"])
    func migratingEarlierStoresPreservesWorkoutHistoryAndAddsDefaultTargets(sourceVersion: String) throws {
        let modelDirectory = try #require(Bundle(for: WorkoutEntity.self).url(forResource: "spotter_", withExtension: "momd"))
        let originalModel = try #require(NSManagedObjectModel(contentsOf: modelDirectory.appendingPathComponent("\(sourceVersion).mom")))
        let currentModel = try #require(NSManagedObjectModel(contentsOf: modelDirectory.appendingPathComponent("SpotterV6.mom")))
        #expect(currentModel.entitiesByName["WorkoutEntity"]?.attributesByName["sessionData"]?.isOptional == true)
        #expect(currentModel.entitiesByName["WorkoutEntity"]?.attributesByName["weightUnit"]?.isOptional == true)

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("spotter-migration-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("Training.sqlite")
        let workoutID = UUID(), exerciseID = UUID(), setID = UUID()
        let trainedAt = Date(timeIntervalSince1970: 1_700_000_000)

        // Write an actual legacy SQLite store, including V3 exercise targets when available.
        do {
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: originalModel)
            let persistentStore = try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL)
            let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            context.persistentStoreCoordinator = coordinator
            let workout = NSEntityDescription.insertNewObject(forEntityName: "WorkoutEntity", into: context)
            workout.setValue(workoutID, forKey: "id")
            workout.setValue("Original strength session", forKey: "name")
            workout.setValue(trainedAt, forKey: "date")
            workout.setValue("completed", forKey: "status")
            workout.setValue("Keep this training history", forKey: "notes")
            if sourceVersion != "spotter_" { workout.setValue("kg", forKey: "weightUnit") }
            let exercise = NSEntityDescription.insertNewObject(forEntityName: "ExerciseEntity", into: context)
            exercise.setValue(exerciseID, forKey: "id")
            exercise.setValue("Goblet Squat", forKey: "name")
            exercise.setValue("Legs", forKey: "muscleGroup")
            exercise.setValue(trainedAt, forKey: "createdAt")
            exercise.setValue(workout, forKey: "workout")
            if ["SpotterV3", "SpotterV4", "SpotterV5"].contains(sourceVersion) {
                exercise.setValue(5, forKey: "targetSets")
                exercise.setValue(6, forKey: "targetReps")
                exercise.setValue(120, forKey: "restSeconds")
            }
            let set = NSEntityDescription.insertNewObject(forEntityName: "WorkoutSetEntity", into: context)
            set.setValue(setID, forKey: "id")
            set.setValue(42.5, forKey: "weight")
            set.setValue(8, forKey: "reps")
            set.setValue(trainedAt.addingTimeInterval(60), forKey: "timestamp")
            set.setValue(exercise, forKey: "exercise")
            try context.save()
            context.reset()
            try coordinator.remove(persistentStore)
        }

        // Reopening this file with the same migration options as Persistence
        // must infer a mapping from every bundled legacy model to V4.
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: currentModel)
        let persistentStore = try coordinator.addPersistentStore(
            ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL,
            options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        )
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        defer { context.reset(); try? coordinator.remove(persistentStore) }
        let workouts = try context.fetch(WorkoutEntity.fetchRequest())
        #expect(workouts.count == 1)
        #expect(try context.count(for: ExerciseEntity.fetchRequest()) == 1)
        #expect(try context.count(for: WorkoutSetEntity.fetchRequest()) == 1)
        let migratedWorkout = try #require(workouts.first)
        #expect(migratedWorkout.id == workoutID)
        #expect(migratedWorkout.name == "Original strength session")
        #expect(migratedWorkout.date == trainedAt)
        #expect(migratedWorkout.scheduledDate == nil)
        #expect(migratedWorkout.calendarDate == trainedAt)
        #expect(migratedWorkout.workoutStatus == .completed)
        #expect(migratedWorkout.notes == "Keep this training history")
        #expect(migratedWorkout.weightUnit == (sourceVersion != "spotter_" ? "kg" : nil))
        let migratedExercise = try #require(migratedWorkout.sortedExercises.first)
        let migratedSet = try #require(migratedExercise.sortedSets.first)
        #expect(migratedExercise.id == exerciseID)
        #expect(migratedExercise.workout == migratedWorkout)
        #expect(migratedExercise.targetSets == (["SpotterV3", "SpotterV4", "SpotterV5"].contains(sourceVersion) ? 5 : 3))
        #expect(migratedExercise.targetReps == (["SpotterV3", "SpotterV4", "SpotterV5"].contains(sourceVersion) ? 6 : 8))
        #expect(migratedExercise.restSeconds == (["SpotterV3", "SpotterV4", "SpotterV5"].contains(sourceVersion) ? 120 : -1))
        #expect(migratedExercise.restOverrideSeconds == (["SpotterV3", "SpotterV4", "SpotterV5"].contains(sourceVersion) ? 120 : nil))
        #expect(migratedSet.id == setID)
        #expect(migratedSet.exercise == migratedExercise)
        #expect(migratedSet.weight == 42.5)
        #expect(migratedSet.reps == 8)
        #expect(migratedSet.timestamp == trainedAt.addingTimeInterval(60))
    }
}

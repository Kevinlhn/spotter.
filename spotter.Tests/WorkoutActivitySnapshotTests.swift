import Testing
import Foundation
import CoreData
@testable import spotter_

@MainActor
struct WorkoutActivitySnapshotTests {
    private func makeStore() -> TrainingStore {
        TrainingStore(context: Persistence(inMemory: true).container.viewContext)
    }

    @Test func onlyAnActivePersistedSessionCreatesASnapshot() throws {
        let store = makeStore()
        #expect(WorkoutActivitySnapshot.make(workout: nil) == nil)
        let template = try #require(store.saveTemplate(TrainingDraft(routine: TrainingRoutine.starters[0])))
        #expect(WorkoutActivitySnapshot.make(workout: template) == nil)
        let workout = try #require(store.save(TrainingDraft(template: template), start: false))
        #expect(WorkoutActivitySnapshot.make(workout: workout) == nil)
        #expect(store.begin(workout))
        #expect(WorkoutActivitySnapshot.make(workout: workout) != nil)
        #expect(store.logSet(exercise: try #require(workout.sortedExercises.first), weight: 20, reps: 8))
        #expect(store.finish(workout))
        #expect(WorkoutActivitySnapshot.make(workout: workout) == nil)
        #expect(store.delete(workout))
        #expect(WorkoutActivitySnapshot.make(workout: workout) == nil)
    }

    @Test func selectedExerciseTargetsAndSessionTotalsRemainDistinct() throws {
        let store = makeStore()
        var draft = TrainingDraft(routine: TrainingRoutine.starters[0])
        draft.weightUnit = "kg"
        draft.moves[1].targetSets = 4
        let workout = try #require(store.save(draft, start: true))
        let exercises = workout.sortedExercises
        #expect(store.logSet(exercise: exercises[0], weight: 20, reps: 8))
        #expect(store.logSet(exercise: exercises[1], weight: 42.5, reps: 10))
        #expect(store.logSet(exercise: exercises[1], weight: 45, reps: 9))
        let snapshot = try #require(WorkoutActivitySnapshot.make(workout: workout, selectedExerciseID: exercises[1].id))
        #expect(snapshot.workoutID == workout.id)
        #expect(snapshot.workoutName == workout.name)
        #expect(snapshot.startedAt == workout.date)
        #expect(snapshot.content.exerciseName == exercises[1].name)
        #expect(snapshot.content.exerciseNumber == 2)
        #expect(snapshot.content.exerciseCount == exercises.count)
        #expect(snapshot.content.targetSets == 4)
        #expect(snapshot.content.loggedSets == 2)
        #expect(snapshot.content.sessionSets == 3)
        #expect(snapshot.content.lastSet == "45 kg × 9 reps")
    }

    @Test func missingOrForeignSelectionFallsBackToFirstExercise() throws {
        let store = makeStore()
        let workout = try #require(store.save(TrainingDraft(routine: TrainingRoutine.starters[0]), start: true))
        let standard = try #require(WorkoutActivitySnapshot.make(workout: workout))
        let foreign = try #require(WorkoutActivitySnapshot.make(workout: workout, selectedExerciseID: UUID()))
        #expect(standard == foreign)
        #expect(standard.content.exerciseNumber == 1)
        #expect(standard.content.loggedSets == 0)
        #expect(standard.content.lastSet == nil)
    }

    @Test func restDeadlineIsStableAndExpiredOrInvalidRestIsOmitted() throws {
        let store = makeStore()
        let workout = try #require(store.save(TrainingDraft(routine: TrainingRoutine.starters[0]), start: true))
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let deadline = now.addingTimeInterval(90)
        let snapshot = try #require(WorkoutActivitySnapshot.make(workout: workout, restUntil: deadline.timeIntervalSince1970, now: now))
        #expect(snapshot.content.restEndsAt == deadline)
        #expect(snapshot == WorkoutActivitySnapshot.make(workout: workout, restUntil: deadline.timeIntervalSince1970, now: now.addingTimeInterval(1)))
        #expect(WorkoutActivitySnapshot.make(workout: workout, restUntil: deadline.timeIntervalSince1970, now: deadline)?.content.restEndsAt == nil)
        #expect(WorkoutActivitySnapshot.make(workout: workout, restUntil: .nan, now: now)?.content.restEndsAt == nil)
        #expect(WorkoutActivitySnapshot.make(workout: workout, restUntil: .infinity, now: now)?.content.restEndsAt == nil)
    }

    @Test func snapshotUpdatesAfterEditingOrDeletingASetAndNeverGuessesLegacyUnits() throws {
        let store = makeStore()
        let workout = try #require(store.save(TrainingDraft(routine: TrainingRoutine.starters[0]), start: true))
        workout.weightUnit = nil
        #expect(store.persist())
        let exercise = try #require(workout.sortedExercises.first)
        #expect(store.logSet(exercise: exercise, weight: 20, reps: 8))
        #expect(WorkoutActivitySnapshot.make(workout: workout)?.content.lastSet == "20 load × 8 reps")
        let set = try #require(exercise.sortedSets.first)
        #expect(store.updateSet(set, weight: 0, reps: 12))
        #expect(WorkoutActivitySnapshot.make(workout: workout)?.content.lastSet == "Bodyweight × 12 reps")
        #expect(store.deleteSet(set))
        let snapshot = try #require(WorkoutActivitySnapshot.make(workout: workout))
        #expect(snapshot.content.lastSet == nil)
        #expect(snapshot.content.loggedSets == 0)
        #expect(snapshot.content.sessionSets == 0)
    }
}

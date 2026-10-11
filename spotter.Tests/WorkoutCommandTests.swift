import Testing
import Foundation
import CoreData
@testable import spotter_

@MainActor
struct WorkoutCommandTests {
    private func fixture() throws -> (TrainingStore, WorkoutEntity) {
        let store = TrainingStore(context: Persistence(inMemory: true).container.viewContext)
        let workout = try #require(store.save(TrainingDraft(routine: TrainingRoutine.starters[1]), start: true))
        return (store, workout)
    }
    @Test func completingAndRetryingCommitsOnlyOneSetAndOneDeadline() throws {
        let (store, workout) = try fixture()
        store.setEntry(workout: workout, weight: 135, reps: 8)
        let revision = workout.sessionState.revision
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        #expect(store.performWorkoutAction(.complete, workout: workout, expectedRevision: revision, now: now) == .applied)
        #expect(store.performWorkoutAction(.complete, workout: workout, expectedRevision: revision, now: now) == .stale)
        #expect(workout.sortedExercises[0].sortedSets.count == 1)
        #expect(workout.sessionState.restUntil == now.timeIntervalSince1970 + 90)
        store.context.refreshAllObjects(); store.reload()
        #expect(store.active?.sessionState.restUntil == now.timeIntervalSince1970 + 90)
        #expect(store.active?.sortedExercises[0].sortedSets[0].weight == 135)
    }
    @Test func navigationEditingAndUndoUseRealSets() throws {
        let (store, workout) = try fixture()
        func act(_ action: WorkoutAction) { #expect(store.performWorkoutAction(action, workout: workout, expectedRevision: workout.sessionState.revision) == .applied) }
        act(.complete); act(.previousSet); act(.weightUp); act(.repsUp); act(.complete)
        #expect(workout.sortedExercises[0].sortedSets.count == 1)
        #expect(workout.sortedExercises[0].sortedSets[0].weight == 5)
        #expect(workout.sortedExercises[0].sortedSets[0].reps == 9)
        act(.nextExercise); act(.complete); act(.previousExercise); act(.undo)
        #expect(workout.sessionState.exerciseID == workout.sortedExercises[1].id)
        #expect(workout.sortedExercises[1].sortedSets.isEmpty)
        #expect(workout.sessionState.restUntil == 0)
    }
    @Test func finishedOrDeletedWorkoutRejectsStaleCommands() throws {
        let (store, workout) = try fixture()
        #expect(store.performWorkoutAction(.complete, workout: workout, expectedRevision: workout.sessionState.revision) == .applied)
        let revision = workout.sessionState.revision
        #expect(store.finish(workout))
        #expect(store.performWorkoutAction(.undo, workout: workout, expectedRevision: revision) == .stale)
        #expect(store.delete(workout))
        #expect(store.performWorkoutAction(.complete, workout: workout, expectedRevision: revision) == .stale)
    }
    @Test func editingInAppInvalidatesRenderedButtonsAndBoundsAreSafe() throws {
        let (store, workout) = try fixture()
        let revision = workout.sessionState.revision
        store.setEntry(workout: workout, weight: 0, reps: 1)
        #expect(store.performWorkoutAction(.complete, workout: workout, expectedRevision: revision) == .stale)
        #expect(store.performWorkoutAction(.weightDown, workout: workout, expectedRevision: workout.sessionState.revision) == .applied)
        #expect(workout.sessionState.weight == 0)
        #expect(store.performWorkoutAction(.repsDown, workout: workout, expectedRevision: workout.sessionState.revision) == .applied)
        #expect(workout.sessionState.reps == 1)
        store.setEntry(workout: workout, weight: .nan, reps: 8)
        #expect(workout.sessionState.weight == 0)
    }
    @Test func restUsesExerciseOverrideAndSnapshotMatchesInputs() throws {
        let (store, workout) = try fixture()
        workout.sortedExercises[0].restSeconds = 0
        store.setEntry(workout: workout, weight: 100, reps: 7)
        #expect(store.performWorkoutAction(.complete, workout: workout, expectedRevision: workout.sessionState.revision) == .applied)
        #expect(workout.sessionState.restUntil == 0)
        let snapshot = try #require(WorkoutActivitySnapshot.make(workout: workout))
        #expect(snapshot.content.currentWeight == 100)
        #expect(snapshot.content.currentReps == 7)
        #expect(snapshot.content.setNumber == 2)
        #expect(snapshot.content.revision == workout.sessionState.revision)
    }
}

import Testing
import Foundation
import CoreData
@testable import spotter_

@MainActor
struct WatchWorkoutTests {
    private func session() throws -> (TrainingStore, WorkoutEntity) {
        let store = TrainingStore(context: Persistence(inMemory: true).container.viewContext)
        var draft = TrainingDraft(routine: TrainingRoutine.starters[1]); draft.weightUnit = "lb"
        let workout = try #require(store.save(draft, start: true))
        store.setEntry(workout: workout, weight: 100, reps: 8)
        return (store, workout)
    }
    private func request(_ action: WatchWorkoutAction, _ workout: WorkoutEntity) -> WatchWorkoutRequest {
        .init(workoutID: workout.id, revision: workout.sessionState.revision, action: action)
    }

    @Test func duplicateLogCannotRecordTwiceAndUsesPhoneEntry() throws {
        let (store, workout) = try session()
        let command = request(.complete, workout)
        #expect(WatchWorkoutHandler.perform(command, store: store).0 == .applied)
        #expect(WatchWorkoutHandler.perform(command, store: store).0 == .stale)
        let sets = workout.sortedExercises[0].sortedSets
        #expect(sets.count == 1)
        #expect(sets[0].weight == 100 && sets[0].reps == 8)
    }
    @Test func phoneEditsInvalidateWatchActions() throws {
        let (store, workout) = try session()
        let command = request(.complete, workout)
        store.setEntry(workout: workout, weight: 105, reps: 9)
        #expect(WatchWorkoutHandler.perform(command, store: store).0 == .stale)
        #expect(workout.sortedExercises[0].sortedSets.isEmpty)
        #expect(WatchWorkoutHandler.snapshot(store: store)?.weight == 105)
    }
    @Test func restDeadlineIsSharedAndSkipDoesNotLog() throws {
        let (store, workout) = try session()
        let end = Date.now.addingTimeInterval(60)
        store.setRest(workout: workout, until: end.timeIntervalSince1970)
        let snapshot = try #require(WatchWorkoutHandler.snapshot(store: store))
        let deadline = try #require(snapshot.restEndsAt)
        #expect(abs(deadline.timeIntervalSince(end)) < 0.001)
        #expect(snapshot.isResting(at: deadline.addingTimeInterval(-1)))
        #expect(!snapshot.isResting(at: deadline))
        #expect(WatchWorkoutHandler.perform(request(.complete, workout), store: store).0 == .stale)
        #expect(WatchWorkoutHandler.perform(request(.skipRest, workout), store: store).0 == .applied)
        #expect(workout.sessionState.restUntil == 0)
        #expect(workout.sortedExercises[0].sortedSets.isEmpty)
    }
    @Test func undoRestoresSameSetAndRejectsReplay() throws {
        let (store, workout) = try session()
        #expect(WatchWorkoutHandler.perform(request(.complete, workout), store: store).0 == .applied)
        let undo = request(.undo, workout)
        #expect(WatchWorkoutHandler.perform(undo, store: store).0 == .applied)
        #expect(WatchWorkoutHandler.perform(undo, store: store).0 == .stale)
        #expect(workout.sortedExercises[0].sortedSets.isEmpty)
        #expect(workout.sessionState.weight == 100 && workout.sessionState.restUntil == 0)
    }
    @Test func recordedSetEditingAndCompletedWorkoutRejectWatchMutation() throws {
        let (store, workout) = try session()
        #expect(WatchWorkoutHandler.perform(request(.complete, workout), store: store).0 == .applied)
        store.performWorkoutAction(.previousSet, workout: workout, expectedRevision: workout.sessionState.revision)
        #expect(WatchWorkoutHandler.perform(request(.weightUp, workout), store: store).0 == .failed)
        let command = request(.complete, workout)
        #expect(store.finish(workout))
        #expect(WatchWorkoutHandler.perform(command, store: store).0 == .stale)
        #expect(WatchWorkoutHandler.snapshot(store: store) == nil)
    }
    @Test func adjustmentsAndNavigationUseExistingPhoneCommands() throws {
        let (store, workout) = try session()
        #expect(WatchWorkoutHandler.perform(request(.weightUp, workout), store: store).0 == .applied)
        #expect(workout.sessionState.weight > 100)
        #expect(WatchWorkoutHandler.perform(request(.repsDown, workout), store: store).0 == .applied)
        #expect(workout.sessionState.reps == 7)
        #expect(WatchWorkoutHandler.perform(request(.nextExercise, workout), store: store).0 == .applied)
        #expect(WatchWorkoutHandler.snapshot(store: store)?.exerciseNumber == 2)
        #expect(workout.sortedExercises.flatMap(\.sortedSets).isEmpty)
    }
    @Test func unknownProtocolAndWrongWorkoutFailWithoutMutation() throws {
        let (store, workout) = try session()
        var command = request(.complete, workout); command.version = 99
        #expect(WatchWorkoutHandler.perform(command, store: store).0 == .failed)
        command.version = 1; command.workoutID = UUID()
        #expect(WatchWorkoutHandler.perform(command, store: store).0 == .stale)
        #expect(workout.sortedExercises[0].sortedSets.isEmpty)
    }
    @Test func wireRoundTripAndOutOfOrderSnapshots() throws {
        let (store, _) = try session()
        let envelope = WatchWorkoutEnvelope(installationID: "test", sequence: 10, updatedAt: .now, workout: WatchWorkoutHandler.snapshot(store: store))
        let decoded = try JSONDecoder().decode(WatchWorkoutEnvelope.self, from: JSONEncoder().encode(envelope))
        #expect(decoded == envelope)
        var old = envelope; old.sequence = 9
        #expect(!old.supersedes(envelope))
        var incompatible = envelope; incompatible.version = 99
        #expect(!incompatible.supersedes(envelope))
        var ended = envelope; ended.sequence = 11; ended.workout = nil
        #expect(ended.supersedes(envelope))
    }
}

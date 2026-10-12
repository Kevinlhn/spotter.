import Testing
import Foundation
import CoreData
@testable import spotter_

@MainActor struct TrainingInsightTests {
    private func record(_ store: TrainingStore, weight: Double, reps: Int, unit: String?, daysAgo: Int) throws -> WorkoutEntity {
        var draft = TrainingDraft(); draft.name = "Test"; draft.weightUnit = unit
        draft.moves = [TrainingMove(name: "Row", muscle: "Back")]
        let workout = try #require(store.save(draft, start: true))
        let move = try #require(workout.sortedExercises.first)
        #expect(store.logSet(exercise: move, weight: weight, reps: reps))
        #expect(store.finish(workout))
        workout.date = Date().addingTimeInterval(-Double(daysAgo) * 86400)
        move.sortedSets.first?.timestamp = workout.date.addingTimeInterval(1200)
        #expect(store.persist())
        return workout
    }
    @Test func unitsRangeRecordsAndDurationUseCompletedHistory() throws {
        let store = TrainingStore(context: Persistence(inMemory: true).container.viewContext)
        _ = try record(store, weight: 100, reps: 8, unit: "lb", daysAgo: 40)
        let recent = try record(store, weight: 50, reps: 8, unit: "kg", daysAgo: 2)
        _ = try record(store, weight: 999, reps: 8, unit: nil, daysAgo: 1)
        let filtered = TrainingProgress.filtered(store.completed, range: .month)
        #expect(filtered.count == 2)
        #expect(abs(TrainingProgress.volume(filtered, unit: "kg") - 400) < 0.01)
        #expect(TrainingProgress.sessions(store.completed, name: " ROW ", unit: "kg").count == 2)
        #expect(TrainingProgress.sessions(store.completed, name: "Row", unit: "unspecified").count == 1)
        let records = TrainingProgress.records(store.completed, since: TrainingProgress.Range.month.start(), unit: "kg")
        #expect(records.count == 1 && records.first?.workoutID == recent.id)
        #expect(TrainingProgress.muscles(filtered).first?.sets == 2)
        #expect(TrainingProgress.loggingMinutes(recent) == 20)
        var plan = TrainingDraft(routine: TrainingRoutine.starters[0]); plan.date = .now
        _ = store.save(plan, start: false)
        #expect(TrainingProgress.filtered(store.workouts, range: .month).count == 2)
    }
    @Test func estimatedMaxExcludesBodyweightAndHighReps() {
        #expect(TrainingProgress.estimatedMax(weight: 0, reps: 8) == nil)
        #expect(TrainingProgress.estimatedMax(weight: 100, reps: 13) == nil)
        #expect(TrainingProgress.estimatedMax(weight: 100, reps: 1) == 100)
        #expect(TrainingProgress.estimatedMax(weight: .infinity, reps: 8) == nil)
    }
}

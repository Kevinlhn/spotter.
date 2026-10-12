import Foundation
import CoreData
import Testing
@testable import spotter_

@MainActor
struct NextSetGuidanceTests {
    private let plan = OverloadPrescription(sets: 3, repRange: 8...12, weight: nil)
    private func advice(_ sets: [(Double, Int)], step: Double = 5) -> OverloadRecommendation {
        ProgressiveOverloadEngine.recommend(history: [], prescription: plan, increment: step,
            currentSets: sets.map { .init(weight: $0.0, reps: $0.1) }, activeSession: true)
    }
    @Test func noHistoryDoesNotInventLoadButPlannedLoadIsActionable() {
        #expect(advice([]).suggested == nil)
        #expect(advice([]).scope == .nextSet)
        let result = ProgressiveOverloadEngine.recommend(history: [],
            prescription: .init(sets: 3, repRange: 8...12, weight: 40), increment: 5, activeSession: true)
        #expect(result.suggested?.weight == 40)
        #expect(result.suggested?.repRange == 8...8)
    }
    @Test func successfulSetGivesExactNextRepsWithoutRaisingLoad() {
        let result = advice([(100, 10)])
        #expect(result.suggested?.weight == 100)
        #expect(result.suggested?.repRange == 10...10)
        #expect(result.reason.contains("set 2"))
    }
    @Test func fatigueRespondsToActualRepDrop() {
        let result = advice([(100, 12), (100, 9)])
        #expect(result.suggested?.repRange == 9...9)
        #expect(result.reason.contains("fell from 12 to 9"))
    }
    @Test func smallMissRetriesButRepeatedMissReducesOneEquipmentStep() {
        #expect(advice([(100, 7)]).suggested?.weight == 100)
        #expect(advice([(100, 7), (100, 7)]).suggested?.weight == 95)
        #expect(advice([(100, 5)]).suggested?.weight == 95)
        #expect(advice([(10, 5)]).suggested?.weight == 10) // Coarse 50% drop rejected.
    }
    @Test func bodyweightFatigueDoesNotAddExternalLoad() {
        let result = advice([(0, 5)])
        #expect(result.suggested?.weight == 0)
        #expect(result.suggested?.repRange == 5...5)
    }
    @Test func mixedLoadsUseLatestActualLoad() {
        let result = advice([(50, 10), (100, 8)])
        #expect(result.suggested?.weight == 100)
        #expect(result.reason.contains("changed the load"))
    }
    @Test func completedExerciseDoesNotPromptUnplannedFourthSet() {
        let result = advice([(100, 8), (100, 8), (100, 8)])
        #expect(result.suggested == nil)
        #expect(result.scope == .complete)
    }
    @Test @MainActor func editsUndoAndTargetsRecalculateWithoutChangingDraft() throws {
        let store = TrainingStore(context: Persistence(inMemory: true).container.viewContext)
        var draft = TrainingDraft(routine: TrainingRoutine.starters[1]); draft.weightUnit = "lb"
        let workout = try #require(store.save(draft, start: true))
        let exercise = workout.sortedExercises[0]
        store.setEntry(workout: workout, weight: 100, reps: 8)
        #expect(store.logSet(exercise: exercise, weight: 100, reps: 5))
        func current() -> OverloadRecommendation {
            store.recommendation(for: TrainingMove(exercise: exercise), unit: "lb", current: exercise)
        }
        #expect(current().suggested?.weight == 95)
        #expect(workout.sessionState.weight == 100)
        let set = try #require(exercise.sortedSets.first)
        #expect(store.updateSet(set, weight: 100, reps: 8))
        #expect(current().suggested?.weight == 100)
        #expect(store.performWorkoutAction(.undo, workout: workout, expectedRevision: workout.sessionState.revision) == .applied)
        #expect(current().suggested == nil)
        #expect(store.exerciseHistory(name: exercise.name, unit: "lb").isEmpty)
    }
}

import Foundation
import CoreData
import Testing
@testable import spotter_

@MainActor
struct ProgressiveOverloadTests {
    private let fixed = OverloadPrescription(sets: 3, repRange: 8...8, weight: nil)
    private func session(_ reps: [Int], weight: Double = 135, day: Int = 0, range: ClosedRange<Int> = 8...8, targetWeight: Double? = nil) -> ExercisePerformance {
        ExercisePerformance(date: Date(timeIntervalSince1970: Double(day) * 86400),
                            sets: reps.map { .init(weight: weight, reps: $0) }, targetSets: 3,
                            repRange: range, targetWeight: targetWeight)
    }
    @Test func noHistoryRequiresBaseline() {
        let result = ProgressiveOverloadEngine.recommend(history: [], prescription: fixed, increment: 5)
        #expect(result.suggested == nil)
        #expect(result.confidence == .baseline)
    }
    @Test func missedTargetKeeps135AndBaselineIsActualPerformance() {
        let baseline = session([8, 8, 7])
        let result = ProgressiveOverloadEngine.recommend(history: [baseline], prescription: fixed, increment: 5)
        #expect(result.suggested?.weight == 135)
        #expect(result.suggested?.repRange == 8...8)
        #expect(result.baseline == baseline)
        #expect(result.reason.contains("missed"))
    }
    @Test func twoSuccessfulFixedSessionsSuggestOneSmallIncrement() {
        let history = [session([8, 8, 8]), session([8, 8, 8], day: 1)]
        let result = ProgressiveOverloadEngine.recommend(history: history, prescription: fixed, increment: 5)
        #expect(result.suggested?.weight == 140)
        #expect(result.confidence == .established)
        #expect(result.trend == .flat)
    }
    @Test func oneSuccessfulSessionBuildsRepsBeforeLoad() {
        let result = ProgressiveOverloadEngine.recommend(history: [session([8, 8, 8])], prescription: fixed, increment: 5)
        #expect(result.suggested?.weight == 135)
        #expect(result.suggested?.repRange == 9...9)
    }
    @Test func topOfRangeRaisesLoadAndKeepsLowerRepOption() {
        let result = ProgressiveOverloadEngine.recommend(history: [session([8, 8, 8], range: 6...8)],
                      prescription: .init(sets: 3, repRange: 6...8, weight: nil), increment: 5)
        #expect(result.suggested?.weight == 140)
        #expect(result.suggested?.repRange == 6...8)
    }
    @Test func incompleteSetsOrMissedPrescribedLoadDoNotProgress() {
        for performance in [session([8, 8]), session([8, 8, 8], targetWeight: 140)] {
            let result = ProgressiveOverloadEngine.recommend(history: [performance], prescription: fixed, increment: 5)
            #expect(result.suggested?.weight == 135)
            #expect(result.suggested?.repRange == 8...8)
        }
    }
    @Test func substantialDeclineNeverRaisesWeightOrReps() {
        let result = ProgressiveOverloadEngine.recommend(history: [session([8, 8, 8], weight: 185), session([8, 8, 8], day: 1)], prescription: fixed, increment: 5)
        #expect(result.trend == .declining)
        #expect(result.suggested?.weight == 135)
        #expect(result.suggested?.repRange == 8...8)
    }
    @Test func equipmentJumpAboveFivePercentFallsBackToReps() {
        let result = ProgressiveOverloadEngine.recommend(history: [session([8, 8, 8], weight: 10), session([8, 8, 8], weight: 10, day: 1)], prescription: fixed, increment: 2.5)
        #expect(result.suggested?.weight == 10)
        #expect(result.suggested?.repRange == 9...9)
    }
    @Test func bodyweightDoesNotBecomeExternalWeight() {
        let result = ProgressiveOverloadEngine.recommend(history: [session([8, 8, 8], weight: 0)], prescription: fixed, increment: 5)
        #expect(result.suggested?.weight == 0)
        #expect(result.suggested?.repRange == 9...9)
    }
    @Test func currentStruggleOverridesHistoricalIncrease() {
        let result = ProgressiveOverloadEngine.recommend(history: [session([8, 8, 8]), session([8, 8, 8], day: 1)], prescription: fixed, increment: 5, currentSets: [.init(weight: 140, reps: 5)])
        #expect(result.suggested?.weight == 135)
        #expect(result.scope == .nextSet)
        #expect(result.reason.contains("5 of 8"))
    }
    @Test func mixedAndInvalidLoadsNeverTriggerIncrease() {
        let mixed = ExercisePerformance(date: .now, sets: [.init(weight: 95, reps: 8), .init(weight: 135, reps: 8), .init(weight: 135, reps: 8)], targetSets: 3, repRange: 8...8, targetWeight: nil)
        let result = ProgressiveOverloadEngine.recommend(history: [mixed], prescription: fixed, increment: 5)
        #expect(result.suggested?.weight == 95)
        #expect(result.reason.contains("mixed"))
        #expect(ProgressiveOverloadEngine.recommend(history: [session([8], weight: .nan)], prescription: fixed, increment: 5).suggested == nil)
    }
    @Test func newHigherTargetsAndMoreSetsDoNotCountAsPreviousSuccess() {
        let history = [session([8, 8, 8]), session([8, 8, 8], day: 1)]
        for prescription in [OverloadPrescription(sets: 3, repRange: 10...10, weight: nil), .init(sets: 4, repRange: 8...8, weight: nil)] {
            #expect(ProgressiveOverloadEngine.recommend(history: history, prescription: prescription, increment: 5).suggested?.weight == 135)
        }
    }
    @Test @MainActor func equipmentStepsRespectUnits() {
        #expect(EquipmentLoadStep.value(name: "Barbell Bench Press", unit: "lb") == 5)
        #expect(EquipmentLoadStep.value(name: "Barbell Bench Press", unit: "kg") == 2.5)
        #expect(EquipmentLoadStep.value(name: "Dumbbell Row", unit: "kg") == 1)
        #expect(EquipmentLoadStep.value(name: "Cable Row", unit: "kg", preferred: 5) == 5)
    }
    @Test @MainActor func historyExcludesPlansAndActiveSetsAndPersistsAcceptedTargets() throws {
        let store = TrainingStore(context: Persistence(inMemory: true).container.viewContext)
        var draft = TrainingDraft(routine: TrainingRoutine.starters[1])
        draft.weightUnit = "lb"
        draft.moves[0].targetWeight = 135; draft.moves[0].targetRepMinimum = 6
        let workout = try #require(store.save(draft, start: true))
        let exercise = workout.sortedExercises[0]
        #expect(exercise.targetWeight?.doubleValue == 135)
        #expect(exercise.repRange == 6...8)
        #expect(workout.sessionState.weight == 135)
        #expect(workout.sessionState.reps == 6)
        #expect(store.logSet(exercise: exercise, weight: 135, reps: 7))
        #expect(store.exerciseHistory(name: exercise.name, unit: "lb").isEmpty)
        #expect(store.finish(workout))
        let history = store.exerciseHistory(name: "  BARBELL   BENCH PRESS ", unit: "lb")
        #expect(history.count == 1)
        #expect(history[0].sets[0].reps == 7)
        #expect(store.exerciseHistory(name: exercise.name, unit: nil).isEmpty)
        let kg = store.exerciseHistory(name: exercise.name, unit: "kg")
        #expect(abs(kg[0].sets[0].weight - 61.23497) < 0.001)
        let copy = TrainingDraft(workout: workout, repeatWorkout: true)
        #expect(copy.moves[0].targetWeight == 135)
        #expect(copy.moves[0].targetRepMinimum == 6)
    }
    @Test @MainActor func repeatedExerciseEntriesAreOneSessionAndPlansAreNotHistory() throws {
        let store = TrainingStore(context: Persistence(inMemory: true).container.viewContext)
        var draft = TrainingDraft()
        draft.name = "Bench twice"; draft.weightUnit = "lb"
        draft.moves = [TrainingMove(name: "Bench", muscle: "Chest"), TrainingMove(name: "Bench", muscle: "Chest")]
        let planned = try #require(store.save(draft, start: false))
        #expect(store.exerciseHistory(name: "Bench", unit: "lb").isEmpty)
        #expect(store.begin(planned))
        for exercise in planned.sortedExercises {
            for _ in 0..<3 { #expect(store.logSet(exercise: exercise, weight: 135, reps: 8)) }
        }
        #expect(store.finish(planned))
        let history = store.exerciseHistory(name: "Bench", unit: "lb")
        #expect(history.count == 1)
        #expect(history[0].sets.count == 6)
        #expect(history[0].targetSets == 6)
    }
    @Test func convertedLoadsUseAvailableEquipmentSteps() {
        let history = [session([8, 8, 8], weight: 61.23497), session([8, 8, 8], weight: 61.23497, day: 1)]
        let result = ProgressiveOverloadEngine.recommend(history: history, prescription: fixed, increment: 2.5)
        #expect(result.suggested?.weight == 62.5)
    }

}

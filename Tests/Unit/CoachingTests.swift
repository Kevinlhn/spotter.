import Testing
import Foundation
import CoreData
@testable import spotter_

@MainActor struct CoachingTests {
    @Test func settingsPersistAndConservativePaceDoesNotInventProgress() throws {
        let defaults = try #require(UserDefaults(suiteName: "coaching-test-\(UUID())"))
        var preferences = TrainingPreferences()
        preferences.coaching.goal = .muscle
        preferences.coaching.aggression = .conservative
        preferences.coaching.recoveryFirst = true
        preferences.coaching.excludedExercises = "squat, bench"
        preferences.save(to: defaults)
        #expect(TrainingPreferences.load(from: defaults) == preferences)
        #expect(preferences.coaching.isExcluded("Goblet Squat"))
        let performance = ExercisePerformance(date: .now, sets: Array(repeating: .init(weight: 100, reps: 8), count: 3), targetSets: 3, repRange: 8...8, targetWeight: 100)
        let advice = ProgressiveOverloadEngine.recommend(history: [performance, performance], prescription: .init(sets: 3, repRange: 8...8, weight: 100), increment: 2.5, coaching: preferences.coaching)
        #expect(advice.suggested?.weight == 100)
        #expect(advice.suggested?.repRange == 8...8)
        preferences.coaching.progressiveOverload = false
        let off = ProgressiveOverloadEngine.recommend(history: [performance, performance], prescription: .init(sets: 3, repRange: 8...8, weight: 100), increment: 2.5, coaching: preferences.coaching)
        #expect(off.reason.contains("off"))
        #expect(off.suggested?.weight == 100)
    }
    @Test func equipmentAndRestrictionsFilterChoices() {
        var preferences = CoachingPreferences()
        preferences.equipment = .bodyweight
        #expect(preferences.allows(TrainingMove(name: "Bodyweight Squat", muscle: "Legs")))
        #expect(!preferences.allows(TrainingMove(name: "Barbell Bench Press", muscle: "Chest")))
        preferences.excludedExercises = "squat"
        #expect(!preferences.allows(TrainingMove(name: "Bodyweight Squat", muscle: "Legs")))
        #expect(!preferences.allows(TrainingMove(name: "Unknown custom movement", muscle: "Legs")))
    }
    @Test func suggestedRoutineCreatesNoRecordsAndUsesUniqueMoves() {
        let store = TrainingStore(context: Persistence(inMemory: true).container.viewContext)
        let draft = store.coachedDraft()
        #expect(!draft.moves.isEmpty)
        #expect(Set(draft.moves.map(\.id)).count == draft.moves.count)
        #expect(Set(draft.moves.map(\.name)).count == draft.moves.count)
        #expect(store.workouts.isEmpty)
        #expect(draft.existing == nil)
    }
}

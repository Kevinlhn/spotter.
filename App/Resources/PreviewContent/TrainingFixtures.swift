#if DEBUG
import Foundation

@MainActor enum TrainingFixtures {
    /// Used only by the in-memory UI test store. Never writes to the user's database.
    static func seedHistory(_ store: TrainingStore) {
        for index in 0..<8 {
            var draft = TrainingDraft(routine: TrainingRoutine.starters[0])
            draft.weightUnit = "lb"
            guard let workout = store.save(draft, start: true) else { continue }
            for exercise in workout.sortedExercises {
                for _ in 0..<3 { _ = store.logSet(exercise: exercise, weight: 30 + Double(index) * 2.5, reps: 8) }
            }
            _ = store.finish(workout)
            workout.date = Calendar.current.date(byAdding: .day, value: -28 + index * 3, to: Date()) ?? .now
            for (offset, set) in workout.sortedExercises.flatMap(\.sortedSets).enumerated() {
                set.timestamp = workout.date.addingTimeInterval(Double(offset + 1) * 120)
            }
            _ = store.persist()
        }
    }
}
#endif

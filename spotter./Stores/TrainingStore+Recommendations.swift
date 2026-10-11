import Foundation

extension TrainingStore {
    /// Project existing completed records. Match normalized names; never treat plans as history.
    /// Convert only known lb/kg units; legacy unspecified loads are kept out of recommendations.
    func exerciseHistory(name: String, unit: String?) -> [ExercisePerformance] {
        guard unit == "kg" || unit == "lb" else { return [] }
        func key(_ value: String) -> String { value.split(whereSeparator: \.isWhitespace).joined(separator: " ").lowercased() }
        return completed.reversed().flatMap { workout -> [ExercisePerformance] in
            guard workout.weightUnit == "kg" || workout.weightUnit == "lb" else { return [] }
            let factor = workout.weightUnit == unit ? 1.0 : unit == "kg" ? 1 / 2.2046226218 : 2.2046226218
            let matches = workout.sortedExercises.filter { key($0.name) == key(name) }
            let sets = matches.flatMap(\.sortedSets)
            guard !sets.isEmpty else { return [] }
            // Repeated entries in one workout are one performance, never two successful sessions.
            let minimum = matches.map { $0.repRange.lowerBound }.max() ?? 8
            let maximum = matches.map { $0.repRange.upperBound }.max() ?? minimum
            return [ExercisePerformance(date: workout.date,
                        sets: sets.map { .init(weight: $0.weight * factor, reps: Int($0.reps)) },
                        targetSets: matches.reduce(0) { $0 + $1.plannedSets }, repRange: minimum...maximum,
                        targetWeight: matches.compactMap { $0.targetWeight?.doubleValue }.max().map { $0 * factor })]
        }
    }

    func recommendation(for move: TrainingMove, unit: String?, current: ExerciseEntity? = nil) -> OverloadRecommendation {
        let step = EquipmentLoadStep.value(name: move.name, unit: unit, preferred: TrainingPreferences.load().weightStep)
        return ProgressiveOverloadEngine.recommend(history: exerciseHistory(name: move.name, unit: unit),
                   prescription: .init(sets: move.targetSets, repRange: move.repRange, weight: move.targetWeight),
                   increment: step,
                   currentSets: current?.sortedSets.map { .init(weight: $0.weight, reps: Int($0.reps)) } ?? [],
                   activeSession: current != nil)
    }
}

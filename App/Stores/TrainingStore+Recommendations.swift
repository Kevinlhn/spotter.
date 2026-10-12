import Foundation

extension TrainingStore {
    /// Project existing completed records. Match normalized names; never treat plans as history.
    /// Convert only known lb/kg units; legacy unspecified loads are kept out of recommendations.
    func exerciseHistory(name: String, unit: String?) -> [ExercisePerformance] {
        guard unit == "kg" || unit == "lb" else { return [] }
        return completed.reversed().flatMap { workout -> [ExercisePerformance] in
            guard workout.weightUnit == "kg" || workout.weightUnit == "lb" else { return [] }
            let factor = workout.weightUnit == unit ? 1.0 : unit == "kg" ? 1 / 2.2046226218 : 2.2046226218
            let matches = workout.sortedExercises.filter { ExerciseCatalog.key($0.name) == ExerciseCatalog.key(name) }
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
        let preferences = TrainingPreferences.load()
        let step = EquipmentLoadStep.value(name: move.name, unit: unit, preferred: TrainingPreferences.load().weightStep)
        var recommendation = ProgressiveOverloadEngine.recommend(history: exerciseHistory(name: move.name, unit: unit),
                   prescription: .init(sets: move.targetSets, repRange: move.repRange, weight: move.targetWeight),
                   increment: step,
                   currentSets: current?.sortedSets.map { .init(weight: $0.weight, reps: Int($0.reps)) } ?? [],
                   activeSession: current != nil, coaching: preferences.coaching)
        if !preferences.coaching.allows(move) {
            recommendation.suggested = nil
            recommendation.reason = "This exercise doesn’t match your Coaching exercise or equipment preferences. Choose a substitution in Plan, or adjust it manually."
        }
        return recommendation
    }
}

extension TrainingStore {
    func coachingChoices(for muscle: String? = nil) -> [TrainingMove] {
        let preferences = TrainingPreferences.load().coaching
        let historyNames = Set(completed.flatMap(\.sortedExercises).map { ExerciseCatalog.key($0.name) })
        return ExerciseCatalog.moves(custom: library, workouts: workouts)
            .filter { preferences.allows($0) && (muscle == nil || $0.muscle == muscle) }
            .sorted {
                func score(_ move: TrainingMove) -> Int {
                    (preferences.isPreferred(move.name) ? 2 : 0) + (historyNames.contains(ExerciseCatalog.key(move.name)) ? 1 : 0)
                }
                return score($0) == score($1) ? $0.name < $1.name : score($0) > score($1)
            }
    }

    /// Reviewable draft only: prioritizes familiar/preferred exercises and never creates records.
    func coachedDraft() -> TrainingDraft {
        let preferences = TrainingPreferences.load()
        let coaching = preferences.coaching
        var draft = TrainingDraft()
        draft.name = "\(coaching.goal.rawValue) routine"
        draft.notes = "Suggested from your coaching settings and completed history. Review exercises and targets before saving."
        let choices = coachingChoices()
        let muscleFamilies = [["Legs", "Quads"], ["Chest"], ["Back"], ["Hamstrings", "Glutes"], ["Shoulders"]]
        let count = preferences.sessionsPerWeek >= 4 || coaching.recoveryFirst ? 4 : 5
        for family in muscleFamilies.prefix(count) {
            guard var move = choices.first(where: { candidate in family.contains(candidate.muscle) && !draft.moves.contains(where: { ExerciseCatalog.key($0.name) == ExerciseCatalog.key(candidate.name) }) }) else { continue }
            move.id = UUID()
            move.targetSets = coaching.experience == .beginner || coaching.recoveryFirst ? 2 : 3
            move.targetRepMinimum = coaching.repRange.lowerBound; move.targetReps = coaching.repRange.upperBound
            move.restSeconds = coaching.recoveryFirst || coaching.goal == .strength ? 120 : 90
            let suggestion = recommendation(for: move, unit: draft.weightUnit)
            move.targetWeight = suggestion.suggested?.weight
            draft.moves.append(move)
        }
        return draft
    }
}

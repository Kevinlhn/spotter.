import Foundation

nonisolated struct ExercisePerformance: Equatable {
    struct SetResult: Equatable {
        let weight: Double
        let reps: Int
        var isValid: Bool { weight.isFinite && (0...10000).contains(weight) && (1...999).contains(reps) }
    }
    let date: Date
    let sets: [SetResult]
    let targetSets: Int
    let repRange: ClosedRange<Int>
    let targetWeight: Double?
    var reachedMinimum: Bool {
        sets.count >= targetSets && sets.prefix(targetSets).allSatisfy {
            $0.reps >= repRange.lowerBound && $0.weight >= (targetWeight ?? 0) - 0.01
        }
    }
    var reachedTop: Bool {
        reachedMinimum && sets.prefix(targetSets).allSatisfy { $0.reps >= repRange.upperBound }
    }
    var uniformLoad: Double? {
        guard let first = sets.first, sets.allSatisfy({ abs($0.weight - first.weight) < 0.01 }) else { return nil }
        return first.weight
    }
    /// Used only to describe trend, never to prescribe a tested one-rep max.
    var capacity: Double {
        sets.map { $0.weight == 0 ? Double($0.reps) : $0.weight * (1 + Double(min($0.reps, 12)) / 30) }.max() ?? 0
    }
}

nonisolated struct OverloadPrescription: Equatable {
    var sets: Int
    var repRange: ClosedRange<Int>
    var weight: Double?
}

nonisolated struct OverloadRecommendation: Equatable {
    enum Scope: String { case nextSet = "Next set", nextWorkout = "Next workout", complete = "Exercise complete" }
    enum Confidence: String { case baseline = "Baseline needed", limited = "Limited history", established = "Established history" }
    enum Trend: String { case unknown = "Building history", improving = "Improving", flat = "Steady", declining = "Declining" }
    var suggested: OverloadPrescription?
    var reason: String
    let confidence: Confidence
    let trend: Trend
    let previous: ExercisePerformance?
    let baseline: ExercisePerformance?
    let bestRecent: ExercisePerformance?
    let sessionCount: Int
    var scope: Scope = .nextWorkout
}

/// Pure, deterministic double progression. No network, models, hidden mutations, or stored copy of history.
nonisolated enum ProgressiveOverloadEngine {
    @MainActor static func recommend(history: [ExercisePerformance], prescription: OverloadPrescription,
                          increment: Double, currentSets: [ExercisePerformance.SetResult] = [],
                          activeSession: Bool = false, coaching: CoachingPreferences = CoachingPreferences()) -> OverloadRecommendation {
        let history = history.filter { !$0.sets.isEmpty && $0.sets.allSatisfy(\.isValid) }
            .sorted { $0.date < $1.date }
        let recent = Array(history.suffix(6))
        let last = recent.last
        let confidence: OverloadRecommendation.Confidence = history.isEmpty ? .baseline : history.count < 2 ? .limited : .established
        let trend: OverloadRecommendation.Trend
        if recent.count >= 2, let latest = recent.last, recent[recent.count - 2].capacity > 0 {
            let ratio = latest.capacity / recent[recent.count - 2].capacity
            trend = ratio < 0.90 ? .declining : ratio > 1.025 ? .improving : .flat
        } else { trend = .unknown }
        func result(_ suggested: OverloadPrescription?, _ reason: String) -> OverloadRecommendation {
            OverloadRecommendation(suggested: suggested, reason: reason, confidence: confidence, trend: trend,
                                   previous: last, baseline: history.first, bestRecent: recent.max { $0.capacity < $1.capacity },
                                   sessionCount: history.count)
        }
        guard (1...20).contains(prescription.sets), prescription.repRange.lowerBound >= 1,
              prescription.repRange.upperBound <= 999 else { return result(nil, "Choose valid set and rep targets first.") }
        let current = currentSets.filter(\.isValid)
        if activeSession || !current.isEmpty {
            let guidance = nextSet(history: history, prescription: prescription, increment: increment, current: current, coaching: coaching)
            var recommendation = result(guidance.suggested, guidance.reason)
            recommendation.scope = current.count >= prescription.sets ? .complete : .nextSet
            return recommendation
        }
        guard let last else { return result(nil, "Complete this exercise in a workout to establish your baseline. Planned values are never counted as performance.") }
        let load = last.uniformLoad ?? last.sets.map(\.weight).min() ?? 0
        let step = increment.isFinite && increment > 0 ? increment : 0
        // Converted historical loads are rounded down to an available step, never up silently.
        let roundedLoad = step > 0 ? (floor((load + 0.00001) / step) * step * 100).rounded() / 100 : load
        var suggested = OverloadPrescription(sets: prescription.sets, repRange: prescription.repRange, weight: roundedLoad)
        if !coaching.progressiveOverload {
            return result(suggested, "Progressive overload is off in Coaching settings. Repeat the last load and your planned reps.")
        }
        if trend == .declining, coaching.recoveryFirst, recent.count >= 3,
           recent[recent.count - 2].capacity < recent[recent.count - 3].capacity * 0.9 {
            suggested.sets = max(1, prescription.sets - 1)
            return result(suggested, "Performance fell across two successive sessions. Consider one fewer set next workout and review recovery before increasing load.")
        }
        if trend == .declining {
            return result(suggested, "Recent performance dropped substantially. Repeat the last load and reassess before increasing it.")
        }
        guard last.uniformLoad != nil else {
            return result(suggested, "Your last session used mixed loads. Start from its lightest recorded load and choose your working weight; Spotter will not infer which sets were warm-ups.")
        }
        guard last.reachedMinimum, last.sets.count >= prescription.sets else {
            return result(suggested, "You missed target reps, load, or sets last session. Repeat the load before progressing.")
        }
        let lastReps = last.sets.prefix(prescription.sets).map(\.reps).min() ?? prescription.repRange.lowerBound
        // New, higher targets are not proof that old targets were achieved.
        if lastReps < prescription.repRange.lowerBound {
            return result(suggested, "Your current rep target is higher than the last performance. Keep the load while building toward it.")
        }
        let twoSuccesses = recent.count >= coaching.requiredSuccesses && recent.suffix(coaching.requiredSuccesses).allSatisfy {
            $0.reachedTop && $0.sets.count >= prescription.sets &&
            $0.repRange == last.repRange && $0.targetSets == last.targetSets &&
            abs(($0.uniformLoad ?? -1) - load) < 0.01
        }
        let rangeReached = coaching.aggression != .conservative && !coaching.recoveryFirst && coaching.experience != .beginner && prescription.repRange.lowerBound < prescription.repRange.upperBound && lastReps >= prescription.repRange.upperBound
        let canRaiseLoad = (twoSuccesses || rangeReached) && last.reachedTop && lastReps >= prescription.repRange.upperBound
        // Never turn bodyweight into an external load or suggest >5% just to fit equipment.
        let nextLoad = roundedLoad + step
        if canRaiseLoad, load > 0, step > 0,
           nextLoad > load, nextLoad - load <= load * coaching.maximumIncrease, nextLoad <= 10000 {
            suggested.weight = (nextLoad * 100).rounded() / 100
            suggested.repRange = prescription.repRange
            return result(suggested, rangeReached
                          ? "You completed every intended set at the top of your rep range. Try one small equipment step and begin at the lower end of the range."
                          : "Your last \(coaching.requiredSuccesses) sessions met the same targets at this load. Try one small equipment step while keeping your rep target.")
        }
        if coaching.aggression == .conservative || coaching.recoveryFirst, !twoSuccesses {
            return result(suggested, "Your coaching pace calls for \(coaching.requiredSuccesses) consistent successful sessions. Repeat this load and target first.")
        }
        if prescription.repRange.lowerBound < prescription.repRange.upperBound {
            let next = min(prescription.repRange.upperBound, lastReps + 1)
            suggested.repRange = next...prescription.repRange.upperBound
        } else {
            let next = min(999, lastReps + 1)
            suggested.repRange = next...next
        }
        return result(suggested, canRaiseLoad && load > 0
                      ? "The next equipment step would exceed your \((coaching.maximumIncrease * 100).formatted(.number.precision(.fractionLength(0...1))))% load-increase limit. Build reps at the current load instead."
                      : load == 0 ? "Build another rep at bodyweight. Spotter does not automatically add external weight."
                      : "You met the minimum targets. Build another rep at this load before increasing weight.")
    }
}

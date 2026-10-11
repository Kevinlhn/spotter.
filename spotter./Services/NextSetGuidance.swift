import Foundation

extension ProgressiveOverloadEngine {
    /// Set-to-set advice uses actual performance, never changes entry values, and never
    /// interprets an easy-looking set as permission to increase the load mid-workout.
    static func nextSet(history: [ExercisePerformance], prescription: OverloadPrescription,
                        increment: Double, current: [ExercisePerformance.SetResult])
        -> (suggested: OverloadPrescription?, reason: String) {
        guard current.count < prescription.sets else {
            return (nil, "All \(prescription.sets) planned sets are saved. Move to your next exercise; progression is reviewed for your next workout.")
        }
        let minimum = prescription.repRange.lowerBound
        let maximum = prescription.repRange.upperBound
        func advice(_ weight: Double, _ reps: Int, _ reason: String) -> (OverloadPrescription?, String) {
            (.init(sets: prescription.sets, repRange: reps...reps, weight: weight), reason)
        }
        guard let latest = current.last else {
            if let planned = prescription.weight, planned.isFinite, (0...10000).contains(planned) {
                return advice(planned, minimum, "Start with your planned load and \(minimum) reps. Your first set will guide the next.")
            }
            let nextWorkout = recommend(history: history, prescription: prescription, increment: increment)
            guard let suggested = nextWorkout.suggested, let weight = suggested.weight else {
                return (nil, "Choose a comfortable starting load and aim for \(minimum) reps. Log your first set to get next-set guidance.")
            }
            return advice(weight, suggested.repRange.lowerBound, nextWorkout.reason)
        }
        let sameLoad = current.suffix(2).allSatisfy { abs($0.weight - latest.weight) < 0.01 }
        let repeatedMiss = current.count >= 2 && sameLoad && current.suffix(2).allSatisfy { $0.reps < minimum }
        let severeMiss = latest.reps <= minimum - 2
        let previous = current.dropLast().last
        let fallingReps = previous.map { abs($0.weight - latest.weight) < 0.01 && latest.reps <= $0.reps - 2 } ?? false
        if latest.reps < minimum {
            if latest.weight == 0 {
                return advice(0, latest.reps, "You logged \(latest.reps) of \(minimum) reps. Stay at bodyweight and aim for \(latest.reps) controlled reps after resting.")
            }
            if (severeMiss || repeatedMiss), increment.isFinite, increment > 0 {
                let reduced = (floor((latest.weight - 0.001) / increment) * increment * 100).rounded() / 100
                if reduced > 0, latest.weight - reduced <= latest.weight * 0.10 {
                    return advice(reduced, minimum, "You \(repeatedMiss ? "missed the target twice" : "logged only \(latest.reps) of \(minimum) reps"). Try one equipment step lighter after resting.")
                }
            }
            return advice(latest.weight, minimum, "You logged \(latest.reps) of \(minimum) reps. Rest fully, then retry \(minimum) at this load. Adjust it manually if needed.")
        }
        let reps = min(maximum, latest.reps)
        if fallingReps {
            return advice(latest.weight, reps, "Reps fell from \(previous!.reps) to \(latest.reps) at the same load. Rest fully and aim for \(reps); no increase today.")
        }
        if let previous, abs(previous.weight - latest.weight) >= 0.01 {
            return advice(latest.weight, reps, "You changed the load and reached \(latest.reps) reps. Repeat this load for \(reps) to check consistency.")
        }
        return advice(latest.weight, reps, "You reached \(latest.reps) reps. Repeat \(reps) at this load for set \(current.count + 1); save increases for the next workout.")
    }
}

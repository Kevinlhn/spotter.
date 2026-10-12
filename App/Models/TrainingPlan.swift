import Foundation

struct TrainingMove: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var muscle: String
    var targetSets: Int = 3
    var targetReps: Int = 8
    /// nil follows the app's rest preference; zero explicitly disables the timer.
    var restSeconds: Int? = nil
    var targetWeight: Double? = nil
    var targetRepMinimum: Int? = nil
    var repRange: ClosedRange<Int> { min(targetRepMinimum ?? targetReps, targetReps)...targetReps }

    init(id: UUID = UUID(), name: String, muscle: String, targetSets: Int = 3, targetReps: Int = 8,
         restSeconds: Int? = nil, targetWeight: Double? = nil, targetRepMinimum: Int? = nil) {
        self.id = id; self.name = name; self.muscle = muscle; self.targetSets = targetSets
        self.targetReps = targetReps; self.restSeconds = restSeconds; self.targetWeight = targetWeight
        self.targetRepMinimum = targetRepMinimum
    }
    init(exercise: ExerciseEntity) {
        self.init(id: exercise.id, name: exercise.name, muscle: exercise.muscleGroup ?? "Other",
                  targetSets: exercise.plannedSets, targetReps: exercise.plannedReps,
                  restSeconds: exercise.restOverrideSeconds, targetWeight: exercise.targetWeight?.doubleValue,
                  targetRepMinimum: exercise.targetRepMinimum > 0 ? Int(exercise.targetRepMinimum) : nil)
    }
}

struct TrainingRoutine: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let equipment: String
    let symbol: String
    let moves: [TrainingMove]

    static let starters = [
        TrainingRoutine(id: "full", name: "The full-body start", subtitle: "A simple place to begin.", equipment: "Dumbbells", symbol: "figure.strengthtraining.traditional", moves: [
            TrainingMove(name: "Goblet Squat", muscle: "Legs"), TrainingMove(name: "Dumbbell Floor Press", muscle: "Chest"),
            TrainingMove(name: "Dumbbell Row", muscle: "Back"), TrainingMove(name: "Dumbbell Romanian Deadlift", muscle: "Hamstrings")]),
        TrainingRoutine(id: "upper", name: "Upper body", subtitle: "Push. Pull. Build.", equipment: "Gym", symbol: "dumbbell", moves: [
            TrainingMove(name: "Barbell Bench Press", muscle: "Chest"), TrainingMove(name: "Lat Pulldown", muscle: "Back"),
            TrainingMove(name: "Seated Cable Row", muscle: "Back"), TrainingMove(name: "Lateral Raise", muscle: "Shoulders")]),
        TrainingRoutine(id: "lower", name: "Lower body", subtitle: "A stronger foundation.", equipment: "Gym", symbol: "figure.strengthtraining.functional", moves: [
            TrainingMove(name: "Leg Press", muscle: "Quads"), TrainingMove(name: "Romanian Deadlift", muscle: "Hamstrings"),
            TrainingMove(name: "Hip Thrust", muscle: "Glutes"), TrainingMove(name: "Standing Calf Raise", muscle: "Calves")]),
        TrainingRoutine(id: "home", name: "No gym. No problem.", subtitle: "Make room for movement.", equipment: "Bodyweight", symbol: "house", moves: [
            TrainingMove(name: "Bodyweight Squat", muscle: "Legs"), TrainingMove(name: "Incline Push-Up", muscle: "Chest"),
            TrainingMove(name: "Glute Bridge", muscle: "Glutes"), TrainingMove(name: "Reverse Lunge", muscle: "Legs")])
    ]
}

struct TrainingDraft: Identifiable {
    let id = UUID()
    var name = ""
    var date = Date()
    var notes = ""
    var weightUnit: String? = UserDefaults.standard.string(forKey: "spotter.weightUnit") == "kg" ? "kg" : "lb"
    var moves: [TrainingMove] = []
    var existing: WorkoutEntity?

    init(routine: TrainingRoutine? = nil, workout: WorkoutEntity? = nil, repeatWorkout: Bool = false) {
        if let routine {
            name = routine.name
            moves = routine.moves.map {
                TrainingMove(name: $0.name, muscle: $0.muscle, targetSets: $0.targetSets, targetReps: $0.targetReps, restSeconds: $0.restSeconds)
            }
        }
        if let workout {
            name = workout.name
            notes = workout.notes ?? ""
            weightUnit = workout.weightUnit
            moves = workout.sortedExercises.map {
                TrainingMove(id: repeatWorkout ? UUID() : $0.id, name: $0.name, muscle: $0.muscleGroup ?? "Other", targetSets: $0.plannedSets, targetReps: $0.plannedReps, restSeconds: $0.restOverrideSeconds, targetWeight: $0.targetWeight?.doubleValue, targetRepMinimum: $0.targetRepMinimum > 0 ? Int($0.targetRepMinimum) : nil)
            }
            if !repeatWorkout { existing = workout; date = workout.calendarDate }
        }
    }
    /// Instantiate reusable content; never retain its managed object or exercise IDs.
    init(template: WorkoutEntity) {
        self.init(workout: template, repeatWorkout: true)
    }
}

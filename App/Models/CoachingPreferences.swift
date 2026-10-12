import Foundation

/// Saved with the existing Settings draft; local rules, no cloud or model dependency.
struct CoachingPreferences: Codable, Equatable {
    enum Goal: String, Codable, CaseIterable { case strength = "Strength", muscle = "Muscle growth", general = "General fitness" }
    enum Experience: String, Codable, CaseIterable { case beginner = "Beginner", intermediate = "Intermediate", advanced = "Experienced" }
    enum Aggression: String, Codable, CaseIterable { case conservative = "Conservative", balanced = "Balanced", aggressive = "Aggressive" }
    enum Equipment: String, Codable, CaseIterable { case all = "Full gym", dumbbells = "Dumbbells & bodyweight", bodyweight = "Bodyweight" }
    var goal = Goal.general
    var experience = Experience.intermediate
    var aggression = Aggression.balanced
    var equipment = Equipment.all
    var recoveryFirst = false
    var progressiveOverload = true
    var preferredExercises = ""
    var excludedExercises = ""
    var requiredSuccesses: Int {
        let count = aggression == .conservative ? 3 : aggression == .balanced ? 2 : 1
        return max(experience == .beginner ? 2 : 1, count) + (recoveryFirst ? 1 : 0)
    }
    var maximumIncrease: Double { aggression == .conservative || recoveryFirst ? 0.025 : 0.05 }
    var repRange: ClosedRange<Int> { switch goal { case .strength: 5...8; case .muscle: 8...12; case .general: 8...10 } }
    func tokens(_ text: String) -> [String] { text.split(separator: ",").map { ExerciseCatalog.key(String($0)) }.filter { !$0.isEmpty } }
    func isExcluded(_ name: String) -> Bool { tokens(excludedExercises).contains { ExerciseCatalog.key(name).contains($0) } }
    func isPreferred(_ name: String) -> Bool { tokens(preferredExercises).contains { ExerciseCatalog.key(name).contains($0) } }
    func allows(_ move: TrainingMove) -> Bool {
        guard !isExcluded(move.name) else { return false }
        switch equipment {
        case .all: return true
        case .dumbbells: return TrainingRoutine.starters.filter { $0.equipment == "Dumbbells" || $0.equipment == "Bodyweight" }.flatMap(\.moves).contains { ExerciseCatalog.key($0.name) == ExerciseCatalog.key(move.name) }
        case .bodyweight: return TrainingRoutine.starters.filter { $0.equipment == "Bodyweight" }.flatMap(\.moves).contains { ExerciseCatalog.key($0.name) == ExerciseCatalog.key(move.name) }
        }
    }
    static func load(from defaults: UserDefaults) -> Self {
        guard let data = defaults.data(forKey: "spotter.coaching.v1"), let value = try? JSONDecoder().decode(Self.self, from: data) else { return Self() }
        return value
    }
    func save(to defaults: UserDefaults) {
        if let data = try? JSONEncoder().encode(self) { defaults.set(data, forKey: "spotter.coaching.v1") }
    }
}

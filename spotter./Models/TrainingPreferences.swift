import Foundation

/// A local draft shared by the Settings destinations. Nothing is written until Save.
struct TrainingPreferences: Equatable {
    enum WeightUnit: String, CaseIterable, Identifiable {
        case lb, kg
        var id: String { rawValue }
        var title: String { self == .lb ? "Pounds (lb)" : "Kilograms (kg)" }
    }
    enum Appearance: String, CaseIterable, Identifiable {
        case system, light, dark
        var id: String { rawValue }
        var title: String { rawValue.capitalized }
    }
    var sessionsPerWeek = 3
    var restSeconds = 90
    var weightUnit = WeightUnit.lb
    var weightStep = 2.5
    var appearance = Appearance.system
    var liveActivitiesEnabled = true
    static let weightSteps = [0.5, 1.0, 2.5, 5.0]

    var restDescription: String {
        if restSeconds == 0 { return "Off" }
        if restSeconds.isMultiple(of: 60) { return "\(restSeconds / 60) min" }
        return "\(restSeconds) sec"
    }

    static func load(from defaults: UserDefaults = .standard) -> Self {
        var result = Self()
        if defaults.object(forKey: "profile.sessionsPerWeek") != nil {
            result.sessionsPerWeek = min(max(defaults.integer(forKey: "profile.sessionsPerWeek"), 1), 7)
        }
        if defaults.object(forKey: "spotter.restSeconds") != nil {
            result.restSeconds = min(max(defaults.integer(forKey: "spotter.restSeconds"), 0), 600)
        }
        if defaults.object(forKey: "spotter.liveActivitiesEnabled") != nil {
            result.liveActivitiesEnabled = defaults.bool(forKey: "spotter.liveActivitiesEnabled")
        }
        result.weightUnit = WeightUnit(rawValue: defaults.string(forKey: "spotter.weightUnit") ?? "") ?? .lb
        result.appearance = Appearance(rawValue: defaults.string(forKey: "spotter.appearance") ?? "") ?? .system
        let step = defaults.double(forKey: "spotter.weightStep")
        if weightSteps.contains(step) { result.weightStep = step }
        return result
    }

    func save(to defaults: UserDefaults = .standard) {
        defaults.set(sessionsPerWeek, forKey: "profile.sessionsPerWeek")
        defaults.set(restSeconds, forKey: "spotter.restSeconds")
        defaults.set(weightUnit.rawValue, forKey: "spotter.weightUnit")
        defaults.set(weightStep, forKey: "spotter.weightStep")
        defaults.set(appearance.rawValue, forKey: "spotter.appearance")
        defaults.set(liveActivitiesEnabled, forKey: "spotter.liveActivitiesEnabled")
    }
}

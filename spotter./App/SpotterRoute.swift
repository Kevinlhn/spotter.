import Foundation

enum SpotterTab: String, Hashable {
    case today, plan, library, progress
    var title: String { rawValue.capitalized }
    var symbol: String {
        switch self { case .today: "sun.max"; case .plan: "calendar"; case .library: "dumbbell"; case .progress: "chart.bar.xaxis" }
    }
}

/// Root owns transitions between editors and active sessions, avoiding stacked presentations.
enum SpotterSheet: Identifiable {
    case exerciseTrends
    case settings
    case quickStart
    case choosePlan(Date)
    case builder(TrainingDraft, WorkoutBuilderMode)
    case journal(WorkoutEntity)

    var id: String {
        switch self {
        case .exerciseTrends: "exercise-trends"
        case .settings: "settings"
        case .quickStart: "quick-start"
        case .choosePlan(let date): "choose-\(date.timeIntervalSince1970)"
        case .builder(let draft, _): "draft-\(draft.id)"
        case .journal(let workout): "journal-\(workout.id)"
        }
    }
}

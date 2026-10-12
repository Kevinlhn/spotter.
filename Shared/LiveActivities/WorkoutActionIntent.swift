import AppIntents
import OSLog

nonisolated enum WorkoutAction: String, Codable {
    case complete, undo, previousSet, nextSet, previousExercise, nextExercise
    case rest, skipRest, weightDown, weightUp, repsDown, repsUp
}

struct WorkoutActionIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Update workout"
    static let supportedModes: IntentModes = .background
    static let isDiscoverable = false
    @Parameter(title: "Workout") var workoutID: String
    @Parameter(title: "Revision") var revision: String
    @Parameter(title: "Action") var actionCode: String

    init() {}
    init(workoutID: String, revision: String, action: WorkoutAction) {
        self.workoutID = workoutID; self.revision = revision; self.actionCode = action.rawValue
    }
    @MainActor func perform() async throws -> some IntentResult {
        guard let action = WorkoutAction(rawValue: actionCode) else { return .result() }
        #if !SPOTTER_WIDGET
        Logger(subsystem: "com.kevinlhn.spotter-", category: "WorkoutIntent").notice("Performing workout action in app")
        try await WorkoutIntentHandler.perform(workoutID: workoutID, revision: revision, action: action)
        #else
        Logger(subsystem: "com.kevinlhn.spotter-", category: "WorkoutIntent").error("Unexpected widget execution of LiveActivityIntent")
        #endif
        return .result()
    }
}

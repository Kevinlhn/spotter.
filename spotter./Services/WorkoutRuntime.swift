import Foundation
import CoreData
import ActivityKit
import OSLog

/// Both foreground launch and LiveActivityIntent use this one container and main-actor store.
@MainActor
final class WorkoutRuntime {
    static let shared = WorkoutRuntime()
    private var loading: Task<TrainingStore, Error>?
    func store() async throws -> TrainingStore {
        if let loading { return try await loading.value }
        let task = Task { @MainActor in
            let persistence = try await Persistence.load(inMemory: ProcessInfo.processInfo.arguments.contains("UI_TESTING"))
            let store = TrainingStore(context: persistence.container.viewContext)
            if let workout = store.active, workout.sessionData == nil {
                var state = workout.sessionState
                let defaults = UserDefaults.standard
                if let id = UUID(uuidString: defaults.string(forKey: "spotter.currentExerciseID") ?? ""),
                   let exercise = workout.sortedExercises.first(where: { $0.id == id }) { state = store.entryState(for: exercise, keeping: state) }
                let deadline = defaults.double(forKey: "spotter.restUntil")
                state.restUntil = deadline.isFinite && deadline > Date().timeIntervalSince1970 ? deadline : 0
                workout.sessionState = state
                guard store.persist() else { throw WorkoutCommandError.saveFailed }
                defaults.removeObject(forKey: "spotter.restUntil")
                defaults.removeObject(forKey: "spotter.currentExerciseID")
            }
            WatchWorkoutBridge.shared.attach(store)
            return store
        }
        loading = task
        do { return try await task.value }
        catch { loading = nil; throw error }
    }
}

enum WorkoutCommandError: Error { case saveFailed }

@MainActor
enum WorkoutIntentHandler {
    static func perform(workoutID: String, revision: String, action: WorkoutAction) async throws {
        guard let id = UUID(uuidString: workoutID) else { return }
        let activities = Activity<WorkoutActivityAttributes>.activities.filter {
            $0.attributes.workoutID == id && ($0.activityState == .active || $0.activityState == .stale)
        }
        guard !activities.isEmpty else { Logger(subsystem: "com.kevinlhn.spotter-", category: "WorkoutIntent").notice("No matching live activity"); return }
        let store = try await WorkoutRuntime.shared.store()
        guard TrainingPreferences.load().liveActivitiesEnabled, let workout = store.active, workout.id == id else {
            for activity in activities { await activity.end(nil, dismissalPolicy: .immediate) }
            return
        }
        let result = store.performWorkoutAction(action, workout: workout, expectedRevision: revision)
        Logger(subsystem: "com.kevinlhn.spotter-", category: "WorkoutIntent").notice("Command result: \(String(describing: result), privacy: .public)")
        if result == .failed { throw WorkoutCommandError.saveFailed }
        // Re-read after each await so an older suspended intent cannot publish an old snapshot.
        for activity in activities {
            if let snapshot = WorkoutActivitySnapshot.make(workout: store.active) {
                await activity.update(ActivityContent(state: snapshot.content, staleDate: snapshot.content.restEndsAt))
            } else { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }
}

import ActivityKit
import Combine
import Foundation

/// Owns one local Live Activity for the one active workout. No push service or background timer is needed.
@MainActor
final class WorkoutActivityCoordinator: ObservableObject {
    @Published private(set) var statusMessage: String?

    private struct Request {
        let snapshot: WorkoutActivitySnapshot?
        let enabled: Bool
        let foreground: Bool
    }

    private typealias WorkoutActivity = Activity<WorkoutActivityAttributes>
    private let defaults: UserDefaults
    private let usesActivityKit: Bool
    private let rememberedWorkoutKey = "spotter.liveActivity.startedWorkoutID"
    private var pending: Request?
    private var worker: Task<Void, Never>?
    private var stateObservation: Task<Void, Never>?
    private var trackedActivityID: String?
    private var lastContent: WorkoutActivityAttributes.ContentState?
    private var wasEnabled: Bool?
    private var wasForeground = false
    private var failedWorkoutID: UUID?

    init(defaults: UserDefaults = .standard, arguments: [String] = ProcessInfo.processInfo.arguments) {
        self.defaults = defaults
        usesActivityKit = !arguments.contains("UI_TESTING") || arguments.contains("UI_TESTING_LIVE_ACTIVITY")
    }

    /// Calls coalesce into an ordered worker, independent of SwiftUI cancelling a previous `.task(id:)`.
    func reconcile(snapshot: WorkoutActivitySnapshot?, enabled: Bool, foreground: Bool) async {
        guard usesActivityKit, !Task.isCancelled else { return }
        if !enabled || (wasEnabled == false && enabled) {
            defaults.removeObject(forKey: rememberedWorkoutKey)
            failedWorkoutID = nil
        }
        if foreground && !wasForeground { failedWorkoutID = nil }
        wasEnabled = enabled
        wasForeground = foreground
        pending = Request(snapshot: snapshot, enabled: enabled, foreground: foreground)
        if worker == nil {
            worker = Task { [weak self] in
                guard let self else { return }
                await self.drain()
            }
        }
        await worker?.value
    }

    private func drain() async {
        while let request = pending {
            pending = nil
            await apply(request)
        }
        worker = nil
    }

    private func apply(_ request: Request) async {
        let snapshot = request.enabled ? request.snapshot : nil
        let activities = WorkoutActivity.activities
        let matching = activities.filter {
            $0.attributes.workoutID == snapshot?.workoutID && isRunning($0)
        }.sorted { $0.id < $1.id }
        let current = matching.first { $0.id == trackedActivityID } ?? matching.first

        // Finish/discard, changing sessions, and disabling all remove stale or duplicate activities.
        for activity in activities where activity.id != current?.id || snapshot == nil {
            if activity.id == trackedActivityID { stopObserving() }
            await activity.end(nil, dismissalPolicy: .immediate)
        }

        guard let snapshot else {
            stopObserving()
            defaults.removeObject(forKey: rememberedWorkoutKey)
            failedWorkoutID = nil
            statusMessage = nil
            return
        }

        if let current {
            remember(snapshot.workoutID)
            observe(current)
            if lastContent != snapshot.content {
                // The rest deadline marks the ready-to-log transition; the workout remains active.
                await current.update(ActivityContent(state: snapshot.content, staleDate: snapshot.content.restEndsAt))
                lastContent = snapshot.content
            }
            statusMessage = isRunning(current)
                ? "Live Activity is showing for \(snapshot.workoutName)."
                : "This workout’s Live Activity has ended. Save with Live Activities off, then turn them back on to show it again."
            return
        }

        stopObserving()
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            statusMessage = "Live Activities are unavailable. Check Spotter’s settings in the Settings app."
            return
        }
        // Remember a successful request across app relaunches. A dismissed/system-ended activity stays gone.
        guard defaults.string(forKey: rememberedWorkoutKey) != snapshot.workoutID.uuidString else {
            statusMessage = "This workout’s Live Activity has ended. Save with Live Activities off, then turn them back on to show it again."
            return
        }
        guard request.foreground, failedWorkoutID != snapshot.workoutID else { return }
        do {
            let activity = try WorkoutActivity.request(
                attributes: snapshot.attributes,
                content: ActivityContent(state: snapshot.content, staleDate: snapshot.content.restEndsAt),
                pushType: nil
            )
            remember(snapshot.workoutID)
            observe(activity)
            lastContent = snapshot.content
            statusMessage = "Live Activity is showing for \(snapshot.workoutName)."
        } catch {
            failedWorkoutID = snapshot.workoutID
            statusMessage = "The Live Activity couldn’t start. Your workout still saves normally. Try reopening Spotter."
        }
    }

    private func isRunning(_ activity: WorkoutActivity) -> Bool {
        activity.activityState == .active || activity.activityState == .stale
    }

    private func remember(_ workoutID: UUID) {
        defaults.set(workoutID.uuidString, forKey: rememberedWorkoutKey)
    }

    private func observe(_ activity: WorkoutActivity) {
        guard trackedActivityID != activity.id else { return }
        stopObserving()
        trackedActivityID = activity.id
        stateObservation = Task { [weak self] in
            for await state in activity.activityStateUpdates {
                guard !Task.isCancelled, let self, self.trackedActivityID == activity.id else { return }
                if state == .dismissed || state == .ended {
                    self.trackedActivityID = nil
                    self.lastContent = nil
                    self.statusMessage = "This workout’s Live Activity has ended. Save with Live Activities off, then turn them back on to show it again."
                    return
                }
            }
        }
    }

    private func stopObserving() {
        stateObservation?.cancel()
        stateObservation = nil
        trackedActivityID = nil
        lastContent = nil
    }
}

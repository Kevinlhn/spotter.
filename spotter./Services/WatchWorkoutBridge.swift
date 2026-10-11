import Foundation
import WatchConnectivity
import Combine
import ActivityKit

/// Activated at process launch, including launches caused by WatchConnectivity.
@MainActor
final class WatchWorkoutBridge: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchWorkoutBridge()
    @Published private(set) var status = "Checking Apple Watch…"
    private var store: TrainingStore?
    private var changes: AnyCancellable?
    private let defaults = UserDefaults.standard
    private var session: WCSession? { WCSession.isSupported() ? .default : nil }

    func activate() {
        guard let session else { status = "Apple Watch requires a paired iPhone."; return }
        session.delegate = self
        session.activate()
    }

    func attach(_ store: TrainingStore) {
        guard self.store !== store else { return }
        self.store = store
        changes = store.$workouts.dropFirst().sink { [weak self] _ in
            // @Published emits before assignment. Read the committed store on the next turn.
            Task { @MainActor [weak self] in self?.publish() }
        }
        publish()
    }

    private func envelope() -> WatchWorkoutEnvelope {
        let key = "spotter.watch.installation"
        let installation = defaults.string(forKey: key) ?? UUID().uuidString
        defaults.set(installation, forKey: key)
        let sequence = defaults.integer(forKey: "spotter.watch.sequence") + 1
        defaults.set(sequence, forKey: "spotter.watch.sequence")
        return WatchWorkoutEnvelope(installationID: installation, sequence: sequence, updatedAt: .now,
                                    workout: store.flatMap { WatchWorkoutHandler.snapshot(store: $0) })
    }

    func publish() {
        guard store != nil, let session, session.activationState == .activated,
              session.isPaired, session.isWatchAppInstalled else { updateStatus(); return }
        let value = envelope()
        guard let data = try? JSONEncoder().encode(value) else { return }
        do { try session.updateApplicationContext(["snapshot": data]); updateStatus() }
        catch { status = "Waiting to sync. Open Spotter on Apple Watch." }
        if session.isReachable { session.sendMessage(["snapshot": data], replyHandler: nil, errorHandler: { _ in }) }
    }

    private func updateStatus() {
        guard let session else { status = "Apple Watch requires a paired iPhone."; return }
        if !session.isPaired { status = "Pair an Apple Watch with this iPhone to get started." }
        else if !session.isWatchAppInstalled { status = "Install Spotter from the Watch app on your iPhone." }
        else if session.isReachable { status = "Connected. Your active workout is ready on Apple Watch." }
        else { status = "Installed. Open Spotter on Apple Watch to connect." }
    }

    private func respond(to request: WatchWorkoutRequest) async -> WatchWorkoutReply {
        do {
            let store = try await WorkoutRuntime.shared.store()
            attach(store)
            let result = WatchWorkoutHandler.perform(request, store: store)
            let response = WatchWorkoutReply(requestID: request.id, outcome: result.0, envelope: envelope(), message: result.1)
            publish()
            // Watch commands also refresh an already-running Live Activity while the UI sleeps.
            if result.0 == .applied {
                for activity in Activity<WorkoutActivityAttributes>.activities {
                    if let snapshot = WorkoutActivitySnapshot.make(workout: store.active), snapshot.workoutID == activity.attributes.workoutID {
                        await activity.update(ActivityContent(state: snapshot.content, staleDate: snapshot.content.restEndsAt))
                    }
                }
            }
            return response
        } catch {
            return WatchWorkoutReply(requestID: request.id, outcome: .failed, envelope: nil,
                                     message: "Open Spotter on iPhone to load your workout, then try again.")
        }
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.updateStatus()
            if let store = try? await WorkoutRuntime.shared.store() { self.attach(store); self.publish() }
        }
    }
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) { Task { @MainActor in self.publish() } }
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) { Task { @MainActor in self.publish() } }
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let data = message["request"] as? Data,
              let request = try? JSONDecoder().decode(WatchWorkoutRequest.self, from: data) else {
            replyHandler(["error": "Unsupported workout message"]); return
        }
        Task { @MainActor in
            let response = await self.respond(to: request)
            replyHandler(["reply": (try? JSONEncoder().encode(response)) ?? Data()])
        }
    }
}

@MainActor
enum WatchWorkoutHandler {
    static func snapshot(store: TrainingStore) -> WatchWorkoutSnapshot? {
        guard let value = WorkoutActivitySnapshot.make(workout: store.active), let revision = value.content.revision else { return nil }
        let state = value.content
        return WatchWorkoutSnapshot(workoutID: value.workoutID, revision: revision, workoutName: value.workoutName,
            exerciseName: state.exerciseName, exerciseNumber: state.exerciseNumber, exerciseCount: state.exerciseCount,
            loggedSets: state.loggedSets, targetSets: state.targetSets, sessionSets: state.sessionSets,
            weight: state.currentWeight ?? 0, reps: state.currentReps ?? 8, unit: state.weightUnit ?? "load",
            restEndsAt: state.restEndsAt, editingSet: state.editingSet == true)
    }

    static func perform(_ request: WatchWorkoutRequest, store: TrainingStore, now: Date = .now) -> (WatchWorkoutReply.Outcome, String?) {
        guard request.version == 1 else { return (.failed, "Update Spotter on both devices to continue.") }
        guard let action = request.action else { return (.refreshed, nil) }
        guard let workout = store.active, workout.id == request.workoutID,
              workout.sessionState.revision == request.revision, let snapshot = snapshot(store: store) else {
            return (.stale, "Your workout changed on iPhone. Check the refreshed set before trying again.")
        }
        guard !snapshot.editingSet else { return (.failed, "Finish editing your recorded set on iPhone first.") }
        if action == .complete && (snapshot.finishedExercise || snapshot.isResting(at: now)) {
            return (.stale, "Finish rest or move to the next exercise before logging.")
        }
        guard let phoneAction = WorkoutAction(rawValue: action.rawValue), let revision = request.revision else {
            return (.failed, "This action is unavailable.")
        }
        switch store.performWorkoutAction(phoneAction, workout: workout, expectedRevision: revision, now: now) {
        case .applied: return (.applied, nil)
        case .stale: return (.stale, "Your workout changed. Check the refreshed set before trying again.")
        case .failed: return (.failed, "The change couldn’t be saved. Check Spotter on iPhone.")
        }
    }
}

import Foundation
import WatchConnectivity
import Combine
import WatchKit

@MainActor
final class WatchWorkoutStore: NSObject, ObservableObject, WCSessionDelegate {
    @Published private(set) var envelope: WatchWorkoutEnvelope?
    @Published private(set) var reachable = false
    @Published private(set) var pending: UUID?
    @Published private(set) var confirmed = false
    @Published var message: String?
    private let cacheKey = "spotter.watch.lastSnapshot"
    private var timeout: Task<Void, Never>?
    var canAct: Bool { reachable && confirmed && pending == nil }

    override init() {
        super.init()
        if let data = UserDefaults.standard.data(forKey: cacheKey) {
            envelope = try? JSONDecoder().decode(WatchWorkoutEnvelope.self, from: data)
        }
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func refresh() { send(nil) }
    func perform(_ action: WatchWorkoutAction) { guard canAct else { return }; send(action) }

    private func send(_ action: WatchWorkoutAction?) {
        guard pending == nil else { return }
        let session = WCSession.default
        reachable = session.activationState == .activated && session.isReachable
        guard reachable else {
            confirmed = false
            message = "Open Spotter on your iPhone to connect."
            return
        }
        let request = WatchWorkoutRequest(workoutID: envelope?.workout?.workoutID,
            revision: envelope?.workout?.revision, action: action)
        guard let data = try? JSONEncoder().encode(request) else { return }
        pending = request.id; message = nil
        timeout?.cancel()
        timeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(10))
            guard !Task.isCancelled else { return }
            self?.failed(request.id)
        }
        session.sendMessage(["request": data], replyHandler: { [weak self] dictionary in
            let data = dictionary["reply"] as? Data
            Task { @MainActor in
                guard let self, self.pending == request.id else { return }
                guard let data, let reply = try? JSONDecoder().decode(WatchWorkoutReply.self, from: data), reply.requestID == request.id else {
                    self.failed(request.id); return
                }
                self.timeout?.cancel(); self.pending = nil
                if let envelope = reply.envelope { self.receive(envelope) }
                else { self.confirmed = false }
                self.message = reply.message
                if reply.outcome == .applied { WKInterfaceDevice.current().play(.success) }
            }
        }, errorHandler: { [weak self] _ in
            Task { @MainActor in self?.failed(request.id) }
        })
    }

    private func failed(_ id: UUID) {
        guard pending == id else { return }
        timeout?.cancel(); pending = nil; confirmed = false
        message = "Couldn’t confirm the change. Refresh and check your set before trying again."
    }

    private func receive(_ value: WatchWorkoutEnvelope) {
        guard value.supersedes(envelope) else { return }
        envelope = value; confirmed = true
        if let data = try? JSONEncoder().encode(value) { UserDefaults.standard.set(data, forKey: cacheKey) }
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in self.refresh() }
    }
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.reachable = WCSession.default.isReachable
            if self.reachable { self.refresh() } else { self.confirmed = false }
        }
    }
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        accept(applicationContext)
    }
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) { accept(message) }
    nonisolated private func accept(_ dictionary: [String: Any]) {
        guard let data = dictionary["snapshot"] as? Data,
              let value = try? JSONDecoder().decode(WatchWorkoutEnvelope.self, from: data) else { return }
        Task { @MainActor in self.receive(value) }
    }
}

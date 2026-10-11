import SwiftUI

struct AppleWatchSettings: View {
    @ObservedObject private var watch = WatchWorkoutBridge.shared
    var body: some View {
        SettingsForm(title: "Apple Watch") {
            Section {
                Label(watch.status, systemImage: "applewatch")
                Button("Refresh connection") { watch.activate(); watch.publish() }
            } header: { Text("Connection") }
            Section {
                Text("Install Spotter in the Watch app on your iPhone, then open Spotter on both devices. Start or resume a workout on iPhone to see it on your wrist.")
                Text("Log sets, follow rest, undo an accidental log, and adjust your next set. Changes save to the same workout on iPhone.")
            } header: { Text("Your workout companion") } footer: {
                Text("Your iPhone must be reachable to save changes. When disconnected, the Watch keeps the last synced view and rest deadline. Refresh before continuing. This companion does not record heart rate, calories, or Apple Health workouts.")
            }
        }
    }
}

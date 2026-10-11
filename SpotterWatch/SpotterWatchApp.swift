import SwiftUI

@main
struct SpotterWatchApp: App {
    @StateObject private var store = WatchWorkoutStore()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            WatchWorkoutView(store: store)
                .onChange(of: scenePhase) { _, phase in if phase == .active { store.refresh() } }
        }
    }
}

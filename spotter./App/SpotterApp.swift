import SwiftUI

@main
struct spotter_App: App {
    @StateObject private var launch = SpotterLaunchCoordinator()
    @State private var incomingURL: URL?

    init() { WatchWorkoutBridge.shared.activate() }

    var body: some Scene {
        WindowGroup {
            SpotterLaunchView(launch: launch, incomingURL: $incomingURL)
                .onOpenURL { incomingURL = $0 }
        }
    }
}

import Foundation

enum SpotterDeepLink {
    static func workoutID(from url: URL) -> UUID? {
        guard url.scheme?.lowercased() == "spotter", url.host?.lowercased() == "workout",
              url.pathComponents.count == 2 else { return nil }
        return UUID(uuidString: url.lastPathComponent)
    }
}

struct WorkoutActivityRequest: Hashable {
    let snapshot: WorkoutActivitySnapshot?
    let enabled: Bool
    let foreground: Bool
}

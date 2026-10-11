import Foundation
import Testing
@testable import spotter_

struct SpotterDeepLinkTests {
    @Test func liveActivityLinkRoundTripsToExactlyItsWorkout() {
        let id = UUID()
        let url = WorkoutActivityAttributes.resumeURL(workoutID: id)
        #expect(SpotterDeepLink.workoutID(from: url) == id)
    }

    @Test func routingAcceptsCaseInsensitiveSchemeAndHost() throws {
        let id = UUID()
        let url = try #require(URL(string: "SPOTTER://WORKOUT/\(id.uuidString.lowercased())"))
        #expect(SpotterDeepLink.workoutID(from: url) == id)
    }

    @Test func unrelatedMalformedAndExtraPathLinksCannotOpenAWorkout() throws {
        let id = UUID().uuidString
        let invalid = [
            "https://workout/\(id)",
            "counter://workout/\(id)",
            "spotter://library/\(id)",
            "spotter://workout",
            "spotter://workout/",
            "spotter://workout/not-a-uuid",
            "spotter://workout/\(id)/edit",
            "spotter://workout/workouts/\(id)",
            "spotter:///\(id)"
        ]
        for text in invalid {
            let url = try #require(URL(string: text))
            #expect(SpotterDeepLink.workoutID(from: url) == nil)
        }
    }
}

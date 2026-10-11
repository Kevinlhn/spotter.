import Foundation
import Testing
@testable import spotter_

struct TrainingPreferencesTests {
    @Test func liveActivityDefaultsOnAndOnlyChangesWhenTheDraftIsSaved() throws {
        let suite = "spotter-live-activity-preferences-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var draft = TrainingPreferences.load(from: defaults)
        #expect(draft.liveActivitiesEnabled)
        #expect(defaults.object(forKey: "spotter.liveActivitiesEnabled") == nil)

        draft.liveActivitiesEnabled = false
        // Cancelling this draft must leave both the stored key and effective default unchanged.
        #expect(TrainingPreferences.load(from: defaults).liveActivitiesEnabled)
        #expect(defaults.object(forKey: "spotter.liveActivitiesEnabled") == nil)
        draft.save(to: defaults)
        #expect(defaults.object(forKey: "spotter.liveActivitiesEnabled") != nil)
        #expect(!TrainingPreferences.load(from: defaults).liveActivitiesEnabled)

        var enabledDraft = TrainingPreferences.load(from: defaults)
        enabledDraft.liveActivitiesEnabled = true
        #expect(!TrainingPreferences.load(from: defaults).liveActivitiesEnabled)
        enabledDraft.save(to: defaults)
        #expect(TrainingPreferences.load(from: defaults).liveActivitiesEnabled)
    }

    @Test func draftDoesNotWriteUntilSaveAndRetainsExistingKeys() throws {
        let suite = "spotter-preferences-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(4, forKey: "profile.sessionsPerWeek")
        defaults.set("kg", forKey: "spotter.weightUnit")
        var draft = TrainingPreferences.load(from: defaults)
        #expect(draft.sessionsPerWeek == 4)
        #expect(draft.weightUnit == .kg)
        draft.sessionsPerWeek = 5
        draft.appearance = .dark
        draft.restSeconds = 0
        draft.weightStep = 1
        #expect(defaults.integer(forKey: "profile.sessionsPerWeek") == 4)
        #expect(defaults.string(forKey: "spotter.appearance") == nil)
        draft.save(to: defaults)
        #expect(TrainingPreferences.load(from: defaults) == draft)
        #expect(defaults.string(forKey: "spotter.appearance") == "dark")
        #expect(defaults.integer(forKey: "spotter.restSeconds") == 0)
    }

    @Test func invalidStoredPreferencesRecoverToUsableValues() throws {
        let suite = "spotter-preferences-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        #expect(TrainingPreferences.load(from: defaults) == TrainingPreferences())
        defaults.set(100, forKey: "profile.sessionsPerWeek")
        defaults.set(-5, forKey: "spotter.restSeconds")
        defaults.set("unknown", forKey: "spotter.weightUnit")
        defaults.set("unknown", forKey: "spotter.appearance")
        defaults.set(123, forKey: "spotter.weightStep")
        let result = TrainingPreferences.load(from: defaults)
        #expect(result.sessionsPerWeek == 7)
        #expect(result.restSeconds == 0)
        #expect(result.weightUnit == .lb)
        #expect(result.appearance == .system)
        #expect(result.weightStep == 2.5)
    }
}

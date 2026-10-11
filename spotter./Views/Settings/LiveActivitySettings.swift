import SwiftUI
import ActivityKit

struct LiveActivitySettings: View {
    @EnvironmentObject private var activities: WorkoutActivityCoordinator
    @Environment(\.openURL) private var openURL
    @Binding var draft: TrainingPreferences

    var body: some View {
        SettingsForm(title: "Live Activity") {
            Section {
                Toggle("Show during workouts", isOn: $draft.liveActivitiesEnabled)
                    .accessibilityIdentifier("live-activity-toggle")
            } footer: {
                Text("See your next set, log it, and follow your rest timer from the Lock Screen or expanded Dynamic Island. Undo corrects your last log. Tap the exercise or weight to edit in Spotter. Your choice applies when you save Settings.")
            }
            Section {
                SettingsRow(title: "Made for your session", symbol: "dumbbell",
                            detail: "Starts with a workout and ends when you finish or discard it. Closing Spotter keeps the activity visible.")
                if let message = activities.statusMessage {
                    Text(message).font(.subheadline).foregroundStyle(SpotterStyle.secondaryText).accessibilityIdentifier("live-activity-status")
                }
                if !ActivityAuthorizationInfo().areActivitiesEnabled {
                    Button("Open iOS Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                    Text("Allow Live Activities for Spotter in iOS Settings to show workouts on your Lock Screen.").font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                }
            } header: { Text("How it works") } footer: {
                Text("iOS controls availability and duration. If you dismiss a workout’s Live Activity, Spotter respects that. To show it again, save this preference off, then enable and save it again.")
            }
        }
    }
}

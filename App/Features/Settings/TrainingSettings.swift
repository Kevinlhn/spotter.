import SwiftUI

/// A single draft spans all destinations. Back navigation never reloads preferences.
struct TrainingSettings: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft = TrainingPreferences()
    @State private var initial = TrainingPreferences()
    @State private var loaded = false
    private enum Destination: Hashable { case training, coaching, units, appearance, activity, watch, data, about }

    var body: some View {
        NavigationStack {
            SettingsForm(title: "Settings") {
                Section {
                    NavigationLink(value: Destination.training) {
                        SettingsRow(title: "Workout preferences", symbol: "slider.horizontal.3",
                                    detail: "\(draft.sessionsPerWeek) sessions / week · Rest \(draft.restDescription.lowercased())")
                    }.accessibilityIdentifier("settings-training")
                    NavigationLink(value: Destination.coaching) {
                        SettingsRow(title: "Coaching", symbol: "sparkles", detail: "Goals, recovery, and progression")
                    }.accessibilityIdentifier("settings-coaching")
                    NavigationLink(value: Destination.units) {
                        SettingsRow(title: "Units", symbol: "scalemass", detail: draft.weightUnit.title)
                    }.accessibilityIdentifier("settings-units")
                } header: { Text("Training") }
                Section {
                    NavigationLink(value: Destination.appearance) {
                        SettingsRow(title: "Appearance", symbol: "circle.lefthalf.filled", detail: draft.appearance.title)
                    }.accessibilityIdentifier("settings-appearance")
                    NavigationLink(value: Destination.activity) {
                        SettingsRow(title: "Live Activity", symbol: "platter.filled.top.iphone", detail: draft.liveActivitiesEnabled ? "Your workout at a glance" : "Off")
                    }.accessibilityIdentifier("settings-live-activity")
                    NavigationLink(value: Destination.watch) {
                        SettingsRow(title: "Apple Watch", symbol: "applewatch", detail: "Sets and rest on your wrist")
                    }.accessibilityIdentifier("settings-apple-watch")
                } header: { Text("App") }
                Section {
                    NavigationLink(value: Destination.data) {
                        SettingsRow(title: "Data & privacy", symbol: "lock", detail: "On-device storage and workout export")
                    }.accessibilityIdentifier("settings-data")
                    NavigationLink(value: Destination.about) {
                        SettingsRow(title: "About Spotter", symbol: "info.circle", detail: "by kevinlhn.")
                    }
                } header: { Text("Your data") } footer: {
                    Text("Preference changes apply together when you tap Save.")
                }
            }
            .toolbar { draftActions }
            .navigationDestination(for: Destination.self) { destination in
                destinationView(destination).toolbar { draftActions }
            }
            .onAppear {
                guard !loaded else { return }
                initial = TrainingPreferences.load()
                draft = initial
                loaded = true
            }
        }
        .tint(SpotterStyle.foregroundAccent)
        .interactiveDismissDisabled(draft != initial)
    }

    @ToolbarContentBuilder
    private var draftActions: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
                dismiss()
                draft.save()
            }.accessibilityIdentifier("save-settings")
        }
    }

    @ViewBuilder
    private func destinationView(_ destination: Destination) -> some View {
        switch destination {
        case .training: WorkoutPreferenceSettings(draft: $draft)
        case .coaching: CoachingSettings(draft: $draft)
        case .units: UnitSettings(draft: $draft)
        case .appearance: AppearanceSettings(draft: $draft)
        case .activity: LiveActivitySettings(draft: $draft)
        case .watch: AppleWatchSettings()
        case .data: DataPrivacySettings()
        case .about: AboutSettings()
        }
    }
}

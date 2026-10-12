import SwiftUI

struct WorkoutPreferenceSettings: View {
    @Binding var draft: TrainingPreferences
    var body: some View {
        SettingsForm(title: "Workout preferences") {
            Section {
                Stepper(value: $draft.sessionsPerWeek, in: 1...7) {
                    LabeledContent("Weekly target", value: "\(draft.sessionsPerWeek) sessions")
                }.accessibilityIdentifier("settings-weekly-target")
            } header: { Text("Your rhythm") } footer: {
                Text("Your weekly progress uses this target. It does not schedule workouts for you.")
            }
            Section {
                Stepper(value: $draft.restSeconds, in: 0...600, step: 30) {
                    LabeledContent("Rest between sets", value: draft.restDescription)
                }.accessibilityIdentifier("settings-rest")
            } header: { Text("Rest timer") } footer: {
                Text("Starts after you log a set. Choose Off to disable it. An exercise's own rest setting takes priority.")
            }
            Section {
                Picker("Weight button increment", selection: $draft.weightStep) {
                    ForEach(TrainingPreferences.weightSteps, id: \.self) { step in
                        Text("\(step.formatted()) \(draft.weightUnit.rawValue)").tag(step)
                    }
                }
            } header: { Text("Quick logging") } footer: {
                Text("The + and − weight buttons use this amount in the current workout's unit.")
            }
        }
    }
}

struct UnitSettings: View {
    @Binding var draft: TrainingPreferences
    var body: some View {
        SettingsForm(title: "Units") {
            Section {
                Picker("New workout weights", selection: $draft.weightUnit) {
                    ForEach(TrainingPreferences.WeightUnit.allCases) { value in Text(value.title).tag(value) }
                }.pickerStyle(.inline)
            } footer: {
                Text("Applies to new workouts. Saved workouts and sessions keep their original units; weights are never silently converted.")
            }
        }
    }
}

struct AppearanceSettings: View {
    @Binding var draft: TrainingPreferences
    var body: some View {
        SettingsForm(title: "Appearance") {
            Section {
                Picker("Appearance", selection: $draft.appearance) {
                    ForEach(TrainingPreferences.Appearance.allCases) { value in Text(value.title).tag(value) }
                }.pickerStyle(.inline)
            } footer: {
                Text("System follows your device. Your choice applies when you save Settings.")
            }
            Section {
                Text("Spotter follows your device's text size, Reduce Motion, Reduce Transparency, and Increase Contrast settings.")
                    .font(.subheadline).foregroundStyle(SpotterStyle.secondaryText)
            } header: { Text("Accessibility") }
        }
    }
}

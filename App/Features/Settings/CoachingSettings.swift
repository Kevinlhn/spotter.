import SwiftUI

struct CoachingSettings: View {
    @Binding var draft: TrainingPreferences
    var body: some View {
        SettingsForm(title: "Coaching") {
            Section {
                Picker("Primary goal", selection: $draft.coaching.goal) { ForEach(CoachingPreferences.Goal.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                Picker("Experience", selection: $draft.coaching.experience) { ForEach(CoachingPreferences.Experience.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                Stepper("\(draft.sessionsPerWeek) sessions per week", value: $draft.sessionsPerWeek, in: 1...7)
                Toggle("Favor recovery", isOn: $draft.coaching.recoveryFirst)
            } header: { Text("Your training") } footer: { Text("Goal and experience shape suggested routines. Recovery favors fewer sets, longer rest, and more evidence before increasing load.") }
            Section {
                Toggle("Progressive overload", isOn: $draft.coaching.progressiveOverload).accessibilityIdentifier("coaching-overload")
                Picker("Recommendation pace", selection: $draft.coaching.aggression) { ForEach(CoachingPreferences.Aggression.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
            } header: { Text("Progression") } footer: { Text("Conservative waits for more successful sessions and caps load steps at 2.5%. Balanced and Aggressive cap steps at 5%; Aggressive needs less history. Missed reps and fatigue still prevent increases. Existing targets never change automatically.") }
            Section {
                Picker("Available equipment", selection: $draft.coaching.equipment) { ForEach(CoachingPreferences.Equipment.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                TextField("Preferred exercises, comma separated", text: $draft.coaching.preferredExercises, axis: .vertical)
                TextField("Exclude exercises, comma separated", text: $draft.coaching.excludedExercises, axis: .vertical)
            } header: { Text("Exercise choices") } footer: { Text("Name fragments filter suggested routines and substitutions. For limited equipment, only known compatible catalog exercises are suggested. Your existing routines and history are preserved.") }
            Section {
                Text("Powered by local rules using your saved sets and these preferences. No cloud AI, generated claims, or automatic workout changes.")
            } header: { Text("How coaching works") }
        }
    }
}

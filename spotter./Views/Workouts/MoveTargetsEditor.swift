import SwiftUI

/// Shared progressive controls, used in a draft and between sets.
struct MoveTargetsEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State var move: TrainingMove
    var weightUnit: String? = nil
    var onSave: (TrainingMove) -> Bool
    @State private var customRest = false

    var body: some View {
        NavigationStack {
            SpotterPage {
                PageHeading(eyebrow: "YOUR WAY TO TRAIN", title: move.name, subtitle: "Targets guide your session. You can always log more or less.")
                Surface {
                    VStack(spacing: 24) {
                        Stepper(value: $move.targetSets, in: 1...20) {
                            Label("\(move.targetSets) sets", systemImage: "square.stack.3d.up")
                        }.accessibilityIdentifier("target-sets")
                        Divider().overlay(SpotterStyle.divider)
                        Stepper(value: $move.targetReps, in: 1...999) {
                            Label("\(move.targetReps) reps / set", systemImage: "repeat")
                        }
                        Toggle("Set a planned weight", isOn: Binding(get: { move.targetWeight != nil }, set: { move.targetWeight = $0 ? (move.targetWeight ?? 0) : nil }))
                        if move.targetWeight != nil {
                            HStack {
                                Text("Weight (\(weightUnit ?? "load"))")
                                TextField("0", value: Binding(get: { move.targetWeight ?? 0 }, set: { move.targetWeight = $0 }), format: .number)
                                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            }
                        }
                        Toggle("Use a rep range", isOn: Binding(get: { move.targetRepMinimum != nil }, set: { move.targetRepMinimum = $0 ? max(1, move.targetReps - 2) : nil }))
                        if move.targetRepMinimum != nil {
                            Stepper("Minimum: \(move.targetRepMinimum ?? move.targetReps) reps", value: Binding(get: { min(move.targetRepMinimum ?? move.targetReps, move.targetReps) }, set: { move.targetRepMinimum = $0 }), in: 1...move.targetReps)
                        }
                    }.font(.headline)
                }
                Surface {
                    VStack(alignment: .leading, spacing: 18) {
                        Toggle("Custom rest time", isOn: $customRest)
                            .onChange(of: customRest) { _, enabled in move.restSeconds = enabled ? (move.restSeconds ?? 90) : nil }
                        if customRest {
                            Stepper(value: Binding(get: { move.restSeconds ?? 90 }, set: { move.restSeconds = $0 }), in: 0...600, step: 15) {
                                Text((move.restSeconds ?? 0) == 0 ? "Timer off" : "\(move.restSeconds ?? 90) seconds")
                            }
                        } else {
                            Text("Uses the default timer from Settings.").font(.subheadline).foregroundStyle(SpotterStyle.secondaryText)
                        }
                    }
                }
                Text("These targets stay with this exercise when you repeat the workout.")
                    .font(.caption).foregroundStyle(SpotterStyle.secondaryText)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { if let minimum = move.targetRepMinimum { move.targetRepMinimum = min(minimum, move.targetReps) }; if onSave(move) { dismiss() } } }
            }
            .onAppear { customRest = move.restSeconds != nil }
        }
    }
}

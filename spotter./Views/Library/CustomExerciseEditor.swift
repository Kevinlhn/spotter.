import SwiftUI

struct CustomExerciseEditor: View {
    @EnvironmentObject private var store: TrainingStore
    @Environment(\.dismiss) private var dismiss
    let onSave: (TrainingMove) -> Void
    @State private var name = ""
    @State private var muscle = ""
    var body: some View {
        NavigationStack {
            Form {
                TextField("Exercise name", text: $name).accessibilityIdentifier("custom-exercise-name")
                TextField("Muscle group (optional)", text: $muscle)
            }.scrollContentBackground(.hidden).background { SpotterWallpaper() }
                .navigationTitle("New exercise").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let move = TrainingMove(name: name.trimmingCharacters(in: .whitespacesAndNewlines), muscle: muscle.isEmpty ? "Other" : muscle)
                            store.saveToLibrary(move)
                            if store.error == nil { onSave(move); dismiss() }
                        }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .alert("Couldn’t save", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                    Button("OK") { store.error = nil }
                } message: { Text(store.error ?? "") }
        }
    }
}

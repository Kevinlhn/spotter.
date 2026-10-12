import SwiftUI

struct CustomExerciseEditor: View {
    @EnvironmentObject private var store: TrainingStore
    @Environment(\.dismiss) private var dismiss
    var existing: ExerciseTemplateEntity? = nil
    let onSave: (TrainingMove) -> Void
    @State private var name = ""
    @State private var muscle = ""
    var body: some View {
        NavigationStack {
            Form {
                TextField("Exercise name", text: $name).accessibilityIdentifier("custom-exercise-name")
                TextField("Muscle group (optional)", text: $muscle)
                if existing != nil { Text("Renaming updates this library entry. Previous workouts keep their original exercise name and history.").font(.caption).foregroundStyle(SpotterStyle.secondaryText) }
            }.scrollContentBackground(.hidden).background { SpotterWallpaper() }
                .onAppear { if let existing { name = existing.name; muscle = existing.primaryMuscle ?? "Other" } }
                .navigationTitle(existing == nil ? "New exercise" : "Edit exercise").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let move = TrainingMove(name: name.trimmingCharacters(in: .whitespacesAndNewlines), muscle: muscle.isEmpty ? "Other" : muscle)
                            if let existing { store.updateLibraryExercise(existing, name: move.name, muscle: move.muscle) }
                            else { store.saveToLibrary(move) }
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

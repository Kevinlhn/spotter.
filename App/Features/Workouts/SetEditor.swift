import SwiftUI

struct SetEditor: View {
    @EnvironmentObject private var store: TrainingStore
    @Environment(\.dismiss) private var dismiss
    let set: WorkoutSetEntity
    @State private var weight = ""
    @State private var reps = ""
    private var validInput: Bool {
        guard let load = Double(weight.replacingOccurrences(of: ",", with: ".")), load.isFinite, load >= 0,
              let count = Int(reps), (1...999).contains(count) else { return false }
        return true
    }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Weight (\(set.exercise?.workout?.weightLabel ?? "load"))") {
                        TextField("Weight", text: $weight).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).accessibilityLabel("Edit set weight")
                    }
                    LabeledContent("Reps") {
                        TextField("Reps", text: $reps).keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing).accessibilityLabel("Edit set reps")
                    }
                }
            }.scrollContentBackground(.hidden).background { SpotterWallpaper() }
                .navigationTitle("Edit set").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            guard let load = Double(weight.replacingOccurrences(of: ",", with: ".")), let count = Int(reps) else { return }
                            if store.updateSet(set, weight: load, reps: count) { dismiss() }
                        }.disabled(!validInput)
                    }
                }
                .onAppear { weight = String(set.weight); reps = String(set.reps) }
                .alert("Couldn’t save", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                    Button("OK") { store.error = nil }
                } message: { Text(store.error ?? "") }
        }.presentationDetents([.medium, .large])
    }
}

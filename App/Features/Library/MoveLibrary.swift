import SwiftUI

struct MoveLibrary: View {
    @Environment(\.dismiss) private var dismiss
    var onSelect: ((TrainingMove) -> Void)?
    @State private var query = ""
    @State private var showCustom = false
    @State private var pendingSelection: TrainingMove?
    var body: some View {
        NavigationStack {
            FeaturePage {
                Button("Create exercise", systemImage: "plus") { showCustom = true }.frame(minHeight: 44)
            } content: {
                ExerciseBrowser(query: $query, onSelect: onSelect.map { callback in { move in callback(move); dismiss() } })
            }
            .navigationTitle("Exercise library").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $showCustom, onDismiss: {
                if let move = pendingSelection, let onSelect { pendingSelection = nil; onSelect(move); dismiss() }
            }) { CustomExerciseEditor { pendingSelection = $0 } }
        }
    }
}

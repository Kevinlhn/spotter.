import SwiftUI

struct MoveLibrary: View {
    @EnvironmentObject private var store: TrainingStore
    @Environment(\.dismiss) private var dismiss
    var onSelect: ((TrainingMove) -> Void)?
    @State private var query = ""
    @State private var showCustom = false
    @State private var pendingSelection: TrainingMove?
    @State private var guide: TrainingMove?

    private var moves: [TrainingMove] {
        var unique: [String: TrainingMove] = [:]
        for move in TrainingRoutine.starters.flatMap(\.moves) { unique[move.name.lowercased()] = move }
        for move in store.library { unique[move.name.lowercased()] = TrainingMove(id: move.id, name: move.name, muscle: move.primaryMuscle ?? "Other") }
        return unique.values.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) || $0.muscle.localizedCaseInsensitiveContains(query) }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            FeaturePage {
                HStack {
                    Text("\(moves.count) exercises").font(.subheadline).foregroundStyle(SpotterStyle.secondaryText)
                    Spacer()
                    Button { showCustom = true } label: { Label("Create exercise", systemImage: "plus").font(.subheadline.bold()).frame(minHeight: 44) }
                }
            } content: {
                List {
                    if moves.isEmpty {
                        Text("No matches. Try a muscle group or create your own exercise.").foregroundStyle(SpotterStyle.secondaryText)
                    }
                    ForEach(moves, id: \.name) { move in
                        Button {
                            if let onSelect { onSelect(move); dismiss() } else { guide = move }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(move.name).font(.headline).foregroundStyle(SpotterStyle.text)
                                    Text(move.muscle).font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                                }
                                Spacer()
                                Image(systemName: onSelect == nil ? "info.circle" : "plus.circle")
                                    .foregroundStyle(SpotterStyle.foregroundAccent)
                            }.padding(.vertical, 6).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                    }
                }.scrollContentBackground(.hidden).scrollDismissesKeyboard(.interactively)
                    .accessibilityIdentifier("exercise-library-list")
            }
            .sheet(item: $guide) { move in
                NavigationStack {
                    SpotterPage {
                        Text(move.name).font(.title2.bold())
                        Text(ExerciseGuidance.cue(for: move.name))
                    }.navigationTitle("Exercise guide").navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { guide = nil } } }
                }.presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showCustom, onDismiss: {
                if let move = pendingSelection, let onSelect { pendingSelection = nil; onSelect(move); dismiss() }
            }) { CustomExerciseEditor { pendingSelection = $0 } }
            .searchable(text: $query, prompt: "Exercise or muscle group")
            .navigationTitle("Exercise library").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

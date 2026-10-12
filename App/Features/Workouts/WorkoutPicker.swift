import SwiftUI

/// Shared selection flow for immediate training and assigning reusable content to a day.
struct WorkoutPicker: View {
    @EnvironmentObject private var store: TrainingStore
    @Environment(\.dismiss) private var dismiss
    let title: String
    var onSuggest: ((TrainingDraft) -> Void)? = nil
    let onSelect: (TrainingDraft) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { onSelect(TrainingDraft()) } label: { Label("Build your own", systemImage: "plus") }
                        .accessibilityIdentifier("choose-custom-workout")
                    Button("Suggest from my training", systemImage: "sparkles") { (onSuggest ?? onSelect)(store.coachedDraft()) }
                }
                if !store.templates.isEmpty {
                    Section("Saved workouts") {
                        ForEach(store.templates) { template in
                            Button { onSelect(TrainingDraft(template: template)) } label: {
                                Label(template.name, systemImage: "bookmark")
                            }
                        }
                    }
                }
                if let recent = store.completed.first {
                    Section("Repeat last session") {
                        Button { onSelect(TrainingDraft(workout: recent, repeatWorkout: true)) } label: {
                            Label(recent.name, systemImage: "arrow.clockwise")
                        }.accessibilityIdentifier("repeat-last-workout")
                    }
                }
                Section("Starter routines") {
                    ForEach(TrainingRoutine.starters) { routine in
                        Button { onSelect(TrainingDraft(routine: routine)) } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(routine.name).font(.headline)
                                Text("\(routine.equipment) · \(routine.moves.count) exercises").font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                            }.padding(.vertical, 5)
                        }.accessibilityIdentifier("choose-routine-\(routine.id)")
                    }
                }
            }.scrollContentBackground(.hidden).background { SpotterWallpaper() }
                .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}

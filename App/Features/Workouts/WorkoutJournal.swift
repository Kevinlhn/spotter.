import SwiftUI

struct WorkoutJournal: View {
    @EnvironmentObject private var store: TrainingStore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workout: WorkoutEntity
    var onRepeat: (() -> Void)?
    @State private var confirmDelete = false
    @State private var savedToPlan = false
    @State private var notice: String?
    @State private var noticeTitle = ""

    var body: some View {
        NavigationStack {
            FeaturePage {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.date.formatted(.dateTime.month(.wide).day().year()))
                        .font(.subheadline.weight(.semibold))
                    Text("\(workout.sortedExercises.count) exercises · \(workout.sortedExercises.reduce(0) { $0 + $1.sortedSets.count }) logged sets")
                        .font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                    if let planned = workout.scheduledDate, !Calendar.current.isDate(planned, inSameDayAs: workout.date) {
                        Text("Originally planned for \(planned.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                    }
                }
            } content: {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        if let notes = workout.notes, !notes.isEmpty { Text(notes).font(.subheadline).foregroundStyle(SpotterStyle.secondaryText) }
                        ForEach(workout.sortedExercises, id: \.objectID) { exercise in
                            JournalExerciseCard(exercise: exercise)
                        }
                    }.padding(.horizontal, 20).padding(.bottom, 16)
                }.accessibilityIdentifier("journal-exercises")
            }
            .navigationTitle(workout.name).navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                if let onRepeat {
                    PrimaryAction(title: "Do this workout again", icon: "arrow.clockwise", action: onRepeat)
                        .padding(.horizontal, 20).padding(.vertical, 8)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button(savedToPlan ? "Saved to Plan" : "Save as reusable workout", systemImage: savedToPlan ? "checkmark" : "bookmark") {
                            saveToPlan()
                        }.disabled(savedToPlan)
                        Button("Delete workout", role: .destructive) { confirmDelete = true }
                    } label: { Image(systemName: "ellipsis.circle") }
                        .accessibilityLabel("Workout actions")
                }
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .confirmationDialog("Delete this workout and its sets?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete workout", role: .destructive) {
                    if store.delete(workout) { dismiss() }
                    else { showFailure() }
                }
            }
            .alert(noticeTitle, isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
                Button("OK") { notice = nil }
            } message: { Text(notice ?? "") }
        }
    }

    private func saveToPlan() {
        guard store.saveTemplate(TrainingDraft(workout: workout, repeatWorkout: true)) != nil else {
            showFailure()
            return
        }
        savedToPlan = true
        noticeTitle = "Saved to Plan"
        notice = "Your exercises, targets, and rest settings are ready to reuse. Logged sets remain in this session."
    }

    private func showFailure() {
        noticeTitle = "Couldn’t complete that"
        notice = store.error ?? "Please try again."
        store.error = nil
    }
}

private struct JournalExerciseCard: View {
    @ObservedObject var exercise: ExerciseEntity
    var body: some View {
        Surface {
            VStack(alignment: .leading, spacing: 14) {
                Text(exercise.name).font(.headline)
                if exercise.sortedSets.isEmpty {
                    Text("No sets logged").font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                }
                ForEach(Array(exercise.sortedSets.enumerated()), id: \.element.objectID) { index, set in
                    HStack {
                        Text("Set \(index + 1)").foregroundStyle(SpotterStyle.secondaryText)
                        Spacer()
                        Text("\(set.weight.formatted()) \(exercise.workout?.weightLabel ?? "load") × \(set.reps) reps").monospacedDigit()
                    }.font(.subheadline)
                }
            }
        }
    }
}

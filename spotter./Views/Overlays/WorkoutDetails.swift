//
//  WorkoutDetails.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 11/8/25.
//


//
//  WorkoutDetails.swift
//  spotter
//
//  Created by Kevin Hernandez-Nino on 11/08/25.
//

import SwiftUI
import CoreData


struct WorkoutDetails: View {
    let workout: WorkoutEntity
    var onDismiss: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var context

    @State private var showAddExercise = false
    @State private var newExerciseName: String = ""

    var body: some View {
        ZStack {

            VStack(spacing: 20) {
                // MARK: - Header
                Text(workout.name.isEmpty ? "Workout" : workout.name)
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(AppColors.bluePrimary)

                // MARK: - Card Container
                VStack(spacing: 20) {
                    headerSection
                    Divider().padding(.vertical, 4)
                    exercisesSection
                    Divider().padding(.vertical, 4)
                    notesSection
                    Divider().padding(.vertical, 4)
                    footerButtons
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 30)
                .background(.ultraThinMaterial)
                .cornerRadius(40)
                .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
                .frame(maxWidth: 500)
                .transition(.scale.combined(with: .opacity))
            }
            .padding()

            // MARK: - Add Exercise Overlay
            if showAddExercise {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.spring()) { showAddExercise = false } }

                VStack(spacing: 15) {
                    Text("Add Exercise")
                        .font(.headline)
                        .foregroundStyle(AppColors.bluePrimary)

                    TextField("Exercise Name", text: $newExerciseName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)

                    HStack(spacing: 12) {
                        Button("Cancel") {
                            withAnimation(.spring()) { showAddExercise = false }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary.opacity(0.1))
                        .cornerRadius(12)

                        Button("Add") {
                            addExercise()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.bluePrimary)
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .disabled(newExerciseName.isEmpty)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(30)
                .shadow(radius: 10)
                .frame(maxWidth: 400)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - Header Stats
    private var headerSection: some View {
        VStack(spacing: 6) {
            Text(workout.date.formatted(.dateTime.month().day().year()))
                .font(.caption)
                .foregroundStyle(.secondary)

            if let exercises = workout.exercises as? Set<ExerciseEntity> {
                Text("\(exercises.count) Exercises")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Exercises Section
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Exercises")
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation(.spring()) { showAddExercise = true }
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .tint(AppColors.bluePrimary)
                }
            }

            if let exercises = workout.exercises as? Set<ExerciseEntity>, !exercises.isEmpty {
                ForEach(exercises.sorted(by: { $0.name < $1.name }), id: \.id) { exercise in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.name)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.bluePrimary)

                        if let sets = exercise.sets as? Set<WorkoutSetEntity>, !sets.isEmpty {
                            ForEach(sets.sorted(by: { $0.timestamp ?? Date() < $1.timestamp ?? Date() }), id: \.id) { set in
                                HStack {
                                    Text("\(Int(set.reps)) reps × \(Int(set.weight)) lbs")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(6)
                                .background(.thinMaterial)
                                .cornerRadius(8)
                            }
                        } else {
                            Text("No sets yet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .shadow(radius: 2, y: 1)
                }
            } else {
                Text("No exercises added yet.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Notes
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
            if let notes = workout.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("No notes for this workout.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Buttons
    private var footerButtons: some View {
        HStack(spacing: 12) {
            Button("Close") {
                withAnimation(.spring()) { onDismiss() }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.primary.opacity(0.1))
            .cornerRadius(12)
            .foregroundColor(.primary)
        }
    }

    // MARK: - Add Exercise Logic
    private func addExercise() {
        let exercise = ExerciseEntity(context: context)
        exercise.id = UUID()
        exercise.name = newExerciseName
        exercise.createdAt = Date()
        exercise.isCustom = true
        workout.addToExercises(exercise)

        do {
            try context.save()
        } catch {
            print("❌ Error saving exercise:", error.localizedDescription)
        }

        newExerciseName = ""
        withAnimation(.spring()) { showAddExercise = false }
    }
}

#Preview {
    let ctx = Persistence.preview.container.viewContext
    let req: NSFetchRequest<WorkoutEntity> = WorkoutEntity.fetchRequest()
    let workout = (try? ctx.fetch(req))?.first ?? {
        let w = WorkoutEntity(context: ctx)
        w.id = UUID()
        w.name = "Push Day"
        w.date = Date()
        w.notes = "Chest and triceps session"
        return w
    }()

    return ZStack {
        SpotterBackground()
        WorkoutDetails(workout: workout, onDismiss: {})
            .environment(\.managedObjectContext, ctx)
    }
    .preferredColorScheme(.dark)
}

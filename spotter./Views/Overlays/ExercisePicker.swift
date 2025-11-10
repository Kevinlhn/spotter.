//
//  ExercisePicker.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 11/9/25.
//


import SwiftUI
import CoreData

struct ExercisePickerSheet: View {
    let workout: WorkoutEntity
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ExerciseEntity.createdAt, ascending: false)]
    ) private var allExercises: FetchedResults<ExerciseEntity>

    @State private var searchText: String = ""
    @State private var newExerciseName: String = ""

    var filteredExercises: [ExerciseEntity] {
        if searchText.isEmpty {
            return Array(allExercises)
        } else {
            return allExercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // MARK: - Search Field
                TextField("Search exercises...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                // MARK: - List of Exercises
                List {
                    if filteredExercises.isEmpty {
                        Text("No exercises found.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(filteredExercises, id: \.id) { exercise in
                            Button {
                                addExistingExercise(exercise)
                            } label: {
                                HStack {
                                    Text(exercise.name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if (workout.exercises as? Set<ExerciseEntity>)?.contains(exercise) == true {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppColors.bluePrimary)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.inset)

                // MARK: - Create New
                VStack(spacing: 8) {
                    TextField("New Exercise Name", text: $newExerciseName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)

                    Button {
                        createNewExercise()
                    } label: {
                        Label("Create Exercise", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.bluePrimary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    .disabled(newExerciseName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.bottom)
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Logic
    private func addExistingExercise(_ exercise: ExerciseEntity) {
        workout.addToExercises(exercise)
        try? context.save()
        dismiss()
    }

    private func createNewExercise() {
        let newExercise = ExerciseEntity(context: context)
        newExercise.id = UUID()
        newExercise.name = newExerciseName.trimmingCharacters(in: .whitespaces)
        newExercise.createdAt = Date()
        newExercise.isCustom = true
        workout.addToExercises(newExercise)
        try? context.save()
        dismiss()
    }
}

#Preview {
    let ctx = Persistence.preview.container.viewContext
    let workout = WorkoutEntity(context: ctx)
    workout.name = "Pull Day"
    workout.date = Date()
    return ExercisePickerSheet(workout: workout)
        .environment(\.managedObjectContext, ctx)
}

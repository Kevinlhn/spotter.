//
//  ExerciseDataManager.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 11/8/25.
//

import Foundation
import CoreData
import Combine

/// Handles all CRUD operations for exercises and sets.
final class ExerciseDataManager: ObservableObject {
    // MARK: - Properties
    static let shared = ExerciseDataManager()
    private let context: NSManagedObjectContext

    // Published arrays for SwiftUI auto-updates
    @Published private(set) var exercises: [ExerciseEntity] = []

    private init(context: NSManagedObjectContext = Persistence.shared.container.viewContext) {
        self.context = context
    }

    // MARK: - Fetch
    /// Fetch all exercises for a specific workout.
    func fetchExercises(for workout: WorkoutEntity) {
        let request: NSFetchRequest<ExerciseEntity> = ExerciseEntity.fetchRequest()
        request.predicate = NSPredicate(format: "workout == %@", workout)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExerciseEntity.createdAt, ascending: true)]

        do {
            exercises = try context.fetch(request)
        } catch {
            print("❌ Failed to fetch exercises: \(error.localizedDescription)")
        }
    }

    // MARK: - Create
    /// Add a new exercise to a given workout.
    func addExercise(to workout: WorkoutEntity,
                     name: String,
                     muscleGroup: String? = nil,
                     isCustom: Bool = true) -> ExerciseEntity {
        let exercise = ExerciseEntity(context: context)
        exercise.id = UUID()
        exercise.name = name
        exercise.muscleGroup = muscleGroup
        exercise.isCustom = isCustom
        exercise.createdAt = Date()
        exercise.workout = workout

        workout.addToExercises(exercise)
        save()
        fetchExercises(for: workout)
        return exercise
    }

    /// Add a new set to a specific exercise.
    func addSet(to exercise: ExerciseEntity,
                weight: Double,
                reps: Int16) -> WorkoutSetEntity {
        let set = WorkoutSetEntity(context: context)
        set.id = UUID()
        set.weight = weight
        set.reps = reps
        set.timestamp = Date()
        set.exercise = exercise

        exercise.addToSets(set)
        save()
        fetchExercises(for: exercise.workout!)
        return set
    }

    // MARK: - Update
    /// Update an existing exercise name or muscle group.
    func updateExercise(_ exercise: ExerciseEntity,
                        name: String? = nil,
                        muscleGroup: String? = nil) {
        if let name = name { exercise.name = name }
        if let muscleGroup = muscleGroup { exercise.muscleGroup = muscleGroup }
        save()
        if let workout = exercise.workout {
            fetchExercises(for: workout)
        }
    }

    /// Update a specific set (weight/reps).
    func updateSet(_ set: WorkoutSetEntity,
                   weight: Double? = nil,
                   reps: Int16? = nil) {
        if let weight = weight { set.weight = weight }
        if let reps = reps { set.reps = reps }
        save()
        if let exercise = set.exercise, let workout = exercise.workout {
            fetchExercises(for: workout)
        }
    }

    // MARK: - Delete
    func deleteExercise(_ exercise: ExerciseEntity) {
        guard let workout = exercise.workout else { return }
        context.delete(exercise)
        save()
        fetchExercises(for: workout)
    }

    func deleteSet(_ set: WorkoutSetEntity) {
        guard let exercise = set.exercise,
              let workout = exercise.workout else { return }
        context.delete(set)
        save()
        fetchExercises(for: workout)
    }

    // MARK: - Save
    private func save() {
        do {
            try context.save()
        } catch {
            print("❌ Core Data save error: \(error.localizedDescription)")
        }
    }
}

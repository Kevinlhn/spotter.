//
//  WorkoutDataManager.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 11/8/25.
//

import Foundation
import CoreData
import Combine

/// Handles CRUD operations for workouts, exercises, and sets.
final class WorkoutDataManager: ObservableObject {
    // MARK: - Properties
    static let shared = WorkoutDataManager()
    private let context: NSManagedObjectContext

    // Published array for SwiftUI auto-updates
    @Published private(set) var workouts: [WorkoutEntity] = []

    // Private initializer (Singleton)
    private init(context: NSManagedObjectContext = Persistence.shared.container.viewContext) {
        self.context = context
        fetchWorkouts()
    }

    // MARK: - Fetch
    func fetchWorkouts() {
        let request: NSFetchRequest<WorkoutEntity> = WorkoutEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutEntity.date, ascending: false)]

        do {
            workouts = try context.fetch(request)
        } catch {
            print("❌ Failed to fetch workouts: \(error.localizedDescription)")
        }
    }

    // MARK: - Create
    func createWorkout(name: String, notes: String? = nil, date: Date = Date()) -> WorkoutEntity {
        let newWorkout = WorkoutEntity(context: context)
        newWorkout.id = UUID()
        newWorkout.name = name
        newWorkout.date = date
        newWorkout.notes = notes

        save()
        fetchWorkouts()
        return newWorkout
    }

    func addExercise(to workout: WorkoutEntity, name: String, muscleGroup: String? = nil) -> ExerciseEntity {
        let exercise = ExerciseEntity(context: context)
        exercise.id = UUID()
        exercise.name = name
        exercise.muscleGroup = muscleGroup
        exercise.isCustom = true
        exercise.createdAt = Date()

        workout.addToExercises(exercise)
        save()
        return exercise
    }

    func addSet(to exercise: ExerciseEntity, weight: Double, reps: Int16) -> WorkoutSetEntity {
        let set = WorkoutSetEntity(context: context)
        set.id = UUID()
        set.weight = weight
        set.reps = reps
        set.timestamp = Date()

        exercise.addToSets(set)
        save()
        return set
    }

    // MARK: - Delete
    func deleteWorkout(_ workout: WorkoutEntity) {
        context.delete(workout)
        save()
        fetchWorkouts()
    }

    // MARK: - Save
    private func save() {
        do {
            try context.save()
        } catch {
            print("❌ Failed to save context: \(error.localizedDescription)")
        }
    }
}

//
//  ExerciseViewModel.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 11/8/25.
//


import Foundation
import CoreData
import Combine

@MainActor
final class ExerciseViewModel: ObservableObject {
    @Published var exercises: [ExerciseEntity] = []
    private let manager = ExerciseDataManager.shared

    // The current parent workout this view is tied to
    private var currentWorkout: WorkoutEntity?

    // MARK: - Load Exercises
    func load(for workout: WorkoutEntity) {
        currentWorkout = workout
        manager.fetchExercises(for: workout)
        exercises = manager.exercises
    }

    // MARK: - Add Exercise / Set
    func addExercise(name: String, muscleGroup: String? = nil) {
        guard let workout = currentWorkout else { return }
        _ = manager.addExercise(to: workout, name: name, muscleGroup: muscleGroup)
        load(for: workout)
    }

    func addSet(to exercise: ExerciseEntity, weight: Double, reps: Int16) {
        _ = manager.addSet(to: exercise, weight: weight, reps: reps)
        if let workout = exercise.workout {
            load(for: workout)
        }
    }

    // MARK: - Update
    func renameExercise(_ exercise: ExerciseEntity, to newName: String) {
        manager.updateExercise(exercise, name: newName)
        if let workout = exercise.workout {
            load(for: workout)
        }
    }

    // MARK: - Delete
    func deleteExercise(_ exercise: ExerciseEntity) {
        manager.deleteExercise(exercise)
        if let workout = exercise.workout {
            load(for: workout)
        }
    }

    func deleteSet(_ set: WorkoutSetEntity) {
        manager.deleteSet(set)
        if let workout = set.exercise?.workout {
            load(for: workout)
        }
    }
}


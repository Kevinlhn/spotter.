//
//  WorkoutViewModel.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 11/8/25.
//

import Foundation
import CoreData
import Combine

@MainActor
final class WorkoutViewModel: ObservableObject {
    @Published var workouts: [WorkoutEntity] = []
    @Published var currentWorkout: WorkoutEntity?

    private let manager = WorkoutDataManager.shared

    init() {
        loadWorkouts()
    }

    // MARK: - Fetch
    func loadWorkouts() {
        manager.fetchWorkouts()
        workouts = manager.workouts
    }

    // MARK: - Create
    func createWorkout(name: String, notes: String? = nil) {
        currentWorkout = manager.createWorkout(name: name, notes: notes)
        loadWorkouts()
    }

    // MARK: - Delete
    func deleteWorkout(_ workout: WorkoutEntity) {
        manager.deleteWorkout(workout)
        loadWorkouts()
    }

    // MARK: - Helpers
    func selectWorkout(_ workout: WorkoutEntity) {
        currentWorkout = workout
    }
}

//
//  HistoryViewModel.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 11/8/25.
//

import Foundation
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var workouts: [WorkoutEntity] = []

    private let manager = WorkoutDataManager.shared

    func loadHistory() {
        manager.fetchWorkouts()
        workouts = manager.workouts
    }
}

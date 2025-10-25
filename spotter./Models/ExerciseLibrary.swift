//
//  ExerciseLibrary.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/3/25.
//
import Foundation
import Combine

class ExerciseLibrary: ObservableObject {
    @Published var all: [Exercise] = []
    
    private let saveKey = "exercise_library"

    init() {
        load()
    }

    func add(_ exercise: Exercise) {
        all.append(exercise)
        save()
    }

    func remove(_ exercise: Exercise) {
        all.removeAll { $0.id == exercise.id }
        save()
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Exercise].self, from: data) {
            all = decoded
        } else {
            // Preload with defaults if empty
            all = [
                Exercise(
                    name: "Bench Press",
                    category: .push,
                    primaryMuscles: [.chestMiddle],
                    secondaryMuscles: [.tricepsLong, .shouldersFront],
                    equipment: ["Barbell"],
                    caloriesPerMinute: 6.0
                ),
                Exercise(
                    name: "Squat",
                    category: .legs,
                    primaryMuscles: [.quads, .glutes],
                    secondaryMuscles: [.hamstrings],
                    equipment: ["Barbell"],
                    caloriesPerMinute: 8.0
                )
            ]
        }
    }
}


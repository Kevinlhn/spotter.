//
//  Exercise.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 9/26/25.
//
import Foundation

struct Exercise: Identifiable, Codable {
    let id: UUID
    var name: String
    var category: ExerciseCategory
    var primaryMuscles: [MuscleGroup]
    var secondaryMuscles: [MuscleGroup]
    var equipment: [String] // e.g. "Dumbbell", "Barbell"
    var caloriesPerMinute: Double

    init(
        id: UUID = UUID(),
        name: String,
        category: ExerciseCategory,
        primaryMuscles: [MuscleGroup],
        secondaryMuscles: [MuscleGroup],
        equipment: [String],
        caloriesPerMinute: Double
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.equipment = equipment
        self.caloriesPerMinute = caloriesPerMinute
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, category, primaryMuscles, secondaryMuscles, equipment, caloriesPerMinute
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.category = try container.decode(ExerciseCategory.self, forKey: .category)
        self.primaryMuscles = try container.decode([MuscleGroup].self, forKey: .primaryMuscles)
        self.secondaryMuscles = try container.decode([MuscleGroup].self, forKey: .secondaryMuscles)
        self.equipment = try container.decode([String].self, forKey: .equipment)
        self.caloriesPerMinute = try container.decode(Double.self, forKey: .caloriesPerMinute)
    }
}

enum ExerciseCategory: String, Codable, CaseIterable {
    case push
    case pull
    case legs
    case core
    case cardio
}

//
//  ExerciseTemplateDataManager.swift
//  spotter.
//
//  Manages the exercise library in Core Data.
//

import Foundation
import CoreData

final class ExerciseTemplateDataManager {
    static let shared = ExerciseTemplateDataManager()

    private let context: NSManagedObjectContext

    private init(context: NSManagedObjectContext = Persistence.shared.container.viewContext) {
        self.context = context
    }

    // MARK: - Fetch

    func fetchAllTemplates() -> [ExerciseTemplateEntity] {
        let request: NSFetchRequest<ExerciseTemplateEntity> = ExerciseTemplateEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: #keyPath(ExerciseTemplateEntity.primaryMuscle), ascending: true),
            NSSortDescriptor(key: #keyPath(ExerciseTemplateEntity.name), ascending: true)
        ]

        do {
            return try context.fetch(request)
        } catch {
            print("❌ Error fetching exercise templates: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Create

    @discardableResult
    func createTemplate(
        name: String,
        primaryMuscle: String?,
        isCustom: Bool
    ) -> ExerciseTemplateEntity {
        let template = ExerciseTemplateEntity(context: context)
        template.id = UUID()
        template.name = name
        template.primaryMuscle = primaryMuscle
        template.isCustom = isCustom
        template.isFavorite = false
        template.createdAt = Date()

        saveContext()
        return template
    }

    // MARK: - Delete

    func deleteTemplate(_ template: ExerciseTemplateEntity) {
        context.delete(template)
        saveContext()
    }

    // MARK: - Seed defaults

    func seedDefaultsIfNeeded() {
        let existing = fetchAllTemplates()
        guard existing.isEmpty else { return }

        let defaults: [(String, String)] = [
            ("Barbell Bench Press", "Chest"),
            ("Incline Dumbbell Press", "Chest"),
            ("Push-Up", "Chest"),
            ("Barbell Squat", "Quads"),
            ("Leg Press", "Quads"),
            ("Romanian Deadlift", "Hamstrings"),
            ("Conventional Deadlift", "Posterior Chain"),
            ("Lat Pulldown", "Back"),
            ("Pull-Up", "Back"),
            ("Seated Cable Row", "Back"),
            ("Overhead Press", "Shoulders"),
            ("Lateral Raise", "Shoulders"),
            ("Barbell Curl", "Biceps"),
            ("Hammer Curl", "Biceps"),
            ("Triceps Pushdown", "Triceps"),
            ("Skullcrusher", "Triceps"),
            ("Hip Thrust", "Glutes"),
            ("Cable Fly", "Chest"),
            ("Face Pull", "Rear Delts"),
            ("Plank", "Core")
        ]

        for (name, muscle) in defaults {
            _ = createTemplate(name: name, primaryMuscle: muscle, isCustom: false)
        }
    }

    // MARK: - Save

    private func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("❌ Error saving exercise templates: \(error.localizedDescription)")
        }
    }
}
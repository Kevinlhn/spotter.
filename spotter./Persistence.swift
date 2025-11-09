//
//  Persistence.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 9/25/25.
//
//
import Foundation
import CoreData

/// Handles all Core Data setup and persistence for Spotter.
struct Persistence {
    static let shared = Persistence()
    static var preview: Persistence = {
        let controller = Persistence(inMemory: true)
        let viewContext = controller.container.viewContext

        // Example preview data
        let workout = WorkoutEntity(context: viewContext)
        workout.id = UUID()
        workout.name = "Sample Push Day"
        workout.date = Date()

        let exercise = ExerciseEntity(context: viewContext)
        exercise.id = UUID()
        exercise.name = "Bench Press"
        exercise.isCustom = true
        exercise.createdAt = Date()

        let set1 = WorkoutSetEntity(context: viewContext)
        set1.id = UUID()
        set1.reps = 8
        set1.weight = 135
        set1.timestamp = Date()

        let set2 = WorkoutSetEntity(context: viewContext)
        set2.id = UUID()
        set2.reps = 6
        set2.weight = 145
        set2.timestamp = Date()

        exercise.addToSets([set1, set2])
        workout.addToExercises(exercise)

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Preview save error: \(nsError), \(nsError.userInfo)")
        }

        return controller
    }()

    // MARK: - Core Data Container
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "spotter_") // ✅ Match model name

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.undoManager = nil // optional performance boost

        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }

    // MARK: - Save Helpers
    func save(context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    func saveBackgroundContext(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask { context in
            block(context)
            save(context: context)
        }
    }
}

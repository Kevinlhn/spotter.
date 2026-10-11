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
    private static let model: NSManagedObjectModel = {
        let url = Bundle(for: WorkoutEntity.self).url(forResource: "spotter_", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: url)!
    }()
    static let shared = Persistence(inMemory: ProcessInfo.processInfo.arguments.contains("UI_TESTING"))
    static var preview: Persistence = {
        let controller = Persistence(inMemory: true)
        let viewContext = controller.container.viewContext

        // Example preview data
        let workout = WorkoutEntity.insert(in: viewContext)
        workout.id = UUID()
        workout.name = "Sample Push Day"
        workout.date = Date()
        workout.status = WorkoutStatus.active.rawValue

        let exercise = ExerciseEntity.insert(in: viewContext)
        exercise.id = UUID()
        exercise.name = "Bench Press"
        exercise.isCustom = true
        exercise.createdAt = Date()

        let set1 = WorkoutSetEntity.insert(in: viewContext)
        set1.id = UUID()
        set1.reps = 8
        set1.weight = 135
        set1.timestamp = Date()

        let set2 = WorkoutSetEntity.insert(in: viewContext)
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

    private init(container: NSPersistentContainer) { self.container = container }

    /// Open/migrate the real store while the launch identity is visible. No branding delay.
    static func load(inMemory: Bool = false) async throws -> Persistence {
        let container = NSPersistentContainer(name: "spotter_", managedObjectModel: Self.model)
        for description in container.persistentStoreDescriptions {
            if inMemory { description.url = URL(fileURLWithPath: "/dev/null") }
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            description.shouldAddStoreAsynchronously = true
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            container.loadPersistentStores { _, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.undoManager = nil
        return Persistence(container: container)
    }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "spotter_", managedObjectModel: Self.model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.persistentStoreDescriptions.forEach {
            $0.shouldMigrateStoreAutomatically = true
            $0.shouldInferMappingModelAutomatically = true
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

/// Resolve entities against this context's model, including during migration tests.
extension NSManagedObject {
    static func insert(in context: NSManagedObjectContext) -> Self {
        NSEntityDescription.insertNewObject(forEntityName: String(describing: self), into: context) as! Self
    }
}

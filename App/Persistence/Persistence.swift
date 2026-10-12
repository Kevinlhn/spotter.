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
    // MARK: - Core Data Container
    let container: NSPersistentContainer

    private init(container: NSPersistentContainer) { self.container = container }

    /// Open/migrate the real store while the launch identity is visible. No branding delay.
    static func load(inMemory: Bool = false) async throws -> Persistence {
        let container = makeContainer(inMemory: inMemory, asynchronous: true)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            container.loadPersistentStores { _, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
        configureViewContext(container.viewContext)
        return Persistence(container: container)
    }

    init(inMemory: Bool = false) {
        container = Self.makeContainer(inMemory: inMemory, asynchronous: false)
        Self.configureViewContext(container.viewContext)

        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }

    private static func makeContainer(inMemory: Bool, asynchronous: Bool) -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "spotter_", managedObjectModel: model)
        for description in container.persistentStoreDescriptions {
            if inMemory { description.url = URL(fileURLWithPath: "/dev/null") }
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            description.shouldAddStoreAsynchronously = asynchronous
        }
        return container
    }

    private static func configureViewContext(_ context: NSManagedObjectContext) {
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.undoManager = nil
    }

}

/// Resolve entities against this context's model, including during migration tests.
extension NSManagedObject {
    static func insert(in context: NSManagedObjectContext) -> Self {
        NSEntityDescription.insertNewObject(forEntityName: String(describing: self), into: context) as! Self
    }
}

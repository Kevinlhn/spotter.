//
//  CoreDataStack.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/29/25.
//

import Foundation
import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()
    let container: NSPersistentContainer
    
    private init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SpotterFitness_DataModel_v0_1")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    var context: NSManagedObjectContext { container.viewContext }
}

extension NSManagedObjectContext {
    func saveIfNeeded() {
        if hasChanges {
            do { try save() }
            catch { print("Core Data save error: \\(error)") }
        }
    }
}

extension UserEntity {
    static func fetchAll(in context: NSManagedObjectContext) -> [UserEntity] {
        (try? context.fetch(fetchRequest())) ?? []
    }
}

extension WorkoutEntity {
    static func fetchByDate(_ date: Date, in context: NSManagedObjectContext) -> [WorkoutEntity] {
        let req = fetchRequest()
        req.predicate = NSPredicate(format: "date == %@", date as NSDate)
        return (try? context.fetch(req)) ?? []
    }
}

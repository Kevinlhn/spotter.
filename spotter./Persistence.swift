//
//  Persistence.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 9/25/25.
//
//
//  PersistenceController.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/29/25.
//

import Foundation
import CoreData

/// Handles Core Data stack initialization and preview context
struct PersistenceController {
    static let shared = PersistenceController()

    // MARK: - Persistent Container
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "spotter_")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved Core Data error: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Preview Support
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        // Create mock user for previews
        let mockUser = UserEntity(context: viewContext)
        mockUser.id = UUID()
        mockUser.name = "Kevin Hernandez-Niño"
        mockUser.email = "kevin@spotter.app"
        mockUser.trainingMode = "hypertrophy"
        mockUser.experienceLevel = "intermediate"
        mockUser.streakDays = 24
        mockUser.createdAt = Date()
        mockUser.updatedAt = Date()

        do {
            try viewContext.save()
        } catch {
            fatalError("Unresolved error saving preview data: \(error)")
        }

        return controller
    }()
}

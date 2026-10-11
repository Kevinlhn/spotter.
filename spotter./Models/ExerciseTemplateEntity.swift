//
//  ExerciseTemplateEntity.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 12/1/25.
//


//
//  ExerciseTemplateEntity.swift
//  spotter.
//
//  Core Data entity representing an exercise in the user's library.
//

import Foundation
import CoreData

@objc(ExerciseTemplateEntity)
public class ExerciseTemplateEntity: NSManagedObject {

}

extension ExerciseTemplateEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExerciseTemplateEntity> {
        NSFetchRequest<ExerciseTemplateEntity>(entityName: "ExerciseTemplateEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var primaryMuscle: String?
    @NSManaged public var isCustom: Bool
    @NSManaged public var isFavorite: Bool
    @NSManaged public var createdAt: Date
}

extension ExerciseTemplateEntity : Identifiable { }
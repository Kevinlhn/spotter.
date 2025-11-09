//
//  ExerciseEntity.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/29/25.
//


import Foundation
import CoreData

@objc(ExerciseEntity)
public class ExerciseEntity: NSManagedObject {}

extension ExerciseEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExerciseEntity> {
        NSFetchRequest<ExerciseEntity>(entityName: "ExerciseEntity")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var category: String
    @NSManaged public var modality: String
    @NSManaged public var primaryMuscles: Data?
    @NSManaged public var secondaryMuscles: Data?
    @NSManaged public var equipmentNeeded: Data?
    @NSManaged public var difficulty: String
    @NSManaged public var videoURL: String?
    @NSManaged public var coachingCues: Data?
    @NSManaged public var isPublic: Bool
    @NSManaged public var createdAt: Date
}
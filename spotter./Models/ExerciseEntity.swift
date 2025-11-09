//
//  ExerciseEntity.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 11/8/25.
//


import Foundation
import CoreData

@objc(ExerciseEntity)
public class ExerciseEntity: NSManagedObject {}

extension ExerciseEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExerciseEntity> {
        return NSFetchRequest<ExerciseEntity>(entityName: "ExerciseEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var muscleGroup: String?
    @NSManaged public var isCustom: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var workout: WorkoutEntity?
    @NSManaged public var sets: NSSet?

    // MARK: - Computed helpers
    var sortedSets: [WorkoutSetEntity] {
        let set = sets as? Set<WorkoutSetEntity> ?? []
        return set.sorted(by: { $0.timestamp ?? Date() < $1.timestamp ?? Date() })
    }
}

// MARK: Generated accessors for sets
extension ExerciseEntity {
    @objc(addSetsObject:)
    @NSManaged public func addToSets(_ value: WorkoutSetEntity)

    @objc(removeSetsObject:)
    @NSManaged public func removeFromSets(_ value: WorkoutSetEntity)

    @objc(addSets:)
    @NSManaged public func addToSets(_ values: NSSet)

    @objc(removeSets:)
    @NSManaged public func removeFromSets(_ values: NSSet)
}

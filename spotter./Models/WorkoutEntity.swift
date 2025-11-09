//
//  WorkoutEntity.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 11/8/25.
//


import Foundation
import CoreData

@objc(WorkoutEntity)
public class WorkoutEntity: NSManagedObject {}

extension WorkoutEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutEntity> {
        return NSFetchRequest<WorkoutEntity>(entityName: "WorkoutEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var date: Date
    @NSManaged public var notes: String?
    @NSManaged public var exercises: NSSet?

    // MARK: - Computed helpers
    var sortedExercises: [ExerciseEntity] {
        let set = exercises as? Set<ExerciseEntity> ?? []
        return set.sorted(by: { $0.createdAt ?? Date() < $1.createdAt ?? Date() })
    }
}

// MARK: Generated accessors for exercises
extension WorkoutEntity {
    @objc(addExercisesObject:)
    @NSManaged public func addToExercises(_ value: ExerciseEntity)

    @objc(removeExercisesObject:)
    @NSManaged public func removeFromExercises(_ value: ExerciseEntity)

    @objc(addExercises:)
    @NSManaged public func addToExercises(_ values: NSSet)

    @objc(removeExercises:)
    @NSManaged public func removeFromExercises(_ values: NSSet)
}

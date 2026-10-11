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
    @NSManaged public var targetWeight: NSNumber?
    @NSManaged public var targetRepMinimum: Int16
    @NSManaged public var targetSets: Int16
    @NSManaged public var targetReps: Int16
    /// -1 follows the global preference; zero means no rest timer.
    @NSManaged public var restSeconds: Int16
    @NSManaged public var workout: WorkoutEntity?
    @NSManaged public var sets: NSSet?

    // MARK: - Computed helpers
    var repRange: ClosedRange<Int> { (targetRepMinimum > 0 ? min(Int(targetRepMinimum), plannedReps) : plannedReps)...plannedReps }
    var plannedSets: Int { (1...20).contains(Int(targetSets)) ? Int(targetSets) : 3 }
    var plannedReps: Int { (1...999).contains(Int(targetReps)) ? Int(targetReps) : 8 }
    var restOverrideSeconds: Int? { (0...600).contains(Int(restSeconds)) ? Int(restSeconds) : nil }

    var sortedSets: [WorkoutSetEntity] {
        let set = sets as? Set<WorkoutSetEntity> ?? []
        return set.sorted {
            let left = $0.timestamp ?? .distantPast
            let right = $1.timestamp ?? .distantPast
            if left != right { return left < right }
            return $0.objectID.uriRepresentation().absoluteString < $1.objectID.uriRepresentation().absoluteString
        }
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

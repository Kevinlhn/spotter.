//
//  WorkoutSetEntity.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/29/25.
//


import Foundation
import CoreData

@objc(WorkoutSetEntity)
public class WorkoutSetEntity: NSManagedObject {}

extension WorkoutSetEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutSetEntity> {
        NSFetchRequest<WorkoutSetEntity>(entityName: "WorkoutSetEntity")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var setNumber: Int16
    @NSManaged public var reps: Int16
    @NSManaged public var weightKG: Double
    @NSManaged public var distanceM: Int32
    @NSManaged public var durationSec: Int32
    @NSManaged public var velocityMPS: Double
    @NSManaged public var rir: Double
    @NSManaged public var rpe: Double
    @NSManaged public var isWarmup: Bool
    @NSManaged public var isSuperset: Bool
    @NSManaged public var completed: Bool
    @NSManaged public var createdAt: Date
    
    @NSManaged public var workout: WorkoutEntity?
    @NSManaged public var exercise: ExerciseEntity?
}



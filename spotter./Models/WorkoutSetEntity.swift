//
//  WorkoutSetEntity.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 11/8/25.
//

import Foundation
import CoreData

@objc(WorkoutSetEntity)
public class WorkoutSetEntity: NSManagedObject {}

extension WorkoutSetEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutSetEntity> {
        return NSFetchRequest<WorkoutSetEntity>(entityName: "WorkoutSetEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var weight: Double
    @NSManaged public var reps: Int16
    @NSManaged public var timestamp: Date?
    @NSManaged public var exercise: ExerciseEntity?
}

//
//  WorkoutEntity.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/29/25.
//

import Foundation
import CoreData

@objc(WorkoutEntity)
public class WorkoutEntity: NSManagedObject {}

extension WorkoutEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutEntity> {
        NSFetchRequest<WorkoutEntity>(entityName: "WorkoutEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var type: String
    @NSManaged public var date: Date
    @NSManaged public var status: String
    @NSManaged public var perceivedFatigue: Int16
    @NSManaged public var energyLevel: Int16
    @NSManaged public var durationSec: Int32
    @NSManaged public var totalVolume: Double
    @NSManaged public var adherenceScore: Double
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date

    @NSManaged public var user: UserEntity?
    @NSManaged public var program: ProgramEntity?
    @NSManaged public var sets: Set<WorkoutSetEntity>?
    @NSManaged public var mediaShares: Set<MediaShareEntity>?
}


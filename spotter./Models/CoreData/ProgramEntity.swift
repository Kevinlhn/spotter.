//
//  ProgramEntity.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/29/25.
//


import Foundation
import CoreData

@objc(ProgramEntity)
public class ProgramEntity: NSManagedObject {}

extension ProgramEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProgramEntity> {
        NSFetchRequest<ProgramEntity>(entityName: "ProgramEntity")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var trainingMode: String
    @NSManaged public var durationWeeks: Int16
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date
    @NSManaged public var isActive: Bool
    @NSManaged public var metadata: Data? // Encoded JSON
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    @NSManaged public var user: UserEntity?
    @NSManaged public var workouts: Set<WorkoutEntity>?
}
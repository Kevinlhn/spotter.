//
//  GoalEntity.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/29/25.
//


import Foundation
import CoreData

@objc(GoalEntity)
public class GoalEntity: NSManagedObject {}

extension GoalEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<GoalEntity> {
        NSFetchRequest<GoalEntity>(entityName: "GoalEntity")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var type: String
    @NSManaged public var targetValue: Double
    @NSManaged public var currentValue: Double
    @NSManaged public var unit: String
    @NSManaged public var targetDate: Date?
    @NSManaged public var status: String
    @NSManaged public var progressPercent: Double
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    @NSManaged public var user: UserEntity?
}
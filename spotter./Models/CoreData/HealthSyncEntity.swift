//
//  HealthSyncEntity.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/29/25.
//


import Foundation
import CoreData

@objc(HealthSyncEntity)
public class HealthSyncEntity: NSManagedObject {}

extension HealthSyncEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<HealthSyncEntity> {
        NSFetchRequest<HealthSyncEntity>(entityName: "HealthSyncEntity")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var source: String
    @NSManaged public var dailySteps: Int32
    @NSManaged public var activeEnergy: Double
    @NSManaged public var restingHeartRate: Double
    @NSManaged public var vo2max: Double
    @NSManaged public var syncedAt: Date
    
    @NSManaged public var user: UserEntity?
}
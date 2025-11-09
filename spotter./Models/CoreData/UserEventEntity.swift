//
//  UserEventEntity.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/29/25.
//


import Foundation
import CoreData

@objc(UserEventEntity)
public class UserEventEntity: NSManagedObject {}

extension UserEventEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserEventEntity> {
        NSFetchRequest<UserEventEntity>(entityName: "UserEventEntity")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var properties: Data?
    @NSManaged public var timestamp: Date
    
    @NSManaged public var user: UserEntity?
}
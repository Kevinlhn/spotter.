//
//  CoachSessionEntity.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/29/25.
//


import Foundation
import CoreData

@objc(CoachSessionEntity)
public class CoachSessionEntity: NSManagedObject {}

extension CoachSessionEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoachSessionEntity> {
        NSFetchRequest<CoachSessionEntity>(entityName: "CoachSessionEntity")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var sessionState: Data?
    @NSManaged public var lastMessage: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    @NSManaged public var user: UserEntity?
}
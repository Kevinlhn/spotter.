//
//  AIPlanHistoryEntity.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/29/25.
//


import Foundation
import CoreData

@objc(AIPlanHistoryEntity)
public class AIPlanHistoryEntity: NSManagedObject {}

extension AIPlanHistoryEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<AIPlanHistoryEntity> {
        NSFetchRequest<AIPlanHistoryEntity>(entityName: "AIPlanHistoryEntity")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var aiModelVersion: String
    @NSManaged public var parameters: Data?
    @NSManaged public var generatedAt: Date
    
    @NSManaged public var user: UserEntity?
    @NSManaged public var program: ProgramEntity?
}
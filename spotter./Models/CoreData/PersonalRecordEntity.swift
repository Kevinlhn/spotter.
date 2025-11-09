//
//  PersonalRecordEntity.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/29/25.
//


import Foundation
import CoreData

@objc(PersonalRecordEntity)
public class PersonalRecordEntity: NSManagedObject {}

extension PersonalRecordEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PersonalRecordEntity> {
        NSFetchRequest<PersonalRecordEntity>(entityName: "PersonalRecordEntity")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var type: String
    @NSManaged public var value: Double
    @NSManaged public var date: Date
    @NSManaged public var context: Data?
    @NSManaged public var createdAt: Date
    
    @NSManaged public var user: UserEntity?
    @NSManaged public var exercise: ExerciseEntity?
}
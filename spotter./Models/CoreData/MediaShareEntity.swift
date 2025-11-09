//
//  MediaShareEntity.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/29/25.
//


import Foundation
import CoreData

@objc(MediaShareEntity)
public class MediaShareEntity: NSManagedObject {}

extension MediaShareEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaShareEntity> {
        NSFetchRequest<MediaShareEntity>(entityName: "MediaShareEntity")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var type: String
    @NSManaged public var imageURL: String
    @NSManaged public var caption: String?
    @NSManaged public var platform: String?
    @NSManaged public var sharedAt: Date?
    @NSManaged public var createdAt: Date
    
    @NSManaged public var user: UserEntity?
    @NSManaged public var workout: WorkoutEntity?
    @NSManaged public var pr: PersonalRecordEntity?
}
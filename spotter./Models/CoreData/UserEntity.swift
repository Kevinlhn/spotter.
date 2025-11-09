//
//  UserEntity.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/29/25.
//


import Foundation
import CoreData

@objc(UserEntity)
public class UserEntity: NSManagedObject {}

extension UserEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserEntity> {
        NSFetchRequest<UserEntity>(entityName: "UserEntity")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var email: String
    @NSManaged public var name: String
    @NSManaged public var gender: String
    @NSManaged public var dob: Date?
    @NSManaged public var heightCM: Double
    @NSManaged public var weightKG: Double
    @NSManaged public var experienceLevel: String
    @NSManaged public var trainingMode: String
    @NSManaged public var timezone: String
    @NSManaged public var streakDays: Int32
    @NSManaged public var appleHealthConnected: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    // Relationships
    @NSManaged public var programs: Set<ProgramEntity>?
    @NSManaged public var workouts: Set<WorkoutEntity>?
    @NSManaged public var goals: Set<GoalEntity>?
    @NSManaged public var prs: Set<PersonalRecordEntity>?
    @NSManaged public var mediaShares: Set<MediaShareEntity>?
    @NSManaged public var healthSyncs: Set<HealthSyncEntity>?
    @NSManaged public var coachSessions: Set<CoachSessionEntity>?
    @NSManaged public var aiPlanHistories: Set<AIPlanHistoryEntity>?
    @NSManaged public var events: Set<UserEventEntity>?
}

extension UserEntity {
    static func mock(context: NSManagedObjectContext? = nil) -> UserEntity {
        let ctx = context ?? PersistenceController.shared.container.viewContext
        let user = UserEntity(context: ctx)
        user.id = UUID()
        user.name = "Kevin Hernandez-Niño"
        user.email = "kevin@spotter.app"
        user.trainingMode = "hypertrophy"
        user.experienceLevel = "intermediate"
        user.streakDays = 24
        user.createdAt = Date()
        user.updatedAt = Date()
        return user
    }
}

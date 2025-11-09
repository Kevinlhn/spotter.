//
//  Workout.swift
//
import Foundation
import CoreData

public struct Workout: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var programID: UUID?
    public var userID: UUID
    public var title: String
    public var type: WorkoutType
    public var date: Date
    public var status: WorkoutStatus
    public var perceivedFatigue: Int?
    public var energyLevel: Int?
    public var durationSec: Int?
    public var totalVolume: Double?
    public var adherenceScore: Double?
    public var notes: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var sets: [WorkoutSet]

    public init(
        id: UUID = UUID(),
        programID: UUID? = nil,
        userID: UUID,
        title: String,
        type: WorkoutType,
        date: Date = .now,
        status: WorkoutStatus = .planned,
        perceivedFatigue: Int? = nil,
        energyLevel: Int? = nil,
        durationSec: Int? = nil,
        totalVolume: Double? = nil,
        adherenceScore: Double? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        sets: [WorkoutSet] = []
    ) {
        self.id = id
        self.programID = programID
        self.userID = userID
        self.title = title
        self.type = type
        self.date = date
        self.status = status
        self.perceivedFatigue = perceivedFatigue
        self.energyLevel = energyLevel
        self.durationSec = durationSec
        self.totalVolume = totalVolume
        self.adherenceScore = adherenceScore
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sets = sets
    }
}

extension Workout {
    func toEntity(in context: NSManagedObjectContext) -> WorkoutEntity {
        let entity = WorkoutEntity(context: context)
        entity.id = id
        entity.title = title
        entity.type = type.rawValue
        entity.date = date
        entity.status = status.rawValue
        entity.notes = notes
        return entity
    }
}

//
//  PersonalRecord.swift
//
import Foundation

public struct PersonalRecord: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var userID: UUID
    public var exerciseID: UUID
    public var type: PRType
    public var value: Double
    public var date: Date
    public var context: [String: String]?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        userID: UUID,
        exerciseID: UUID,
        type: PRType,
        value: Double,
        date: Date = .now,
        context: [String: String]? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.userID = userID
        self.exerciseID = exerciseID
        self.type = type
        self.value = value
        self.date = date
        self.context = context
        self.createdAt = createdAt
    }
}

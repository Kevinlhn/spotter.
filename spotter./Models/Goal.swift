//
//  Goal.swift
//
import Foundation

public struct Goal: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var userID: UUID
    public var type: GoalType
    public var targetValue: Double
    public var currentValue: Double
    public var unit: String
    public var targetDate: Date?
    public var status: GoalStatus
    public var progressPercent: Double
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        userID: UUID,
        type: GoalType,
        targetValue: Double,
        currentValue: Double = 0,
        unit: String,
        targetDate: Date? = nil,
        status: GoalStatus = .active,
        progressPercent: Double = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.userID = userID
        self.type = type
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.unit = unit
        self.targetDate = targetDate
        self.status = status
        self.progressPercent = progressPercent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

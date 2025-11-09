//
//  Program.swift
//
import Foundation

public struct Program: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var userID: UUID
    public var title: String
    public var trainingMode: TrainingModeType
    public var durationWeeks: Int
    public var startDate: Date
    public var endDate: Date
    public var isActive: Bool
    public var metadata: [String: String]?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        userID: UUID,
        title: String,
        trainingMode: TrainingModeType,
        durationWeeks: Int,
        startDate: Date,
        endDate: Date,
        isActive: Bool = false,
        metadata: [String: String]? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.userID = userID
        self.title = title
        self.trainingMode = trainingMode
        self.durationWeeks = durationWeeks
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

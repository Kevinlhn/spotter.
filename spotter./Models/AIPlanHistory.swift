//
//  AIPlanHistory.swift
//
import Foundation

public struct AIPlanHistory: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var userID: UUID
    public var planID: UUID
    public var aiModelVersion: String
    public var parameters: [String: AnyCodable]
    public var generatedAt: Date

    public init(
        id: UUID = UUID(),
        userID: UUID,
        planID: UUID,
        aiModelVersion: String,
        parameters: [String: AnyCodable],
        generatedAt: Date = .now
    ) {
        self.id = id
        self.userID = userID
        self.planID = planID
        self.aiModelVersion = aiModelVersion
        self.parameters = parameters
        self.generatedAt = generatedAt
    }
}

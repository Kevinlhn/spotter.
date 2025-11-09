//
//  CoachSession.swift
//
import Foundation

public struct CoachSession: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var userID: UUID
    public var sessionState: [String: AnyCodable] // arbitrary JSON
    public var lastMessage: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        userID: UUID,
        sessionState: [String: AnyCodable] = [:],
        lastMessage: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.userID = userID
        self.sessionState = sessionState
        self.lastMessage = lastMessage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

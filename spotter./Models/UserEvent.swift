//
//  UserEvent.swift
//
import Foundation

public struct UserEvent: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var userID: UUID
    public var name: String
    public var properties: [String: AnyCodable]
    public var timestamp: Date

    public init(
        id: UUID = UUID(),
        userID: UUID,
        name: String,
        properties: [String: AnyCodable] = [:],
        timestamp: Date = .now
    ) {
        self.id = id
        self.userID = userID
        self.name = name
        self.properties = properties
        self.timestamp = timestamp
    }
}

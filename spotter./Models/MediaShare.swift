//
//  MediaShare.swift
//
import Foundation

public struct MediaShare: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var userID: UUID
    public var workoutID: UUID?
    public var prID: UUID?
    public var type: MediaShareType
    public var imageURL: String
    public var caption: String?
    public var platform: SharePlatform?
    public var sharedAt: Date?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        userID: UUID,
        workoutID: UUID? = nil,
        prID: UUID? = nil,
        type: MediaShareType,
        imageURL: String,
        caption: String? = nil,
        platform: SharePlatform? = nil,
        sharedAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.userID = userID
        self.workoutID = workoutID
        self.prID = prID
        self.type = type
        self.imageURL = imageURL
        self.caption = caption
        self.platform = platform
        self.sharedAt = sharedAt
        self.createdAt = createdAt
    }
}

//
//  AppleHealthSync.swift
//
import Foundation

public struct AppleHealthSync: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var userID: UUID
    public var source: String // e.g., HealthKit
    public var dailySteps: Int
    public var activeEnergy: Double // kcal
    public var restingHeartRate: Double // bpm
    public var vo2max: Double?
    public var syncedAt: Date

    public init(
        id: UUID = UUID(),
        userID: UUID,
        source: String = "HealthKit",
        dailySteps: Int = 0,
        activeEnergy: Double = 0,
        restingHeartRate: Double = 0,
        vo2max: Double? = nil,
        syncedAt: Date = .now
    ) {
        self.id = id
        self.userID = userID
        self.source = source
        self.dailySteps = dailySteps
        self.activeEnergy = activeEnergy
        self.restingHeartRate = restingHeartRate
        self.vo2max = vo2max
        self.syncedAt = syncedAt
    }
}

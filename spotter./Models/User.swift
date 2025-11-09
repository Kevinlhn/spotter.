//
//  User.swift
//
import Foundation

public struct User: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var email: String
    public var name: String
    public var gender: Gender
    public var dob: Date?
    public var heightCM: Double?
    public var weightKG: Double?
    public var experienceLevel: ExperienceLevel
    public var trainingMode: TrainingModeType
    public var timezone: String
    public var streakDays: Int
    public var appleHealthConnected: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        email: String,
        name: String,
        gender: Gender = .unspecified,
        dob: Date? = nil,
        heightCM: Double? = nil,
        weightKG: Double? = nil,
        experienceLevel: ExperienceLevel = .novice,
        trainingMode: TrainingModeType = .mixed,
        timezone: String = TimeZone.current.identifier,
        streakDays: Int = 0,
        appleHealthConnected: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.gender = gender
        self.dob = dob
        self.heightCM = heightCM
        self.weightKG = weightKG
        self.experienceLevel = experienceLevel
        self.trainingMode = trainingMode
        self.timezone = timezone
        self.streakDays = streakDays
        self.appleHealthConnected = appleHealthConnected
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}


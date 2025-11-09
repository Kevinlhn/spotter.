//
//  Exercise.swift
//
import Foundation

public struct Exercise: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var category: ExerciseCategory
    public var modality: ExerciseModality
    public var primaryMuscles: [String]
    public var secondaryMuscles: [String]
    public var equipmentNeeded: [String]
    public var difficulty: Difficulty
    public var videoURL: String?
    public var coachingCues: [String]
    public var isPublic: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        category: ExerciseCategory,
        modality: ExerciseModality,
        primaryMuscles: [String],
        secondaryMuscles: [String] = [],
        equipmentNeeded: [String] = [],
        difficulty: Difficulty = .beginner,
        videoURL: String? = nil,
        coachingCues: [String] = [],
        isPublic: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.modality = modality
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.equipmentNeeded = equipmentNeeded
        self.difficulty = difficulty
        self.videoURL = videoURL
        self.coachingCues = coachingCues
        self.isPublic = isPublic
        self.createdAt = createdAt
    }
}

//
//  WorkoutSet.swift
//
import Foundation

public struct WorkoutSet: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var workoutID: UUID
    public var exerciseID: UUID
    public var setNumber: Int
    public var reps: Int?
    public var weightKG: Double?
    public var distanceM: Int?
    public var durationSec: Int?
    public var velocityMPS: Double?
    public var rir: Double?
    public var rpe: Double?
    public var isWarmup: Bool
    public var isSuperset: Bool
    public var completed: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        workoutID: UUID,
        exerciseID: UUID,
        setNumber: Int,
        reps: Int? = nil,
        weightKG: Double? = nil,
        distanceM: Int? = nil,
        durationSec: Int? = nil,
        velocityMPS: Double? = nil,
        rir: Double? = nil,
        rpe: Double? = nil,
        isWarmup: Bool = false,
        isSuperset: Bool = false,
        completed: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.workoutID = workoutID
        self.exerciseID = exerciseID
        self.setNumber = setNumber
        self.reps = reps
        self.weightKG = weightKG
        self.distanceM = distanceM
        self.durationSec = durationSec
        self.velocityMPS = velocityMPS
        self.rir = rir
        self.rpe = rpe
        self.isWarmup = isWarmup
        self.isSuperset = isSuperset
        self.completed = completed
        self.createdAt = createdAt
    }
}

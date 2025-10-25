//
//  Workout.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 9/26/25.
//
import Foundation

struct Workout: Identifiable, Codable {
    let id: UUID
    var date: Date
    var exercises: [WorkoutSet]
    var durationMinutes: Double

    init(id: UUID = UUID(), date: Date, exercises: [WorkoutSet], durationMinutes: Double) {
        self.id = id
        self.date = date
        self.exercises = exercises
        self.durationMinutes = durationMinutes
    }

    private enum CodingKeys: String, CodingKey {
        case id, date, exercises, durationMinutes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.date = try container.decode(Date.self, forKey: .date)
        self.exercises = try container.decode([WorkoutSet].self, forKey: .exercises)
        self.durationMinutes = try container.decode(Double.self, forKey: .durationMinutes)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(exercises, forKey: .exercises)
        try container.encode(durationMinutes, forKey: .durationMinutes)
    }
}

struct WorkoutSet: Identifiable, Codable {
    let id: UUID
    var exercise: Exercise
    var sets: Int
    var reps: Int
    var weight: Double? // optional for bodyweight
    var duration: Double? // for cardio/timed exercises

    init(id: UUID = UUID(),
         exercise: Exercise,
         sets: Int,
         reps: Int,
         weight: Double? = nil,
         duration: Double? = nil) {
        self.id = id
        self.exercise = exercise
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.duration = duration
    }

    private enum CodingKeys: String, CodingKey {
        case id, exercise, sets, reps, weight, duration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.exercise = try container.decode(Exercise.self, forKey: .exercise)
        self.sets = try container.decode(Int.self, forKey: .sets)
        self.reps = try container.decode(Int.self, forKey: .reps)
        self.weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        self.duration = try container.decodeIfPresent(Double.self, forKey: .duration)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(exercise, forKey: .exercise)
        try container.encode(sets, forKey: .sets)
        try container.encode(reps, forKey: .reps)
        try container.encodeIfPresent(weight, forKey: .weight)
        try container.encodeIfPresent(duration, forKey: .duration)
    }
}

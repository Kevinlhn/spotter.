//
//  Enums.swift
//  Spotter Fitness
//
import Foundation

public enum Gender: String, Codable, CaseIterable, Sendable {
    case male, female, other, unspecified
}

public enum ExperienceLevel: String, Codable, CaseIterable, Sendable {
    case novice, intermediate, advanced, elite
}

public enum TrainingModeType: String, Codable, CaseIterable, Sendable {
    case strength, hypertrophy, endurance, fatLoss, mobility, mixed
}

public enum WorkoutType: String, Codable, CaseIterable, Sendable {
    case strength, hypertrophy, cardio, mobility, mixed
}

public enum WorkoutStatus: String, Codable, CaseIterable, Sendable {
    case planned, completed, skipped
}

public enum GoalType: String, Codable, CaseIterable, Sendable {
    case bodyweight, e1rm, pace, distance, streak, custom
}

public enum GoalStatus: String, Codable, CaseIterable, Sendable {
    case active, achieved, paused
}

public enum PRType: String, Codable, CaseIterable, Sendable {
    case weight, reps, time, distance, velocity
}

public enum MediaShareType: String, Codable, CaseIterable, Sendable {
    case workoutSummary, prAchievement, goalProgress
}

public enum SharePlatform: String, Codable, CaseIterable, Sendable {
    case instagram, threads, tiktok, x, other
}

public enum ExerciseCategory: String, Codable, CaseIterable, Sendable {
    case barbell, dumbbell, machine, bodyweight, cardio, mobility
}

public enum ExerciseModality: String, Codable, CaseIterable, Sendable {
    case compound, isolation, conditioning, stretch
}

public enum Difficulty: String, Codable, CaseIterable, Sendable {
    case beginner, intermediate, advanced
}

//
//  User.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 9/26/25.
//

import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    var name: String
    var age: Int
    var weight: Double
    var height: Double
    var goals: [FitnessGoal]        // 👈 multiple goals
    var activityLevel: ActivityLevel
    var injuries: [Injury]          // 👈 multiple injuries
    
    init(id: UUID = UUID(),
         name: String,
         age: Int,
         weight: Double,
         height: Double,
         goals: [FitnessGoal] = [],
         activityLevel: ActivityLevel = .sedentary,
         injuries: [Injury] = []) {
        self.id = id
        self.name = name
        self.age = age
        self.weight = weight
        self.height = height
        self.goals = goals
        self.activityLevel = activityLevel
        self.injuries = injuries
    }
}

// MARK: - Fitness Goal
enum FitnessGoal: String, Codable, CaseIterable {
    case strength
    case hypertrophy
    case endurance
    case general
    case weightLoss
    case mobility
}

// MARK: - Activity Level
enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary
    case lightlyActive
    case active
    case veryActive
}

// MARK: - Injury
enum Injury: String, Codable, CaseIterable {
    case none
    case back
    case knees
    case shoulders
    case other
}

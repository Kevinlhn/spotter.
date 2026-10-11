//
//  SpotterExportManager.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 12/13/25.
//

import Foundation
import CoreData

enum SpotterExportError: Error {
    case noWorkoutsFound
}

final class SpotterExportManager {
    static let shared = SpotterExportManager()
    private init() {}

    // MARK: - Codable Export Models

    struct ExportPayload: Codable {
        let exportedAt: Date
        let app: String
        let version: Int
        let workouts: [ExportWorkout]
        let templates: [ExportWorkout]
        let exerciseLibrary: [ExportLibraryExercise]
    }

    struct ExportLibraryExercise: Codable {
        let id: UUID
        let name: String
        let primaryMuscle: String?
        let isCustom: Bool
        let isFavorite: Bool
        let createdAt: Date
    }

    struct ExportWorkout: Codable {
        let id: UUID
        let name: String
        let date: Date
        let scheduledDate: Date?
        let notes: String?
        let status: String
        let weightUnit: String?
        let exercises: [ExportExercise]
    }

    struct ExportExercise: Codable {
        let id: UUID
        let name: String
        let muscleGroup: String?
        let createdAt: Date?
        let targetSets: Int
        let targetReps: Int
        let targetRepMinimum: Int?
        let targetWeight: Double?
        /// nil uses the global rest preference; zero explicitly disables rest.
        let restSeconds: Int?
        let sets: [ExportSet]
    }

    struct ExportSet: Codable {
        let id: UUID
        let reps: Int16
        let weight: Double
        let timestamp: Date?
    }

    // MARK: - Public API

    /// Creates a JSON file in temp directory and returns the file URL.
    func exportJSONFile(from context: NSManagedObjectContext) throws -> URL {
        let workouts = try fetchWorkouts(context: context)
        let libraryRequest = ExerciseTemplateEntity.fetchRequest()
        libraryRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        let library = try context.fetch(libraryRequest)
        if workouts.isEmpty && library.isEmpty { throw SpotterExportError.noWorkoutsFound }

        let payload = ExportPayload(
            exportedAt: Date(),
            app: "spotter",
            version: 4,
            workouts: workouts.filter { $0.workoutStatus != .template }.map { mapWorkout($0) },
            templates: workouts.filter { $0.workoutStatus == .template }.map { mapWorkout($0) },
            exerciseLibrary: library.map {
                ExportLibraryExercise(id: $0.id, name: $0.name, primaryMuscle: $0.primaryMuscle,
                                      isCustom: $0.isCustom, isFavorite: $0.isFavorite, createdAt: $0.createdAt)
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(payload)

        let filename = "spotter_export_\(isoFileSafe(Date())).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: [.atomic])

        return url
    }

    // MARK: - Fetch + Mapping

    private func fetchWorkouts(context: NSManagedObjectContext) throws -> [WorkoutEntity] {
        let request: NSFetchRequest<WorkoutEntity> = WorkoutEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        return try context.fetch(request)
    }

    private func mapWorkout(_ w: WorkoutEntity) -> ExportWorkout {
        return ExportWorkout(
            id: w.id,
            name: w.name,
            date: w.date,
            scheduledDate: w.scheduledDate,
            notes: w.notes,
            status: w.status ?? "scheduled",
            weightUnit: w.weightUnit,
            exercises: w.sortedExercises.map { mapExercise($0) }
        )
    }

    private func mapExercise(_ e: ExerciseEntity) -> ExportExercise {
        return ExportExercise(
            id: e.id, // in case your model allows nil
            name: e.name,
            muscleGroup: e.muscleGroup,
            createdAt: e.createdAt,
            targetSets: e.plannedSets,
            targetReps: e.plannedReps,
            targetRepMinimum: e.targetRepMinimum > 0 ? Int(e.targetRepMinimum) : nil,
            targetWeight: e.targetWeight?.doubleValue,
            restSeconds: e.restOverrideSeconds,
            sets: e.sortedSets.map { mapSet($0) }
        )
    }

    private func mapSet(_ s: WorkoutSetEntity) -> ExportSet {
        ExportSet(
            id: s.value(forKey: "id") as? UUID ?? UUID(),
            reps: s.reps,
            weight: s.weight,
            timestamp: s.timestamp
        )
    }

    private func isoFileSafe(_ date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.string(from: date)
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: ".", with: "-")
    }
}


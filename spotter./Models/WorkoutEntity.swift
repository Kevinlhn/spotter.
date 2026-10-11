//
//  WorkoutEntity.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 11/8/25.
//

import Foundation
import CoreData

@objc(WorkoutEntity)
public class WorkoutEntity: NSManagedObject {}

extension WorkoutEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutEntity> {
        return NSFetchRequest<WorkoutEntity>(entityName: "WorkoutEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var date: Date
    /// The assigned calendar day survives starting/completing a scheduled workout.
    @NSManaged public var scheduledDate: Date?
    var calendarDate: Date { scheduledDate ?? date }
    @NSManaged public var sessionData: Data?
    @NSManaged public var notes: String?
    @NSManaged public var weightUnit: String?
    var weightLabel: String { weightUnit ?? "load" }
    @NSManaged public var exercises: NSSet?
    @NSManaged public var status: String?

    // MARK: - Computed helpers
    var sortedExercises: [ExerciseEntity] {
        let set = exercises as? Set<ExerciseEntity> ?? []
        return set.sorted {
            let left = $0.createdAt ?? .distantPast
            let right = $1.createdAt ?? .distantPast
            if left != right { return left < right }
            return $0.objectID.uriRepresentation().absoluteString < $1.objectID.uriRepresentation().absoluteString
        }
    }

    var workoutStatus: WorkoutStatus {
        get { WorkoutStatus(rawValue: status ?? WorkoutStatus.scheduled.rawValue) ?? .scheduled }
        set { status = newValue.rawValue }
    }
}

// MARK: Generated accessors for exercises
extension WorkoutEntity {
    @objc(addExercisesObject:)
    @NSManaged public func addToExercises(_ value: ExerciseEntity)

    @objc(removeExercisesObject:)
    @NSManaged public func removeFromExercises(_ value: ExerciseEntity)

    @objc(addExercises:)
    @NSManaged public func addToExercises(_ values: NSSet)

    @objc(removeExercises:)
    @NSManaged public func removeFromExercises(_ values: NSSet)
}


extension WorkoutEntity: Identifiable { }

// MARK: - Enum
enum WorkoutStatus: String, CaseIterable {
    case template
    case scheduled
    case active
    case completed

    var label: String {
        switch self {
        case .template: return "Saved workout"
        case .scheduled: return "Scheduled"
        case .active: return "Active"
        case .completed: return "Completed"
        }
    }

    var color: String {
        switch self {
        case .template: return "blue"
        case .scheduled: return "gray"
        case .active: return "blue"
        case .completed: return "green"
        }
    }
}

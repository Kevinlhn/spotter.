import CoreData
import Foundation

extension Persistence {
    static var preview: Persistence = {
        let controller = Persistence(inMemory: true)
        let viewContext = controller.container.viewContext

        // Example preview data
        let workout = WorkoutEntity.insert(in: viewContext)
        workout.id = UUID()
        workout.name = "Sample Push Day"
        workout.date = Date()
        workout.status = WorkoutStatus.active.rawValue

        let exercise = ExerciseEntity.insert(in: viewContext)
        exercise.id = UUID()
        exercise.name = "Bench Press"
        exercise.isCustom = true
        exercise.createdAt = Date()

        let set1 = WorkoutSetEntity.insert(in: viewContext)
        set1.id = UUID()
        set1.reps = 8
        set1.weight = 135
        set1.timestamp = Date()

        let set2 = WorkoutSetEntity.insert(in: viewContext)
        set2.id = UUID()
        set2.reps = 6
        set2.weight = 145
        set2.timestamp = Date()

        exercise.addToSets([set1, set2])
        workout.addToExercises(exercise)

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Preview save error: \(nsError), \(nsError.userInfo)")
        }

        return controller
    }()

}

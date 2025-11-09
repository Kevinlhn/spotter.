//
//  WorkoutDetailOverlay.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/30/25.
//

import SwiftUI
import CoreData

struct WorkoutDetailOverlay: View {
        @Environment(\.managedObjectContext) private var context
        @Environment(\.colorScheme) private var colorScheme

        @ObservedObject var workout: WorkoutEntity
        @State private var showAddExercise = false

        @FetchRequest private var sets: FetchedResults<WorkoutSetEntity>

        init(workout: WorkoutEntity) {
            self.workout = workout
            _sets = FetchRequest<WorkoutSetEntity>(
                sortDescriptors: [NSSortDescriptor(keyPath: \WorkoutSetEntity.createdAt, ascending: true)],
                predicate: NSPredicate(format: "workout == %@", workout)
            )
        }

        var body: some View {
                // Content
                    VStack{
                        headerSection
                        exerciseListSection

                        // MARK: - Add Exercise Button
                        Button {
                            withAnimation(.spring()) { showAddExercise = true }
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Exercise")
                            }
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppColors.bluePrimary.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                        .padding(.horizontal)

                        // MARK: - Notes
                        if let notes = workout.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(.headline)
                                    .foregroundColor(AppColors.bluePrimary)
                                Text(notes)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(15)
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                    .background(.primary.opacity(0.05))
                    .cornerRadius(80)
                    .padding()

                // MARK: - Overlay Presentation
                if showAddExercise {
                    Rectangle().fill(.ultraThinMaterial).ignoresSafeArea() .onTapGesture {
                        withAnimation(.spring()) { showAddExercise = false }
                    }

                    VStack {
                        AddExerciseOverlay(workout: workout) {
                            withAnimation(.spring()) { showAddExercise = false }
                        }
                        .environment(\.managedObjectContext, context)
                    }
                    .padding()
                    .frame(maxWidth: 500)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(10)
                }
        }

        // MARK: - Header Section
        private var headerSection: some View {
            VStack(spacing: 6) {
                Text(workout.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppColors.bluePrimary.gradient)
                    .multilineTextAlignment(.center)
                
                Text(workout.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(workout.type.capitalized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 20) {
                    statCard(icon: "clock.fill", title: "Duration", value: durationString)
                    statCard(icon: "flame.fill", title: "Volume", value: "\(Int(workout.totalVolume)) kg")
                    statCard(icon: "bolt.fill", title: "Energy", value: "\(workout.energyLevel)")
                }
                .padding(.top, 10)
            }
            .padding()
        }

        private var exerciseListSection: some View {
            VStack(spacing: 14) {
                if !sets.isEmpty {
                    ForEach(sortedExerciseNames, id: \.self) { exerciseName in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(exerciseName)
                                .font(.headline)
                                .foregroundStyle(AppColors.bluePrimary)

                            let exerciseSets: [WorkoutSetEntity] = groupedSets[exerciseName] ?? []
                            ForEach(exerciseSets, id: \.objectID) { set in
                                setRow(for: set)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }

// MARK: - Exercise Helpers
private var sortedExerciseNames: [String] {
    groupedSets.keys.sorted()
}

@ViewBuilder
private func setRow(for set: WorkoutSetEntity) -> some View {
    HStack {
        Text("Set \(set.setNumber)")
            .font(.caption)
            .frame(width: 50, alignment: .leading)
        Spacer()
        Text("\(set.reps) reps")
        Text("\(set.weightKG, specifier: "%.1f") kg")
        Spacer()
        Button {
            toggleSetCompletion(set)
        } label: {
            Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(set.completed ? .green : .gray)
        }
    }
    .padding(8)
    .background(.ultraThinMaterial)
    .cornerRadius(10)
}

        // MARK: - Helpers
        private func statCard(icon: String, title: String, value: String) -> some View {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(AppColors.bluePrimary)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(.ultraThinMaterial)
            .cornerRadius(15)
        }

        private var durationString: String {
            let minutes = Int(workout.durationSec) / 60
            return minutes > 0 ? "\(minutes) min" : "--"
        }

        private var groupedSets: [String: [WorkoutSetEntity]] {
            Dictionary(grouping: sets) { $0.exercise?.name ?? "Unknown" }
        }

        private func toggleSetCompletion(_ set: WorkoutSetEntity) {
            set.completed.toggle()
            try? context.save()
        }
    }

// MARK: - Preview
#Preview("WorkoutDetailOverlay") {
    // Use the in-memory preview container from your PersistenceController
    let context = PersistenceController.preview.container.viewContext

    // Create a fake workout
    let workout = WorkoutEntity(context: context)
    workout.id = UUID()
    workout.title = "Upper Body Strength"
    workout.type = "strength"
    workout.date = Date()
    workout.status = "completed"
    workout.durationSec = 3600
    workout.totalVolume = 8200
    workout.energyLevel = 8
    workout.perceivedFatigue = 6
    workout.createdAt = Date()
    workout.updatedAt = Date()

    // Add a few fake exercises and sets
    let exercises = ["Bench Press", "Pull-Ups", "Overhead Press"]
    for (i, name) in exercises.enumerated() {
        for setNum in 1...3 {
            let set = WorkoutSetEntity(context: context)
            set.id = UUID()
            set.setNumber = Int16(setNum)
            set.reps = Int16(10 - setNum)
            set.weightKG = Double(60 + (i * 10))
            set.completed = true
            set.createdAt = Date()
            
            // Fake exercise relationship
            let exercise = ExerciseEntity(context: context)
            exercise.name = name
            exercise.category = "strength"
            exercise.createdAt = Date()
            set.exercise = exercise
            set.workout = workout
        }
    }

    // Return preview view
    return WorkoutDetailOverlay(workout: workout)
        .environment(\.managedObjectContext, context)
        .preferredColorScheme(.dark)
}

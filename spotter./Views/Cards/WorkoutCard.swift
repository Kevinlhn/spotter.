//
//  WorkoutCard.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 11/8/25.
//

import SwiftUI
import CoreData

struct WorkoutCard: View {
    let workout: WorkoutEntity
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // MARK: - Title & Date
            HStack {
                Text(workout.name)
                    .font(.headline)
                    .foregroundColor(AppColors.bluePrimary)

                Spacer()

                Text(workout.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // MARK: - Notes (if any)
            if let notes = workout.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Divider().opacity(0.2)

            // MARK: - Exercise Summary
            if let exercises = workout.exercises as? Set<ExerciseEntity>, !exercises.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(exercises.count) Exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(exercises.prefix(3).compactMap { $0.name }, id: \.self) { name in
                            Text(name)
                                .font(.caption2)
                                .foregroundColor(AppColors.bluePrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.bluePrimary.opacity(0.15))
                                .cornerRadius(6)
                        }

                        if exercises.count > 3 {
                            Text("+\(exercises.count - 3)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                }
            } else {
                Text("No exercises yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppColors.bluePrimary.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 0.5)
        )
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }
}

#Preview("WorkoutCard") {
    // MARK: - Preview Data Setup
    let context = Persistence.preview.container.viewContext

    // Try to reuse an existing preview workout, otherwise create one safely.
    let request: NSFetchRequest<WorkoutEntity> = WorkoutEntity.fetchRequest()
    let workout = (try? context.fetch(request))?.first ?? {
        let w = WorkoutEntity(context: context)
        w.id = UUID()
        w.name = "Push Day"
        w.date = Date()
        w.notes = "Chest & triceps focus."

        let bench = ExerciseEntity(context: context)
        bench.id = UUID()
        bench.name = "Bench Press"
        bench.createdAt = Date()
        bench.isCustom = true

        let dips = ExerciseEntity(context: context)
        dips.id = UUID()
        dips.name = "Dips"
        dips.createdAt = Date()
        dips.isCustom = true

        w.addToExercises(bench)
        w.addToExercises(dips)
        return w
    }()

    return ZStack {
        SpotterBackground()
        WorkoutCard(workout: workout)
            .frame(width: 350)
            .padding()
    }
    .environment(\.managedObjectContext, context)
    .preferredColorScheme(.dark)
}

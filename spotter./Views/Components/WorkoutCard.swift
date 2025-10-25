//
//  WorkoutCard.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/2/25.
//
import SwiftUI
import Foundation

struct WorkoutCard: View {
    var workout: Workout
    var tags: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: Date & Duration
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("Workout Plan")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "1E5A66"))
                }
                Spacer()
                Text("\(workout.durationMinutes, specifier: "%.0f") min")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "1E5A66"))
            }

            Divider()

            // Exercise Preview
            VStack(alignment: .leading, spacing: 12) {
                ForEach(workout.exercises.prefix(3)) { set in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(set.exercise.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "1E5A66"))
                            Text(exerciseDetailText(for: set))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        
                        
                        // Optional progress circle for future completion feature
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(Color(hex: "1E5A66"), lineWidth: 3)
                            .frame(width: 24, height: 24)
                    }
                }

                // Show “+N more exercises” if more than 3
                if workout.exercises.count > 3 {
                    Text("+\(workout.exercises.count - 3) more exercises")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            // Tags
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "1E5A66").opacity(0.2))
                                .foregroundColor(Color(hex: "1E5A66"))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.white, Color(hex: "E6F0F2")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }

    private func exerciseDetailText(for set: WorkoutSet) -> String {
        var components: [String] = []
        components.append("\(set.sets)x\(set.reps)")
        if let weight = set.weight {
            let weightStr = weight.formatted(.number.precision(.fractionLength(0)))
            components.append("\(weightStr) lbs")
        }
        if let duration = set.duration {
            let durationStr = duration.formatted(.number.precision(.fractionLength(0)))
            components.append("\(durationStr) sec")
        }
        return components.joined(separator: " • ")
    }
}

struct WorkoutCard_Previews: PreviewProvider {
    static var sampleWorkout: Workout {
        let ex1 = Exercise(
            name: "Bench Press",
            category: .push,
            primaryMuscles: [.chestMiddle],
            secondaryMuscles: [.tricepsLateral, .shouldersFront],
            equipment: ["Barbell"],
            caloriesPerMinute: 20
        )
        let ex2 = Exercise(
            name: "Squat",
            category: .legs,
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes],
            equipment: ["Barbell"],
            caloriesPerMinute: 10
        )
        let ex3 = Exercise(
            name: "Plank",
            category: .core,
            primaryMuscles: [.absUpper, .absLower],
            secondaryMuscles: [],
            equipment: [],
            caloriesPerMinute: 5
        )
        let set1 = WorkoutSet(exercise: ex1, sets: 3, reps: 12, weight: 200)
        let set2 = WorkoutSet(exercise: ex2, sets: 4, reps: 10, weight: 150)
        let set3 = WorkoutSet(exercise: ex3, sets: 1, reps: 1, duration: 60)
        return Workout(date: Date(), exercises: [set1, set2, set3], durationMinutes: 60)
    }
    
    static var previews: some View {
        WorkoutCard(workout: sampleWorkout, tags: ["Chest", "Strength"])
    }
}

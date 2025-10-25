//
//  WSetCard.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/3/25.
//
import SwiftUI

struct WSetCard: View {
    @Binding var set: WorkoutSet

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(set.exercise.name)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "1E5A66"))

            HStack(spacing: 16) {
                // Sets
                IntControl(title: "Sets", value: $set.sets, range: 1...10)

                // Reps
                IntControl(title: "Reps", value: $set.reps, range: 1...50)

                // Weight or Duration depending on category
                if set.exercise.category == .cardio {
                    IntControl(
                        title: "Duration (s)",
                        value: Binding(
                            get: { Int(set.duration ?? 60) },
                            set: { set.duration = Double($0) }
                        ),
                        range: 10...600
                    )
                } else {
                    IntControl(
                        title: "Weight (lbs)",
                        value: Binding(
                            get: { Int(set.weight ?? 0) },
                            set: { set.weight = Double($0) }
                        ),
                        range: 0...500,
                        step: 5 // increment by 5
                    )
                }
            }
            .font(.caption)
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color(hex: "F2F7F8"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// Small reusable numeric control with +/- buttons and optional TextField
struct IntControl: View {
    var title: String
    @Binding var value: Int
    var range: ClosedRange<Int>
    var step: Int = 1 // default increment step

    @State private var textValue: String = ""

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                Button {
                    let newValue = max(range.lowerBound, value - step)
                    value = newValue
                    textValue = "\(newValue)"
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(title) minus")

                TextField("", text: $textValue)
                    .frame(width: 40)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .onAppear { textValue = "\(value)" }
                    .onChange(of: textValue) { old, new in
                        if let intVal = Int(new) {
                            value = min(max(range.lowerBound, intVal), range.upperBound)
                        }
                    }
                Button {
                    let newValue = min(range.upperBound, value + step)
                    value = newValue
                    textValue = "\(newValue)"
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(title) plus")
            }
        }
    }
}

// MARK: - Preview
struct WSetCard_Previews: PreviewProvider {
    static var bench = Exercise(
        name: "Bench Press",
        category: .push,
        primaryMuscles: [.chestMiddle],
        secondaryMuscles: [.tricepsLong],
        equipment: ["Barbell"],
        caloriesPerMinute: 8
    )

    static var plank = Exercise(
        name: "Plank",
        category: .cardio,
        primaryMuscles: [.absUpper, .absLower],
        secondaryMuscles: [],
        equipment: ["Bodyweight"],
        caloriesPerMinute: 4
    )

    static var previews: some View {
        Group {
            WSetCard(set: .constant(WorkoutSet(exercise: bench, sets: 3, reps: 8, weight: 100)))
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Weighted Exercise")

            WSetCard(set: .constant(WorkoutSet(exercise: plank, sets: 1, reps: 1, duration: 60)))
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Cardio (Duration)")
        }
    }
}

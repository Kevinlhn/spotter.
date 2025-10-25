//
//  WorkoutEditor.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/2/25.
//

import SwiftUI

struct WorkoutEditor: View {
    @Environment(\.dismiss) var dismiss
    
    // Input
    @State private var selectedExercises: [WorkoutSet] = []
    @State private var workoutTags: [String] = []
    @State private var tagInput: String = ""
    @State private var date: Date = Date()
    
    // Library
    var allExercises: [Exercise] = []
    var onSave: ((Workout, [String]) -> Void)?
    
    // Picker state
    @State private var showExercisePicker = false
    
    // Computed property for total duration
    private var totalDuration: Double {
        selectedExercises.reduce(0) { $0 + ($1.duration ?? Double($1.sets * $1.reps)) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Date picker
                DatePicker("Workout Date", selection: $date, displayedComponents: .date)
                    .padding(.horizontal)
                
                Divider()
                
                // Exercise list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(selectedExercises.indices, id: \.self) { index in
                            WSetCard(set: $selectedExercises[index])
                        }
                        
                        // Open Exercise Picker
                        Button {
                            showExercisePicker.toggle()
                        } label: {
                            Label("Add Exercise", systemImage: "plus.circle.fill")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(hex: "1E5A66"))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                
                // Tags input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "1E5A66"))
                    
                    HStack {
                        TextField("Add tag", text: $tagInput)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("Add") {
                            let trimmed = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            workoutTags.append(trimmed)
                            tagInput = ""
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: "1E5A66"))
                    }
                    
                    // Show tags
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(workoutTags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(hex: "1E5A66").opacity(0.2))
                                        .foregroundColor(Color(hex: "1E5A66"))
                                        .clipShape(Capsule())
                                    
                                    Button(action: {
                                        workoutTags.removeAll { $0 == tag }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Save Button
                Button {
                    let workout = Workout(date: date, exercises: selectedExercises, durationMinutes: totalDuration)
                    onSave?(workout, workoutTags)
                    dismiss()
                } label: {
                    Text("Save Workout")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "1E5A66"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("New Workout")
            .sheet(isPresented: $showExercisePicker) {
                ExercisePicker(allExercises: allExercises) { exercise in
                    let newSet = WorkoutSet(exercise: exercise, sets: 3, reps: 10)
                    selectedExercises.append(newSet)
                }
            }
        }
    }
}

// MARK: - Preview
struct WorkoutEditor_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutEditor(
            allExercises: [
                Exercise(
                    name: "Bench Press",
                    category: .push,
                    primaryMuscles: [.chestMiddle],
                    secondaryMuscles: [.tricepsLong],
                    equipment: ["Barbell"],
                    caloriesPerMinute: 8
                ),
                Exercise(
                    name: "Squat",
                    category: .legs,
                    primaryMuscles: [.quads, .glutes],
                    secondaryMuscles: [.hamstrings],
                    equipment: ["Barbell"],
                    caloriesPerMinute: 10
                ),
                Exercise(
                    name: "Running",
                    category: .cardio,
                    primaryMuscles: [.calvesGastrocnemius],
                    secondaryMuscles: [],
                    equipment: ["Treadmill"],
                    caloriesPerMinute: 12
                )
            ]
        ) { workout, tags in
            print("Saved workout: \(workout)")
            print("Tags: \(tags)")
        }
    }
}

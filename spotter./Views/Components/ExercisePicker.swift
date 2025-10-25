//
//  ExercisePicker.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/3/25.
//

import SwiftUI

struct ExercisePicker: View {
    var allExercises: [Exercise]
    var onSelect: (Exercise) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var searchText: String = ""
    @State private var showNewExerciseForm = false
    
    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return allExercises
        } else {
            return allExercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Option to create new exercise
                Section {
                    Button {
                        showNewExerciseForm = true
                    } label: {
                        Label("Create New Exercise", systemImage: "plus.circle.fill")
                            .foregroundColor(Color(hex: "1E5A66"))
                    }
                }
                
                // Library list
                Section("Library") {
                    ForEach(filteredExercises) { exercise in
                        Button {
                            onSelect(exercise)
                            dismiss()
                        } label: {
                            HStack {
                                Text(exercise.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(exercise.category.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showNewExerciseForm) {
                ExerciseForm { newExercise in
                    onSelect(newExercise)  // immediately return the new exercise
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    let sampleExercises = [
        Exercise(name: "Bench Press", category: .push, primaryMuscles: [.chestLower], secondaryMuscles: [.tricepsLong], equipment: ["Barbell"], caloriesPerMinute: 6),
        Exercise(name: "Deadlift", category: .pull, primaryMuscles: [.abductors], secondaryMuscles: [.absLower], equipment: ["Barbell"], caloriesPerMinute: 8),
        Exercise(name: "Squat", category: .legs, primaryMuscles: [.quads], secondaryMuscles: [.glutes], equipment: ["Barbell"], caloriesPerMinute: 7)
    ]
    
    ExercisePicker(allExercises: sampleExercises) { selected in
        print("Selected: \(selected.name)")
    }
}

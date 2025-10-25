//
//  ExerciseForm.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/3/25.
//


import SwiftUI

struct ExerciseForm: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var category: ExerciseCategory = .push
    
    var onSave: (Exercise) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise Info") {
                    TextField("Exercise Name", text: $name)
                    
                    Picker("Category", selection: $category) {
                        ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue.capitalized).tag(cat)
                        }
                    }
                }
            }
            .navigationTitle("New Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newExercise = Exercise(
                            id: UUID(),
                            name: name,
                            category: category,
                            primaryMuscles: [],
                            secondaryMuscles: [],
                            equipment: [],
                            caloriesPerMinute: 5
                        )
                        onSave(newExercise)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    ExerciseForm { exercise in
        print("Created exercise: \(exercise.name)")
    }
}

//
//  AddExerciseOverlay.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/30/25.
//


import SwiftUI
import CoreData

struct AddExerciseOverlay: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    
    var workout: WorkoutEntity               // parent workout
    var onDismiss: () -> Void
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ExerciseEntity.name, ascending: true)],
        animation: .easeInOut
    ) private var exercises: FetchedResults<ExerciseEntity>
    
    // MARK: - Fields
    @State private var selectedExercise: ExerciseEntity?
    @State private var customName: String = ""
    @State private var reps: String = ""
    @State private var weight: String = ""
    @State private var rir: String = ""
    @State private var rpe: String = ""
    @State private var setsCount: Int = 3
    @State private var isWarmup: Bool = false
    @State private var showSaved = false
    @State private var useCustomExercise = false
    
    var body: some View {
        VStack {
            VStack(spacing: 22) {
                Text("Add Exercise")
                    .font(.title2.bold())

                // MARK: - Exercise Picker or Custom
                Picker("Exercise Source", selection: $useCustomExercise) {
                    Text("Library").tag(false)
                    Text("Custom").tag(true)
                }
                .pickerStyle(.segmented)

                if useCustomExercise {
                    SpotterTextField("Exercise Name", text: $customName, systemImage: "square.and.pencil")
                } else {
                    Menu {
                        ForEach(exercises, id: \.objectID) { exercise in
                            Button(exercise.name) {
                                selectedExercise = exercise
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "dumbbell.fill")
                            Text(selectedExercise?.name ?? "Select Exercise")
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }
                }

                // MARK: - Set Details
                SpotterTextField("Reps per set", text: $reps, systemImage: "number.circle")
                    .keyboardType(.numberPad)
                
                SpotterTextField("Weight (kg)", text: $weight, systemImage: "scalemass.fill")
                    .keyboardType(.decimalPad)

                Stepper("Sets: \(setsCount)", value: $setsCount, in: 1...10)
                    .padding(.vertical, 6)
                
                HStack {
                    SpotterTextField("RIR", text: $rir, systemImage: "arrow.down.right.circle")
                        .keyboardType(.decimalPad)
                    SpotterTextField("RPE", text: $rpe, systemImage: "arrow.up.right.circle")
                        .keyboardType(.decimalPad)
                }

                Toggle("Warm-up Set", isOn: $isWarmup)
                    .tint(AppColors.bluePrimary)
                    .padding(.vertical, 4)

                // MARK: - Actions
                HStack(spacing: 10) {
                    Button("Cancel") {
                        withAnimation(.spring()) { onDismiss() }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundStyle(.primary)
                    
                    Button {
                        saveExercise()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.bluePrimary.opacity(0.9))
                        .cornerRadius(12)
                        .foregroundStyle(.white)
                    }
                }

                // MARK: - Confirmation
                if showSaved {
                    SavedMessageView(message: "Exercise Added!")
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(10)
                }
            }
            .padding(25)
            .background(.ultraThinMaterial)
            .cornerRadius(60)
            .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
            .padding(.horizontal, 15)
            .transition(.scale.combined(with: .opacity))
        }
        .padding()
    }
    // MARK: - Reusable Text Field
    private struct SpotterTextField: View {
        var placeholder: String
        @Binding var text: String
        var systemImage: String

        init(_ placeholder: String, text: Binding<String>, systemImage: String) {
            self.placeholder = placeholder
            self._text = text
            self.systemImage = systemImage
        }

        var body: some View {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .foregroundStyle(.secondary)
                TextField(placeholder, text: $text)
                    .font(.subheadline)
                    .textInputAutocapitalization(.words)
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
    }
    // MARK: - Save
    private func saveExercise() {
        // Create or select exercise
        let exercise: ExerciseEntity
        if useCustomExercise {
            let newExercise = ExerciseEntity(context: context)
            newExercise.id = UUID()
            newExercise.name = customName
            newExercise.category = "custom"
            newExercise.modality = "strength"
            newExercise.createdAt = Date()
            exercise = newExercise
        } else if let selected = selectedExercise {
            exercise = selected
        } else {
            return
        }

        // Create sets
        for setIndex in 1...setsCount {
            let set = WorkoutSetEntity(context: context)
            set.id = UUID()
            set.setNumber = Int16(setIndex)
            set.reps = Int16(Int(reps) ?? 0)
            set.weightKG = Double(weight) ?? 0
            set.rir = Double(rir) ?? 0
            set.rpe = Double(rpe) ?? 0
            set.isWarmup = isWarmup
            set.completed = false
            set.createdAt = Date()
            set.exercise = exercise
            set.workout = workout
        }

        // Save
        do {
            try context.save()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showSaved = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showSaved = false
                    onDismiss()
                }
            }
        } catch {
            print("❌ Error saving exercise:", error.localizedDescription)
        }
    }
}


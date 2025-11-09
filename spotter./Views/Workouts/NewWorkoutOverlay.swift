//
//  NewWorkoutOverlay.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/31/25.
//

import SwiftUI
import CoreData

struct NewWorkoutOverlay: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var context
    var onDismiss: () -> Void
    
    @State private var title: String = ""
    @State private var type: String = "Strength"
    @State private var duration: String = ""
    @State private var energyLevel: Double = 5
    @State private var fatigue: Double = 5
    @State private var notes: String = ""
    @State private var date: Date = Date()
    @State private var showSaved = false
    @State private var showDatePicker = false
    @State private var selectedDate: Date = Date()

    // Exercise planning
    @State private var exercisePlans: [ExercisePlan] = []
    @State private var showAddExercise = false
    @State private var newExerciseName: String = ""
    
    let workoutTypes = ["Strength", "Cardio", "Mobility"]

    var body: some View {
        VStack{
            Button(action: { withAnimation(.spring()) { showDatePicker.toggle() } }) {
                Text(selectedDate.formatted(.dateTime.month(.abbreviated).day().year()))
                    .accentColor(.primary)
                    .font(.headline)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            }
            
            if showDatePicker {
                DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .cornerRadius(12)
                    .shadow(radius: 4)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
            VStack{
                
                // MARK: - Basic Fields
                
                VStack(spacing: 20) {
                    SpotterTextField("Title", text: $title, systemImage: "dumbbell.fill")
                    
                    Picker("Type", selection: $type) {
                        ForEach(workoutTypes, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                    
                    SpotterTextField("Duration (min)", text: $duration, systemImage: "clock.fill")
                        .keyboardType(.numberPad)
                    
                    VStack(alignment: .leading) {
                        Label("Energy Level: \(Int(energyLevel))", systemImage: "bolt.fill")
                            .font(.subheadline)
                        Slider(value: $energyLevel, in: 1...10, step: 1)
                            .tint(AppColors.bluePrimary)
                    }
                    
                    VStack(alignment: .leading) {
                        Label("Fatigue: \(Int(fatigue))", systemImage: "flame.fill")
                            .font(.subheadline)
                        Slider(value: $fatigue, in: 1...10, step: 1)
                            .tint(.orange)
                    }
                    
                    SpotterTextField("Notes", text: $notes, systemImage: "square.and.pencil")
                    
                    Divider().padding(.vertical, 8)
                
                }
                .padding(.horizontal, 20)
                
                // MARK: - Buttons
                HStack(spacing: 10) {
                    Button("Cancel") {
                        withAnimation(.spring()) { onDismiss() }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundStyle(.primary)
                    
                    Button {
                        saveWorkout()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.bluePrimary)
                        .cornerRadius(12)
                        .foregroundStyle(.white)
                    }
                }
                
                if showSaved {
                    SavedMessageView(message: "Workout Saved!")
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(10)
                }
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 40)
            .background(.primary.opacity(0.05))
            .cornerRadius(60)
            .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
            .padding(.horizontal, 15)
            .transition(.scale.combined(with: .opacity))
            .zIndex(5)
            
            // MARK: - Add Exercise Overlay
            if showAddExercise {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.spring()) { showAddExercise = false } }
                
                VStack(spacing: 15) {
                    Text("Add Exercise")
                        .font(.headline)
                        .foregroundStyle(AppColors.bluePrimary)
                    
                    TextField("Exercise Name", text: $newExerciseName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            withAnimation(.spring()) { showAddExercise = false }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                        
                        Button("Add") {
                            addExercise()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.bluePrimary)
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .disabled(newExerciseName.isEmpty)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(40)
                .shadow(radius: 10)
                .transition(.scale.combined(with: .opacity))
            }
            // MARK: - Exercises Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Exercises")
                        .font(.headline)
                    Spacer()
                    Button {
                        withAnimation(.spring()) { showAddExercise = true }
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .tint(.primary)
                    }
                }
                
                if !exercisePlans.isEmpty{
                    ForEach($exercisePlans) { $plan in
                        ExercisePlanCard(plan: $plan) {
                            exercisePlans.removeAll { $0.id == plan.id }
                        }
                    }
                }
            }.padding(.horizontal, 25)
                .padding(.vertical, 40)
                .background(.primary.opacity(0.05))
                .cornerRadius(60)
                .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
                .padding(.horizontal, 15)
                .transition(.scale.combined(with: .opacity))
                .zIndex(5)
        }
    }

    // MARK: - Save to Core Data
    private func saveWorkout() {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let newWorkout = WorkoutEntity(context: context)
        newWorkout.id = UUID()
        newWorkout.title = title
        newWorkout.type = type.lowercased()
        newWorkout.durationSec = Int32((Int(duration) ?? 0) * 60)
        newWorkout.energyLevel = Int16(energyLevel)
        newWorkout.perceivedFatigue = Int16(fatigue)
        newWorkout.notes = notes
        newWorkout.date = date
        newWorkout.status = "planned"
        newWorkout.createdAt = Date()
        newWorkout.updatedAt = Date()
        
        // Save exercises and sets
        for plan in exercisePlans {
            let exercise = ExerciseEntity(context: context)
            exercise.name = plan.exercise.name
            exercise.category = "strength"
            exercise.createdAt = Date()
            
            for s in plan.sets {
                let set = WorkoutSetEntity(context: context)
                set.id = UUID()
                set.setNumber = Int16(s.number)
                set.reps = Int16(s.reps)
                set.weightKG = s.weight
                set.createdAt = Date()
                set.exercise = exercise
                set.workout = newWorkout
            }
        }

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
            print("❌ Error saving workout:", error.localizedDescription)
        }
    }

    // MARK: - Add Exercise
    private func addExercise() {
        let exercise = ExerciseEntity(context: context)
        exercise.name = newExerciseName
        exercise.category = "strength"
        exercise.createdAt = Date()
        
        let plan = ExercisePlan(exercise: exercise)
        exercisePlans.append(plan)
        
        newExerciseName = ""
        withAnimation(.spring()) { showAddExercise = false }
    }
}

// MARK: - Helper Views (same as before)
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

struct SavedMessageView: View {
    var message: String

    var body: some View {
        Text(message)
            .font(.headline)
            .padding(.vertical, 8)
            .padding(.horizontal, 20)
            .background(.ultraThinMaterial)
            .cornerRadius(30)
            .shadow(radius: 5)
            .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Exercise Plan + Card
struct ExercisePlan: Identifiable, Equatable {
    let id = UUID()
    var exercise: ExerciseEntity
    var sets: [SetPlan] = [SetPlan(number: 1)]
}

struct SetPlan: Identifiable, Equatable {
    let id = UUID()
    var number: Int
    var reps: Int = 10
    var weight: Double = 50
    var isWarmup: Bool = false
}

struct ExercisePlanCard: View {
    @Binding var plan: ExercisePlan
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(plan.exercise.name)
                    .font(.headline)
                Spacer()
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash.fill")
                }
            }

            ForEach($plan.sets) { $set in
                HStack {
                    Stepper("Set \(set.number)", value: $set.number, in: 1...50)
                        .labelsHidden()
                    Stepper("\(set.reps) reps", value: $set.reps, in: 1...50)
                    Stepper("\(Int(set.weight)) kg", value: $set.weight, in: 0...300, step: 2.5)
                }
                .font(.caption)
                .padding(6)
                .background(.thinMaterial)
                .cornerRadius(10)
            }

            Button {
                plan.sets.append(SetPlan(number: plan.sets.count + 1))
            } label: {
                Label("Add Set", systemImage: "plus")
                    .font(.caption)
                    .foregroundColor(AppColors.bluePrimary)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 2, y: 1)
    }
}

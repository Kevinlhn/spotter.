//
//  WorkoutDetails.swift
//  spotter
//
//  Created by Kevin Hernandez-Nino on 11/9/25.
//

import SwiftUI
import CoreData

struct WorkoutDetails: View {
    @ObservedObject var workout: WorkoutEntity
    var onDismiss: () -> Void   // ✅ added

    @Environment(\.managedObjectContext) private var context
    @Environment(\.colorScheme) private var colorScheme

    @State private var showExercisePicker = false
    @State private var workoutName: String = ""
    @State private var notes: String = ""

    private var exercises: [ExerciseEntity] {
        (workout.exercises as? Set<ExerciseEntity>)?
            .sorted(by: { $0.createdAt ?? .now < $1.createdAt ?? .now }) ?? []
    }

    var body: some View {
        ZStack {
            SpotterBackground()

            VStack{
                ScrollView {
                    VStack{
                        nameSection
                        notesSection
                        Divider().opacity(0.2)

                        if exercises.isEmpty {
                            VStack(spacing: 8) {
                                Text("No exercises yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Add an exercise to start building your workout.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 60)
                        } else {
                            ForEach(exercises, id: \.id) { exercise in
                                ExerciseRow(exercise: exercise)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                addExerciseButton
                footerBar.padding()
            }
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerSheet(workout: workout)
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            workoutName = workout.name
            notes = workout.notes ?? ""
        }
    }

    // MARK: - Header Bar
    private var footerBar: some View {
        HStack {
            Button {
                withAnimation(.spring()) { onDismiss() }   // ✅ uses closure
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Close")
                }
                .font(.subheadline)
                .tint(.primary)
                .padding(.horizontal,20)
                .padding(.vertical,10)
                .background(Color.primary.opacity(0.25))
                .cornerRadius(50)
            }

            Spacer()

            Text(workout.date.formatted(.dateTime.month().day().year()))
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button {
                saveWorkout()
                withAnimation(.spring()) { onDismiss() }  // ✅ closes after saving
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save")
                }
                .font(.subheadline.bold())
                .padding(.horizontal,20)
                .padding(.vertical,10)
                .background(AppColors.bluePrimary)
                .foregroundColor(.white)
                .cornerRadius(50)
                .shadow(radius: 3, y: 2)
            }
        }
        .padding(5)
        .background(.ultraThickMaterial)
        .cornerRadius(50)
        .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
    }

    // MARK: - Name Section
    private var nameSection: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Workout")
                .font(.footnote)
            TextField("", text: $workoutName)
                .frame(minHeight: 30)
                .padding(12)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
        }
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .center, spacing: 8) {
            TextField("Notes", text: $notes)
                .frame(minHeight: 30)
                .padding(12)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                
        }
    }

    // MARK: - Add Exercise Button
    private var addExerciseButton: some View {
        Button {
            showExercisePicker = true
        } label: {
            Label("Add Exercise", systemImage: "plus.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.bluePrimary)
                .foregroundColor(.white)
                .cornerRadius(14)
                .shadow(radius: 4)
        }
        .padding(.horizontal)
    }

    // MARK: - Save Logic
    private func saveWorkout() {
        workout.name = workoutName.isEmpty ? "Untitled Workout" : workoutName
        workout.notes = notes
        try? context.save()
    }
}

#Preview {
    let ctx = Persistence.preview.container.viewContext
    let workout = WorkoutEntity(context: ctx)
    workout.id = UUID()
    workout.name = "Push Day"
    workout.date = Date()

    return WorkoutDetails(workout: workout, onDismiss: {})
        .environment(\.managedObjectContext, ctx)
        .preferredColorScheme(.dark)
}

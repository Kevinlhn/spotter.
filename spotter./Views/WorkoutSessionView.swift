//
//  WorkoutSessionView.swift
//  spotter.
//
//  Follow an active workout and log sets.
//

import SwiftUI
import CoreData

struct WorkoutSessionView: View {
    let workout: WorkoutEntity
    @ObservedObject var workoutVM: WorkoutViewModel
    let onEnd: () -> Void

    @StateObject private var exerciseVM = ExerciseViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                SpotterBackground()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    headerSection
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(exerciseVM.exercises, id: \.id) { exercise in
                                SessionExerciseCard(
                                    exercise: exercise,
                                    addSet: { ex, weight, reps in
                                        exerciseVM.addSet(to: ex, weight: weight, reps: reps)
                                    },
                                    deleteSet: { set in
                                        exerciseVM.deleteSet(set)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }

                    finishButton
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                }
            }
            .navigationTitle(workout.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        onEnd()
                    }
                }
            }
        }
        .onAppear {
            exerciseVM.load(for: workout)
        }
    }

    // MARK: - UI

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Active workout")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(workout.name)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var finishButton: some View {
        Button {
            workoutVM.updateStatus(for: workout, to: .completed)
            onEnd()
        } label: {
            Text("Finish workout")
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.bluePrimary)
                .foregroundColor(.white)
                .cornerRadius(18)
                .font(.headline)
        }
    }
}

// MARK: - Exercise card for session

private struct SessionExerciseCard: View {
    let exercise: ExerciseEntity
    let addSet: (ExerciseEntity, Double, Int16) -> Void
    let deleteSet: (WorkoutSetEntity) -> Void

    @State private var isExpanded: Bool = true
    @State private var repsText: String = ""
    @State private var weightText: String = ""

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.subheadline.weight(.medium))
                    if let mg = exercise.muscleGroup, !mg.isEmpty {
                        Text(mg)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)

            if isExpanded {
                let sets = exercise.sortedSets

                if !sets.isEmpty {
                    ForEach(sets, id: \.id) { set in
                        HStack {
                            Text("\(set.reps) reps")
                            Spacer()
                            Text("\(set.weight, specifier: "%.1f") lb")
                            Button(role: .destructive) {
                                deleteSet(set)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                            }
                        }
                        .font(.caption)
                        .padding(.horizontal, 10)
                    }
                }

                HStack {
                    TextField("Reps", text: $repsText)
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                    TextField("Weight", text: $weightText)
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                    Spacer()
                    Button {
                        guard
                            let reps = Int16(repsText),
                            let weight = Double(weightText)
                        else { return }

                        addSet(exercise, weight, reps)
                        repsText = ""
                        weightText = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                .padding(10)
            }
        }
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(18)
    }
}

#Preview {
    Text("WorkoutSessionView Preview")
}
//
//  WorkoutsView.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/29/25.
//
import SwiftUI
import CoreData

struct WorkoutsView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.date, order: .reverse)],
        animation: .easeInOut
    )
    private var workouts: FetchedResults<WorkoutEntity>
    @State private var showNewWorkout = false
       @State private var selectedWorkout: WorkoutEntity? = nil
    @State private var showLogger = false

    var body: some View {
            ZStack {
                SpotterBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        Text("workouts.")
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundStyle(AppColors.bluePrimary.gradient)
                            .padding(.top, 20)

                        ForEach(workouts, id: \.objectID) { workout in
                            WorkoutCardCD(workout: workout)
                                .onTapGesture { selectedWorkout = workout }
                        }

                        Button {
                            withAnimation(.spring()) { showNewWorkout = true }
                        } label: {
                            Label("New Workout", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(AppColors.bluePrimary)
                                .cornerRadius(20)
                        }
                        .padding(.top, 20)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 80)
                }

                // MARK: - Overlays
                if showNewWorkout {
                    
                    Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
                    
                    NewWorkoutOverlay(onDismiss: { showNewWorkout = false })
                        .environment(\.managedObjectContext, context)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(10)
                }

                if let workout = selectedWorkout {
                    Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
                    WorkoutDetailOverlay(workout: workout)
                    .environment(\.managedObjectContext, context)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(10)
                }
            }
        }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "dumbbell")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No workouts yet.")
                .font(.headline)
            Button("Create one") { createNewWorkout() }
                .buttonStyle(.borderedProminent)
        }
        .padding(.top, 80)
    }

    private var addButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button { createNewWorkout() } label: {
                    Image(systemName: "plus")
                        .font(.title)
                        .padding()
                        .background(AppColors.bluePrimary)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                .padding()
            }
        }
    }

    private func createNewWorkout() {
        let w = WorkoutEntity(context: context)
        w.id = UUID()
        w.title = "New Workout"
        w.type = "strength"
        w.date = Date()
        w.status = "planned"
        w.perceivedFatigue = 0
        w.energyLevel = 0
        w.durationSec = 0
        w.totalVolume = 0
        w.adherenceScore = 0
        w.createdAt = Date()
        w.updatedAt = Date()
        try? context.save()
    }
}

// Core Data card version
struct WorkoutCardCD: View {
    @ObservedObject var workout: WorkoutEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(workout.title)
                .font(.headline)
            Text(workout.type.capitalized)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack {
                Label("\(workout.sets?.count ?? 0) sets", systemImage: "flame.fill")
                Spacer()
                Label(workout.date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    return NewWorkoutOverlay(onDismiss: {})
        .environment(\.managedObjectContext, context)
}

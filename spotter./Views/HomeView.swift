//
//  HomeView.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 11/8/25.
//

import SwiftUI
import CoreData

struct HomeView: View {
    @StateObject private var viewModel = WorkoutViewModel()
    @State private var showNewWorkout = false
    @State private var selectedWorkout: WorkoutEntity? = nil
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            SpotterBackground()

            VStack {
                headerSection

                // MARK: - Workouts List
                if viewModel.workouts.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Text("No workouts yet.")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Start a new workout to begin tracking your progress.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.workouts, id: \.id) { workout in
                            WorkoutCard(workout: workout)
                                .listRowBackground(Color.clear)
                                .scrollContentBackground(.hidden)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets())
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        selectedWorkout = workout
                                    }
                                }
                        }
                        .onDelete(perform: deleteWorkout)
                    }
                    .listStyle(.plain)
                    .scrollIndicators(.hidden)
                    .padding()
                }

                addWorkoutButton.padding()
            }

            // MARK: - New Workout Overlay
            if showNewWorkout {
                VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring()) { showNewWorkout = false }
                    }

                NewWorkout(viewModel: viewModel) {
                    withAnimation(.spring()) { showNewWorkout = false }
                }
                .transition(.scale.combined(with: .opacity))
                .zIndex(10)
            }

            // MARK: - Workout Details Overlay
            if let workout = selectedWorkout {
                VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring()) { selectedWorkout = nil }
                    }

                WorkoutDetails(workout: workout) {
                    withAnimation(.spring()) { selectedWorkout = nil }
                }
                .transition(.scale.combined(with: .opacity))
                .zIndex(11)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showNewWorkout)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedWorkout)
    }

    // MARK: - Delete Function
    private func deleteWorkout(at offsets: IndexSet) {
        offsets.map { viewModel.workouts[$0] }.forEach(viewModel.deleteWorkout)
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: -5) {
            Text("built to keep you moving forward")
                .padding(.horizontal, 20)
                .padding(.vertical, 5)
                .background(AppColors.scheme(for: colorScheme).opacity(0.5))
                .cornerRadius(10)
                .font(.system(size: 8, weight: .thin))

            Text("spotter.")
                .font(.system(size: 50, weight: .heavy))
                .foregroundStyle(AppColors.bluePrimary.gradient)
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.top, 10)
    }

    // MARK: - Add Workout Button
    private var addWorkoutButton: some View {
        Button {
            withAnimation(.spring()) { showNewWorkout = true }
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Start New Workout")
                    .fontWeight(.semibold)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppColors.bluePrimary)
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(radius: 4)
        }
        .padding()
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, Persistence.preview.container.viewContext)
        .preferredColorScheme(.dark)
}

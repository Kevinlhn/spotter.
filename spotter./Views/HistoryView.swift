import SwiftUI
import CoreData

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Derived Data

    private var completedWorkouts: [WorkoutEntity] {
        viewModel.workouts.filter { $0.workoutStatus == .completed }
    }

    // Group completed workouts by day (most recent first)
    private var workoutsByDay: [(date: Date, workouts: [WorkoutEntity])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: completedWorkouts) { workout in
            calendar.startOfDay(for: workout.date)
        }

        return grouped
            .map { ($0.key, $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.0 > $1.0 }
    }

    // Simple stats
    private var totalCompleted: Int {
        completedWorkouts.count
    }

    private var totalVolume: Int {
        completedWorkouts.reduce(0) { total, workout in
            let exercises = (workout.exercises as? Set<ExerciseEntity>) ?? []
            let workoutVolume = exercises.reduce(0) { exTotal, exercise in
                let sets = (exercise.sets as? Set<WorkoutSetEntity>) ?? []
                return exTotal + sets.reduce(0) { $0 + Int($1.reps) * Int($1.weight) }
            }
            return total + workoutVolume
        }
    }

    private var totalSets: Int {
        completedWorkouts.reduce(0) { total, workout in
            let exercises = (workout.exercises as? Set<ExerciseEntity>) ?? []
            let setsCount = exercises.reduce(0) { exTotal, exercise in
                let sets = (exercise.sets as? Set<WorkoutSetEntity>) ?? []
                return exTotal + sets.count
            }
            return total + setsCount
        }
    }

    var body: some View {
        ZStack {
            SpotterBackground()

            VStack(spacing: 0) {
                headerSection
                    .padding(.bottom, 10)

                if completedWorkouts.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Text("No completed workouts yet.")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Finish a workout to see it show up here.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            statsSummaryCard

                            ForEach(workoutsByDay, id: \.date) { group in
                                sectionForDay(date: group.date, workouts: group.workouts)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadHistory()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: -5) {
            Text("every rep counts")
                .padding(.horizontal, 20)
                .padding(.vertical, 5)
                .background(AppColors.scheme(for: colorScheme).opacity(0.5))
                .cornerRadius(10)
                .font(.system(size: 10, weight: .thin))

            Text("history.")
                .font(.system(size: 40, weight: .heavy))
                .foregroundStyle(AppColors.bluePrimary.gradient)
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.top, 10)
    }

    // MARK: - Stats Card

    private var statsSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)
                .foregroundStyle(AppColors.bluePrimary)

            HStack(spacing: 16) {
                statPill(title: "Workouts", value: "\(totalCompleted)")
                statPill(title: "Sets", value: "\(totalSets)")
                statPill(title: "Volume", value: "\(totalVolume) lbs")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.scheme(for: colorScheme).opacity(0.4))
        .cornerRadius(14)
    }

    // MARK: - Day Section

    private func sectionForDay(date: Date, workouts: [WorkoutEntity]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(date, style: .date)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            ForEach(workouts, id: \.id) { workout in
                WorkoutCard(workout: workout)
            }
        }
    }
}

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, Persistence.preview.container.viewContext)
        .preferredColorScheme(.dark)
}
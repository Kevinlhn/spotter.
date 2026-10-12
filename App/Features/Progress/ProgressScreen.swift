import SwiftUI

struct ProgressScreen: View {
    @EnvironmentObject private var store: TrainingStore
    let onOpen: (WorkoutEntity) -> Void
    let onTrends: () -> Void
    @State private var range = TrainingProgress.Range.month
    @State private var explore = false
    @State private var recordExercise: TrainingMove?
    @AppStorage("spotter.weightUnit") private var unit = "lb"
    private var workouts: [WorkoutEntity] { TrainingProgress.filtered(store.completed, range: range) }
    private var sets: Int { workouts.reduce(0) { $0 + TrainingProgress.validSets($1).count } }
    private var records: [TrainingProgress.Record] { TrainingProgress.records(store.completed, since: range.start(), unit: unit) }
    var body: some View {
        FeaturePage {
            VStack(alignment: .leading, spacing: 8) {
                FeatureHeading(title: "Progress", subtitle: "See what your training is changing")
                Picker("Time range", selection: $range) { ForEach(TrainingProgress.Range.allCases) { Text($0.rawValue).tag($0) } }
                    .pickerStyle(.segmented).accessibilityIdentifier("progress-range")
            }
        } content: {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if workouts.isEmpty {
                        EmptyTrainingState(icon: "chart.xyaxis.line", title: "Your history starts with a session.", message: "Complete a workout or choose a wider time range.")
                    } else {
                        HStack {
                            metric("Sessions", value: "\(workouts.count)")
                            metric("Sets", value: "\(sets)")
                            metric("Active days", value: "\(Set(workouts.map { Calendar.current.startOfDay(for: $0.date) }).count)")
                        }.padding(16).spotterGlass(radius: 22)
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeading(title: "Your training rhythm")
                            Text(insight).font(.subheadline)
                            let minutes = workouts.compactMap { TrainingProgress.loggingMinutes($0) }
                            if !minutes.isEmpty {
                                Text("\((minutes.reduce(0, +) / Double(minutes.count)).formatted(.number.precision(.fractionLength(0)))) min average to last set").font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                            }
                        }.padding(16).spotterGlass(radius: 22)
                    }
                    Button(action: onTrends) { link("Exercise performance", detail: "Strength, best sets, and your next target", symbol: "chart.line.uptrend.xyaxis") }
                        .buttonStyle(SpotterPressStyle()).accessibilityIdentifier("exercise-trends")
                    Button { explore = true } label: { link("Workload & consistency", detail: "Volume, muscle groups, and frequency", symbol: "chart.bar") }
                        .buttonStyle(SpotterPressStyle()).accessibilityIdentifier("progress-workload")
                    if !records.isEmpty {
                        SectionHeading(title: "Recent weight records")
                        ForEach(records.prefix(3)) { record in
                            Button { recordExercise = TrainingMove(name: record.name, muscle: "") } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(record.name).font(.headline)
                                    Text("\(record.weight.formatted(.number.precision(.fractionLength(0...1)))) \(unit) × \(record.reps) · \(record.date.formatted(date: .abbreviated, time: .omitted))").font(.caption)
                                }.frame(maxWidth: .infinity, alignment: .leading).padding(16).spotterGlass(radius: 22)
                            }.buttonStyle(SpotterPressStyle())
                        }
                    }
                    SectionHeading(title: "Workout history", detail: "\(workouts.count) sessions")
                    ForEach(workouts) { workout in
                        Button { onOpen(workout) } label: { WorkoutListRow(workout: workout) }
                            .buttonStyle(SpotterPressStyle()).accessibilityIdentifier("history-\(workout.id)")
                    }
                }.padding(.horizontal, 20).padding(.bottom, 16)
            }.accessibilityIdentifier("workout-history")
        }
        .sheet(isPresented: $explore) { WorkloadProgressView(range: range) }
        .sheet(item: $recordExercise) { ExerciseProgressView(initialExercise: $0.name) }
    }
    private var insight: String {
        let weeks = TrainingProgress.weeks(store.completed)
        let recent = weeks.last?.count ?? 0
        let target = TrainingPreferences.load().sessionsPerWeek
        return "\(recent) of \(target) sessions toward your weekly goal. \(recent >= target ? "You’ve reached your weekly goal." : "\(max(0, target - recent)) more to reach your goal.")"
    }
    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) { Text(value).font(.title2.bold()).monospacedDigit(); Text(title).font(.caption).foregroundStyle(SpotterStyle.secondaryText) }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private func link(_ title: String, detail: String, symbol: String) -> some View {
        HStack { SpotterRowIcon(symbol: symbol); VStack(alignment: .leading, spacing: 4) { Text(title).font(.headline); Text(detail).font(.caption).foregroundStyle(SpotterStyle.secondaryText) }; Spacer(); SpotterChevron() }.padding(16).spotterGlass(radius: 22, interactive: true)
    }
}

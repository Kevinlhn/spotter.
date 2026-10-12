import SwiftUI
import Charts

struct ExerciseProgressView: View {
    @EnvironmentObject private var store: TrainingStore
    @Environment(\.dismiss) private var dismiss
    var initialExercise: String = ""
    @State private var exerciseName = ""
    @State private var range = TrainingProgress.Range.quarter
    @State private var unit = TrainingPreferences.load().weightUnit.rawValue
    @State private var selectedDate: Date?
    @AppStorage("spotter.progressMetric") private var metric = "load"
    private var names: [String] { Set(TrainingProgress.exerciseNames(store.completed) + (initialExercise.isEmpty ? [] : [initialExercise])).sorted() }
    private var all: [TrainingProgress.Session] { TrainingProgress.sessions(store.completed, name: exerciseName, unit: unit) }
    private var sessions: [TrainingProgress.Session] { all.filter { $0.date >= range.start() } }
    private var move: TrainingMove {
        let exercise = store.completed.flatMap(\.sortedExercises).first { ExerciseCatalog.key($0.name) == ExerciseCatalog.key(exerciseName) }
        return exercise.map(TrainingMove.init(exercise:)) ?? TrainingMove(name: exerciseName, muscle: "Other")
    }
    private var title: String { switch metric { case "volume": "External volume"; case "estimate": "Estimated 1RM"; case "reps": "Total reps"; case "sets": "Sets"; default: "Best weight" } }
    private var suffix: String { metric == "sets" || metric == "reps" ? metric : metric == "volume" ? "\(unit) · reps" : unit == "unspecified" ? "load" : unit }
    private var selected: TrainingProgress.Session? {
        guard let selectedDate else { return nil }
        return sessions.min { abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate)) }
    }
    var body: some View {
        NavigationStack {
            FeaturePage {
                VStack(spacing: 4) {
                    Picker("Exercise", selection: $exerciseName) { ForEach(names, id: \.self) { Text($0).tag($0) } }.accessibilityIdentifier("progress-exercise")
                    Picker("Time range", selection: $range) { ForEach(TrainingProgress.Range.allCases) { Text($0.rawValue).tag($0) } }
                }.frame(maxWidth: .infinity).spotterControl()
            } content: {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        if let latest = all.last, let best = latest.bestSet {
                            VStack(alignment: .leading, spacing: 6) {
                                SectionHeading(title: "Latest session", detail: latest.date.formatted(date: .abbreviated, time: .omitted))
                                Text("\(best.weight.formatted(.number.precision(.fractionLength(0...1)))) \(unit == "unspecified" ? "load" : unit) × \(best.reps)").font(.title2.bold())
                                Text("Best set · \(latest.sets.count) sets logged").font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                                if all.count > 1, let previous = all[all.count - 2].bestSet {
                                    Text("Previous best set: \(previous.weight.formatted(.number.precision(.fractionLength(0...1)))) × \(previous.reps)").font(.subheadline)
                                }
                                if let record = all.map(\.bestWeight).max() {
                                    Text("All-time best weight: \(record.formatted(.number.precision(.fractionLength(0...1)))) \(unit == "unspecified" ? "load" : unit)").font(.caption)
                                }
                            }.padding(16).spotterGlass(radius: 22)
                            Text(TrainingProgress.trend(all)).font(.subheadline)
                            let recommendation = store.recommendation(for: move, unit: unit)
                            VStack(alignment: .leading, spacing: 6) {
                                SectionHeading(title: "Next workout")
                                if let target = recommendation.suggested, let weight = target.weight {
                                    Text("\(weight.formatted()) \(unit) × \(target.repRange.lowerBound == target.repRange.upperBound ? String(target.repRange.lowerBound) : "\(target.repRange.lowerBound)–\(target.repRange.upperBound)") reps").font(.headline)
                                }
                                Text(recommendation.reason).font(.subheadline)
                            }.padding(16).spotterGlass(radius: 22)
                        } else {
                            EmptyTrainingState(icon: "chart.xyaxis.line", title: "Build your exercise history.", message: "Finish a workout with this exercise to see performance and recommendations.")
                        }
                        Picker("Recorded unit", selection: $unit) {
                            Text("Pounds (converted)").tag("lb"); Text("Kilograms (converted)").tag("kg")
                            Text("Unspecified only").tag("unspecified")
                        }.accessibilityIdentifier("progress-unit")
                        Picker("Measure", selection: $metric) {
                            Text("Best weight").tag("load"); Text("Estimated 1RM").tag("estimate"); Text("Volume").tag("volume")
                            Text("Total reps").tag("reps"); Text("Logged sets").tag("sets")
                        }.accessibilityIdentifier("progress-metric")
                        if !sessions.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionHeading(title: title, detail: suffix)
                                Chart(sessions) { session in
                                    if let value = session.value(metric: metric) {
                                        LineMark(x: .value("Session", session.date), y: .value(title, value)).foregroundStyle(SpotterStyle.strength)
                                        PointMark(x: .value("Session", session.date), y: .value(title, value)).foregroundStyle(SpotterStyle.strength)
                                    }
                                }.frame(height: 150).chartXSelection(value: $selectedDate)
                                if let selected, let value = selected.value(metric: metric) {
                                    Text("\(selected.date.formatted(date: .abbreviated, time: .omitted)): \(value.formatted(.number.precision(.fractionLength(0...1)))) \(suffix)").font(.caption).monospacedDigit()
                                }
                                Text(metric == "estimate" ? "Epley estimate from weighted sets of 1–12 reps; not a tested maximum. Bodyweight and higher-rep sets are excluded." : "Tap the chart to inspect a session. Known lb/kg loads are converted; unspecified records stay separate.").font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                            }.padding(16).spotterGlass(radius: 22)
                        } else { Text("No sessions in this range and unit.").font(.caption) }
                        SectionHeading(title: "Session results", detail: "\(sessions.count) sessions")
                        ForEach(sessions.reversed()) { session in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(session.date.formatted(date: .abbreviated, time: .omitted)).font(.headline)
                                Text("\(session.volume.formatted(.number.precision(.fractionLength(0)))) \(unit) · reps · \(session.reps) total reps").font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                                ForEach(Array(session.sets.enumerated()), id: \.offset) { index, set in
                                    Text("\(index + 1).  \(set.weight.formatted(.number.precision(.fractionLength(0...1)))) × \(set.reps)").monospacedDigit().font(.subheadline)
                                }
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(16).spotterGlass(radius: 22)
                        }
                    }.padding(.horizontal, 20).padding(.bottom, 16)
                }.accessibilityIdentifier("exercise-results")
            }.navigationTitle("Exercise performance").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
                .onAppear {
                    if !["load", "reps", "sets", "estimate", "volume"].contains(metric) { metric = "load" }
                    if exerciseName.isEmpty { exerciseName = names.contains(initialExercise) ? initialExercise : names.first ?? "" }
                }
                .onChange(of: exerciseName) { _, _ in selectedDate = nil }
                .onChange(of: range) { _, _ in selectedDate = nil }
        }
    }
}

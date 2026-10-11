import SwiftUI
import Charts

struct ExerciseProgressView: View {
    @EnvironmentObject private var store: TrainingStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var exerciseName = ""
    @State private var unit = "lb"
    @AppStorage("spotter.progressMetric") private var metric = "load"

    private var names: [String] { TrainingProgress.exerciseNames(store.completed) }
    private var units: [String] { TrainingProgress.units(store.completed, exerciseName: exerciseName) }
    private var points: [ExerciseProgressPoint] {
        TrainingProgress.points(store.completed, exerciseName: exerciseName, unit: unit, metric: metric)
    }
    private var metricLabel: String { metric == "reps" ? "Total reps" : metric == "sets" ? "Logged sets" : "Best weight" }
    private var suffix: String { metric == "load" ? (unit == "unspecified" ? "load" : unit) : metric }

    var body: some View {
        NavigationStack {
            FeaturePage {
                if !names.isEmpty { filters }
            } content: {
                if names.isEmpty {
                    CompactContent {
                        EmptyTrainingState(icon: "chart.xyaxis.line", title: "A little history goes a long way.", message: "Finish a workout with logged sets to explore exercise progress here.")
                            .padding(.horizontal, 20)
                    }
                } else if textSize.isAccessibilitySize {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 14) {
                            chart
                            resultsHeading
                            results
                        }.padding(.horizontal, 20).padding(.bottom, 16)
                    }.scrollBounceBehavior(.basedOnSize).accessibilityIdentifier("exercise-results")
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        chart.padding(.horizontal, 20)
                        resultsHeading.padding(.horizontal, 20)
                        ScrollView {
                            LazyVStack(spacing: 0) { results }
                                .padding(.horizontal, 20).padding(.bottom, 16)
                        }.scrollBounceBehavior(.basedOnSize).accessibilityIdentifier("exercise-results")
                    }
                }
            }
            .navigationTitle("Exercise trends").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .onAppear {
                if !["load", "reps", "sets"].contains(metric) { metric = "load" }
                if !names.contains(exerciseName) { exerciseName = names.first ?? "" }
                selectUnit()
            }
            .onChange(of: exerciseName) { _, _ in selectUnit() }
        }
    }

    private var filters: some View {
        VStack(spacing: 4) {
            Picker("Exercise", selection: $exerciseName) {
                ForEach(names, id: \.self) { Text($0).tag($0) }
            }.accessibilityIdentifier("progress-exercise")
            Picker("Measure", selection: $metric) {
                Text("Best weight").tag("load")
                Text("Total reps").tag("reps")
                Text("Logged sets").tag("sets")
            }.accessibilityIdentifier("progress-metric")
            if units.count > 1 {
                Picker("Recorded unit", selection: $unit) {
                    ForEach(units, id: \.self) { Text($0 == "unspecified" ? "Original unit unspecified" : $0).tag($0) }
                }.accessibilityIdentifier("progress-unit")
            }
        }.pickerStyle(.menu).font(.subheadline).frame(maxWidth: .infinity)
            .padding(.vertical, 6).spotterControl()
    }

    private var chart: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeading(title: metricLabel, detail: unit == "unspecified" ? "Unit unspecified" : unit)
            Chart(points) { point in
                LineMark(x: .value("Workout date", point.date), y: .value(metricLabel, point.value))
                    .foregroundStyle(SpotterStyle.strength)
                PointMark(x: .value("Workout date", point.date), y: .value(metricLabel, point.value))
                    .foregroundStyle(SpotterStyle.strength)
            }.frame(minHeight: 80, idealHeight: 130, maxHeight: 160)
            Text("Compared within the same recorded weight unit.").font(.caption).foregroundStyle(SpotterStyle.secondaryText)
        }.padding(16).spotterGlass(radius: 22)
    }

    private var resultsHeading: some View {
        SectionHeading(title: "Session results", detail: "\(points.count) sessions")
    }

    private var results: some View {
        ForEach(points.reversed()) { point in
            HStack(alignment: .firstTextBaseline) {
                Text(point.date.formatted(.dateTime.month(.abbreviated).day().year())).foregroundStyle(SpotterStyle.secondaryText)
                Spacer()
                Text("\(point.value.formatted()) \(suffix)").fontWeight(.semibold).monospacedDigit()
            }.font(.subheadline).padding(.vertical, 12)
            Divider().overlay(SpotterStyle.divider)
        }
    }

    private func selectUnit() { if !units.contains(unit) { unit = units.first ?? "lb" } }
}

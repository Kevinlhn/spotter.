import SwiftUI
import Charts

struct WorkloadProgressView: View {
    @EnvironmentObject private var store: TrainingStore
    @Environment(\.dismiss) private var dismiss
    @State var range: TrainingProgress.Range
    @State private var measure = "Volume"
    @AppStorage("spotter.weightUnit") private var unit = "lb"
    private var workouts: [WorkoutEntity] { TrainingProgress.filtered(store.completed, range: range) }
    var body: some View {
        NavigationStack {
            SpotterPage {
                Picker("Time range", selection: $range) { ForEach(TrainingProgress.Range.allCases) { Text($0.rawValue).tag($0) } }
                Picker("Measure", selection: $measure) { ForEach(["Volume", "Muscles", "Frequency"], id: \.self) { Text($0) } }.pickerStyle(.segmented)
                if workouts.isEmpty { Text("No completed sessions in this range.") }
                else if measure == "Volume" {
                    Text("\(TrainingProgress.volume(workouts, unit: unit).formatted(.number.precision(.fractionLength(0)))) \(unit) · reps").font(.title2.bold())
                    Text("Total external load × reps").foregroundStyle(SpotterStyle.secondaryText)
                    Chart(workouts.reversed()) { workout in
                        BarMark(x: .value("Session", workout.date), y: .value("Volume", TrainingProgress.volume([workout], unit: unit))).foregroundStyle(SpotterStyle.strength)
                    }.frame(height: 180)
                    Text("Known kg/lb loads are converted to \(unit). Bodyweight contributes zero external volume; unspecified units are excluded. Volume compares workload, not workout quality.").font(.caption)
                } else if measure == "Muscles" {
                    let groups = TrainingProgress.muscles(workouts)
                    Chart(groups) { group in BarMark(x: .value("Sets", group.sets), y: .value("Muscle", group.name)).foregroundStyle(SpotterStyle.strength) }.frame(height: max(120, Double(groups.count) * 32))
                    Text("Each set counts once toward its recorded primary muscle group. Secondary muscles aren’t estimated.").font(.caption)
                    ForEach(groups) { group in HStack { Text(group.name); Spacer(); Text("\(group.sets) sets").bold() } }
                } else {
                    let weeks = TrainingProgress.weeks(workouts)
                    Chart(weeks) { week in BarMark(x: .value("Week", week.date, unit: .weekOfYear), y: .value("Sessions", week.count)).foregroundStyle(SpotterStyle.strength) }.frame(height: 180)
                    Text("Weekly sessions shown for the last six weeks, limited to your chosen range.").font(.caption)
                    SectionHeading(title: "Exercise consistency")
                    ForEach(TrainingProgress.exerciseNames(workouts), id: \.self) { name in
                        HStack { Text(name); Spacer(); Text("\(workouts.filter { $0.sortedExercises.contains { ExerciseCatalog.key($0.name) == ExerciseCatalog.key(name) && !$0.sortedSets.isEmpty } }.count) sessions").font(.caption).monospacedDigit() }
                    }
                }
            }.navigationTitle("Workload").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

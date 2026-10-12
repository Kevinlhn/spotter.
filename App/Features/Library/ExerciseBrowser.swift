import SwiftUI

struct ExerciseBrowser: View {
    @EnvironmentObject private var store: TrainingStore
    @Binding var query: String
    let onSelect: ((TrainingMove) -> Void)?
    @State private var muscle = "All muscles"
    @State private var customOnly = false
    @State private var detail: TrainingMove?
    private var catalog: [TrainingMove] { ExerciseCatalog.moves(custom: store.library, workouts: store.workouts) }
    private var muscles: [String] { ["All muscles"] + Set(catalog.map(\.muscle)).sorted() }
    private var filtered: [TrainingMove] {
        catalog.filter { move in
            (query.isEmpty || move.name.localizedCaseInsensitiveContains(query) || move.muscle.localizedCaseInsensitiveContains(query)) &&
            (muscle == "All muscles" || move.muscle == muscle) &&
            (!customOnly || store.library.contains { $0.id == move.id && $0.isCustom })
        }
    }
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Exercise or muscle group", text: $query).autocorrectionDisabled().accessibilityIdentifier("exercise-search")
                if !query.isEmpty { Button { query = "" } label: { Image(systemName: "xmark.circle.fill").frame(minWidth: 44, minHeight: 44) }.accessibilityLabel("Clear search") }
            }.padding(.horizontal, 14).frame(minHeight: 48).spotterControl().padding(.horizontal, 20)
            HStack {
                Picker("Muscle group", selection: $muscle) { ForEach(muscles, id: \.self) { Text($0).tag($0) } }
                Spacer()
                Toggle("Custom", isOn: $customOnly).toggleStyle(.button)
            }.font(.caption).padding(.horizontal, 20)
            List {
                if filtered.isEmpty { Text("No matches. Try another filter or create an exercise.").foregroundStyle(SpotterStyle.secondaryText) }
                ForEach(filtered, id: \.name) { move in
                    Button { if let onSelect { onSelect(move) } else { detail = move } } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(move.name).font(.headline).foregroundStyle(SpotterStyle.text)
                                Text(move.muscle).font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                            }
                            Spacer()
                            Image(systemName: onSelect == nil ? "chevron.right" : "plus.circle").foregroundStyle(SpotterStyle.foregroundAccent)
                        }.padding(.vertical, 6).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
            }.scrollContentBackground(.hidden).scrollDismissesKeyboard(.interactively).accessibilityIdentifier("exercise-library-list")
        }
        .sheet(item: $detail) { ExerciseDetailView(move: $0) }
    }
}

struct ExerciseDetailView: View {
    @EnvironmentObject private var store: TrainingStore
    @Environment(\.dismiss) private var dismiss
    let move: TrainingMove
    @State private var edit = false
    @State private var trends = false
    private var custom: ExerciseTemplateEntity? { store.library.first { $0.id == move.id && $0.isCustom } }
    private var name: String { custom?.name ?? move.name }
    private var sessions: [WorkoutEntity] { store.completed.filter { $0.sortedExercises.contains { ExerciseCatalog.key($0.name) == ExerciseCatalog.key(name) && !$0.sortedSets.isEmpty } } }
    var body: some View {
        NavigationStack {
            SpotterPage {
                Text(name).font(.title2.bold())
                Text(custom?.primaryMuscle ?? move.muscle).foregroundStyle(SpotterStyle.secondaryText)
                Text(ExerciseGuidance.cue(for: name))
                Button("Performance & recommendations", systemImage: "chart.xyaxis.line") { trends = true }.frame(minHeight: 44)
                SectionHeading(title: "Recent sessions", detail: "\(sessions.count) total")
                if sessions.isEmpty { Text("Log this exercise in a completed workout to build your history.").foregroundStyle(SpotterStyle.secondaryText) }
                ForEach(sessions.prefix(5)) { workout in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(workout.date.formatted(date: .abbreviated, time: .omitted)).font(.subheadline.bold())
                        ForEach(workout.sortedExercises.filter { ExerciseCatalog.key($0.name) == ExerciseCatalog.key(name) }.flatMap(\.sortedSets)) { set in
                            Text("\(set.weight.formatted()) \(workout.weightUnit ?? "load") × \(set.reps)").monospacedDigit()
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(16).spotterGlass(radius: 22)
                }
                if custom != nil { Button("Edit custom exercise", systemImage: "pencil") { edit = true }.frame(minHeight: 44) }
            }.navigationTitle("Exercise").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
                .sheet(isPresented: $edit) { CustomExerciseEditor(existing: custom) { _ in } }
                .sheet(isPresented: $trends) { ExerciseProgressView(initialExercise: name) }
        }
    }
}

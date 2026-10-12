import SwiftUI

struct RoutineLibrary: View {
    @EnvironmentObject private var store: TrainingStore
    let onCreate: (TrainingDraft, WorkoutBuilderMode) -> Void
    @State private var query = ""
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                TextField("Search routines", text: $query).padding(14).spotterControl()
                Button { onCreate(TrainingDraft(), .template) } label: {
                    Label("Create routine", systemImage: "plus").frame(minHeight: 44)
                }.accessibilityIdentifier("build-workout")
                Button { onCreate(store.coachedDraft(), .template) } label: {
                    Label("Suggest a routine", systemImage: "sparkles").frame(minHeight: 44)
                }.accessibilityIdentifier("coached-routine")
                Text("Uses your Coaching settings and training history. Review before saving.").font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                SectionHeading(title: "Your routines", detail: "\(store.templates.count)")
                ForEach(store.templates.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }) { template in
                    Button { onCreate(TrainingDraft(workout: template), .template) } label: {
                        HStack {
                            SpotterRowIcon(symbol: "rectangle.stack")
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name).font(.headline)
                                Text("\(template.sortedExercises.count) exercises").font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                            }
                            Spacer(); SpotterChevron()
                        }.padding(16).spotterGlass(radius: 22, interactive: true)
                    }.buttonStyle(SpotterPressStyle()).accessibilityIdentifier("template-\(template.id)")
                }
                if store.templates.isEmpty {
                    Text("Save a routine to repeat it, train now, or schedule a fresh copy.").font(.subheadline).foregroundStyle(SpotterStyle.secondaryText)
                }
                SectionHeading(title: "Start with a routine")
                ForEach(TrainingRoutine.starters.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) || $0.equipment.localizedCaseInsensitiveContains(query) }) { routine in
                    Button { onCreate(TrainingDraft(routine: routine), .template) } label: { RoutineRow(routine: routine) }
                        .buttonStyle(SpotterPressStyle()).accessibilityIdentifier("routine-\(routine.id)")
                }
            }.padding(.horizontal, 20).padding(.bottom, 16)
        }.scrollDismissesKeyboard(.interactively)
    }
}

struct RoutineRow: View {
    let routine: TrainingRoutine
    var body: some View {
        HStack(spacing: 12) {
            SpotterRowIcon(symbol: routine.symbol)
            VStack(alignment: .leading, spacing: 5) {
                Text(routine.name).font(.headline).foregroundStyle(SpotterStyle.text)
                Text("\(routine.equipment) · \(routine.moves.count) exercises").font(.caption).foregroundStyle(SpotterStyle.secondaryText)
            }
            Spacer(minLength: 8); SpotterChevron()
        }.padding(16).spotterGlass(radius: 22, interactive: true).contentShape(Rectangle())
    }
}

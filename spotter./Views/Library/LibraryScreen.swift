import SwiftUI

struct LibraryScreen: View {
    @EnvironmentObject private var store: TrainingStore
    let onCreate: (TrainingDraft, WorkoutBuilderMode) -> Void
    @State private var showExercises = false
    @Binding var query: String

    var body: some View {
        FeaturePage {
            HStack {
                FeatureHeading(title: "Library", subtitle: "Reusable workouts and exercises")
                Button { onCreate(TrainingDraft(), .template) } label: {
                    Image(systemName: "plus").font(.body.weight(.semibold)).frame(width: 44, height: 44)
                        .spotterGlass(radius: 22, interactive: true)
                }.buttonStyle(SpotterPressStyle()).accessibilityLabel("Create saved workout").accessibilityIdentifier("build-workout")
            }
        } content: {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(SpotterStyle.secondaryText).accessibilityHidden(true)
                    TextField("Search workouts", text: $query)
                        .autocorrectionDisabled().submitLabel(.search)
                        .accessibilityIdentifier("workout-search")
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(SpotterStyle.secondaryText).frame(width: 44, height: 44)
                        }.buttonStyle(SpotterPressStyle()).accessibilityLabel("Clear search")
                    }
                }.font(.subheadline).padding(.leading, 14).padding(.trailing, query.isEmpty ? 14 : 0)
                    .frame(minHeight: 48).spotterControl().padding(.horizontal, 20)
                Button { showExercises = true } label: {
                    HStack(spacing: 10) { Label("Exercise library", systemImage: "figure.strengthtraining.traditional"); Spacer(); SpotterChevron() }
                        .font(.subheadline.weight(.semibold)).padding(14).spotterControl().contentShape(Rectangle())
                }.buttonStyle(SpotterPressStyle()).padding(.horizontal, 20)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        let saved = store.templates.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }
                        SectionHeading(title: "Saved workouts", detail: "\(store.templates.count)")
                        if saved.isEmpty {
                            Text(query.isEmpty ? "Save a workout here to use it anytime. Dates belong in Plan." : "No saved workouts match your search.")
                                .font(.subheadline).foregroundStyle(SpotterStyle.secondaryText).padding(.bottom, 8)
                        }
                        ForEach(saved) { template in
                            Button { onCreate(TrainingDraft(workout: template), .template) } label: {
                                HStack(spacing: 12) {
                                    SpotterRowIcon(symbol: "rectangle.stack")
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(template.name).font(.headline).foregroundStyle(SpotterStyle.text)
                                        Text("\(template.sortedExercises.count) exercises").font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                                    }
                                    Spacer(minLength: 8); SpotterChevron()
                                }.padding(16).spotterGlass(radius: 22, interactive: true).contentShape(Rectangle())
                            }.buttonStyle(SpotterPressStyle()).accessibilityIdentifier("template-\(template.id)")
                        }
                        SectionHeading(title: "Starter routines").padding(.top, 8)
                        ForEach(TrainingRoutine.starters.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) || $0.equipment.localizedCaseInsensitiveContains(query) }) { routine in
                            Button { onCreate(TrainingDraft(routine: routine), .workout) } label: { RoutineRow(routine: routine) }
                                .buttonStyle(SpotterPressStyle()).accessibilityIdentifier("routine-\(routine.id)")
                        }
                    }.padding(.horizontal, 20).padding(.bottom, 16)
                }.scrollBounceBehavior(.basedOnSize).scrollDismissesKeyboard(.interactively).accessibilityIdentifier("library-list")
            }
        }
        .sheet(isPresented: $showExercises) { MoveLibrary(onSelect: nil) }
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

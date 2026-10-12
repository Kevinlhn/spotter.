import SwiftUI

enum WorkoutBuilderMode: String, CaseIterable, Identifiable {
    case workout, plan, template
    var id: String { rawValue }
    var label: String {
        switch self { case .workout: "Train now"; case .plan: "Plan"; case .template: "Save workout" }
    }
}

struct WorkoutBuilder: View {
    @EnvironmentObject private var store: TrainingStore
    @Environment(\.dismiss) private var dismiss
    @State var draft: TrainingDraft
    @State var mode: WorkoutBuilderMode = .workout
    var onStart: (WorkoutEntity) -> Void
    @State private var showLibrary = false
    @State private var showDelete = false
    @State private var moveToConfigure: TrainingMove?
    @State private var savedCopy = false
    private var canSave: Bool { !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !draft.moves.isEmpty }
    private var primaryTitle: String {
        switch mode { case .workout: "Start workout"; case .plan: "Save plan"; case .template: "Save workout" }
    }

    var body: some View {
        NavigationStack {
            FeaturePage {
                VStack(alignment: .leading, spacing: 8) {
                    if draft.existing == nil {
                        Picker("Workout destination", selection: $mode) {
                            ForEach(WorkoutBuilderMode.allCases) { Text($0.label).tag($0) }
                        }.pickerStyle(.segmented).accessibilityIdentifier("workout-destination")
                    }
                    Text(mode == .template ? "A reusable routine in Plan. Schedule a fresh copy whenever you train." : mode == .plan ? "Assign this workout to a day. You can change it later." : "Review your lineup, then start logging.")
                        .font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                }
            } content: {
                List {
                    Section("Workout") {
                        TextField("Name your workout", text: $draft.name).font(.headline).accessibilityIdentifier("workout-name")
                        if draft.existing == nil {
                            Picker("Weight unit", selection: $draft.weightUnit) {
                                Text("Pounds (lb)").tag(Optional("lb"))
                                Text("Kilograms (kg)").tag(Optional("kg"))
                                if draft.weightUnit == nil { Text("Original unit unspecified").tag(String?.none) }
                            }
                        }
                        TextField("Note (optional)", text: $draft.notes, axis: .vertical).lineLimit(1...3)
                        if mode == .plan {
                            DatePicker("Train on", selection: $draft.date, displayedComponents: [.date, .hourAndMinute])
                                .accessibilityIdentifier("planned-date")
                        }
                    }
                    Section {
                        ForEach(Array(draft.moves.enumerated()), id: \.element.id) { index, move in
                            VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 10) {
                                Text("\(index + 1)").font(.caption.monospaced()).foregroundStyle(SpotterStyle.secondaryText)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(move.name).font(.headline)
                                    Text("\(move.targetSets) sets · \(move.targetReps) reps · \(move.muscle)").font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                                }
                                Spacer(minLength: 0)
                                Menu {
                                    Menu("Substitute exercise") {
                                        ForEach(store.coachingChoices(for: move.muscle).filter { ExerciseCatalog.key($0.name) != ExerciseCatalog.key(move.name) }.prefix(6)) { candidate in
                                            Button(candidate.name) {
                                                guard let position = draft.moves.firstIndex(where: { $0.id == move.id }) else { return }
                                                draft.moves[position].name = candidate.name
                                                draft.moves[position].muscle = candidate.muscle
                                                draft.moves[position].targetWeight = nil
                                            }
                                        }
                                    }
                                    Button("Sets, reps & rest", systemImage: "slider.horizontal.3") { moveToConfigure = move }
                                    if index > 0 { Button("Move up", systemImage: "arrow.up") { draft.moves.swapAt(index, index - 1) } }
                                    if index + 1 < draft.moves.count { Button("Move down", systemImage: "arrow.down") { draft.moves.swapAt(index, index + 1) } }
                                    Button("Remove exercise", systemImage: "trash", role: .destructive) { draft.moves.removeAll { $0.id == move.id } }
                                } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44) }
                                    .accessibilityLabel("Options for \(move.name)")
                            }
                            if let weight = move.targetWeight {
                                Text("Planned: \(weight.formatted()) \(draft.weightUnit ?? "load") · \(move.repRange.lowerBound)–\(move.repRange.upperBound) reps")
                                    .font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                            }
                            OverloadSuggestion(recommendation: store.recommendation(for: move, unit: draft.weightUnit), unit: draft.weightUnit) { suggestion in
                                guard let position = draft.moves.firstIndex(where: { $0.id == move.id }) else { return }
                                draft.moves[position].targetSets = suggestion.sets
                                draft.moves[position].targetWeight = suggestion.weight
                                draft.moves[position].targetReps = suggestion.repRange.upperBound
                                draft.moves[position].targetRepMinimum = suggestion.repRange.lowerBound
                            }
                            }
                        }.onMove { draft.moves.move(fromOffsets: $0, toOffset: $1) }
                        Button { showLibrary = true } label: { Label("Add exercise", systemImage: "plus") }
                    } header: {
                        Text("Lineup · \(draft.moves.count) exercises")
                    } footer: {
                        Text("Use an exercise’s menu to adjust sets, reps, rest, or order.")
                    }
                    if mode == .template, draft.existing != nil {
                        Section("Use this workout") {
                            Button("Start a copy", systemImage: "play.fill") {
                                if let workout = store.save(independentDraft(), start: true) { onStart(workout) }
                            }.disabled(store.active != nil)
                            Button("Plan a copy", systemImage: "calendar.badge.plus") { draft = independentDraft(); mode = .plan }
                            Button("Duplicate routine", systemImage: "plus.rectangle.on.rectangle") {
                                draft = independentDraft(); draft.name += " copy"
                            }
                        }
                    }
                    if mode != .template, canSave {
                        Section {
                            Button("Save as reusable routine", systemImage: "bookmark") {
                                if store.saveTemplate(independentDraft()) != nil { savedCopy = true }
                            }
                        }
                    }
                    if draft.existing != nil {
                        Section { Button(mode == .template ? "Delete saved workout" : "Delete planned workout", role: .destructive) { showDelete = true } }
                    }
                }
                .scrollContentBackground(.hidden).scrollDismissesKeyboard(.interactively)
                .accessibilityIdentifier("workout-editor-list")
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 6) {
                    PrimaryAction(title: primaryTitle, icon: mode == .workout ? "play.fill" : "checkmark", action: save)
                        .disabled(!canSave || (mode == .workout && store.active != nil))
                        .accessibilityIdentifier("workout-primary-action")
                    if store.active != nil && mode == .workout {
                        Text("Resume your current session from Today, or save this workout for later.").font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                    }
                    if mode == .plan, draft.existing != nil {
                        Button("Start workout now") {
                            if let workout = store.save(draft, start: true) { onStart(workout) }
                        }.font(.subheadline.weight(.semibold)).frame(minHeight: 44).disabled(!canSave || store.active != nil)
                    }
                }.padding(.horizontal, 20).padding(.vertical, 8).background(.regularMaterial)
            }
            .navigationTitle(mode == .template ? "Saved workout" : mode == .plan ? "Plan workout" : "Your workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .sheet(isPresented: $showLibrary) {
                MoveLibrary { move in
                    var copy = move; copy.id = UUID(); draft.moves.append(copy)
                }
            }
            .sheet(item: $moveToConfigure) { move in
                MoveTargetsEditor(move: move, weightUnit: draft.weightUnit) { edited in
                    guard let index = draft.moves.firstIndex(where: { $0.id == edited.id }) else { return false }
                    draft.moves[index] = edited; return true
                }
            }
            .confirmationDialog("Delete this \(mode == .template ? "saved workout" : "plan")?", isPresented: $showDelete, titleVisibility: .visible) {
                Button("Delete workout", role: .destructive) { if let workout = draft.existing, store.delete(workout) { dismiss() } }
            }
            .alert("Routine saved in Plan", isPresented: $savedCopy) { Button("OK") {} } message: { Text("Your reusable copy is ready. This workout is unchanged.") }
            .alert("Couldn’t save", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                Button("OK") { store.error = nil }
            } message: { Text(store.error ?? "") }
        }
    }

    private func save() {
        switch mode {
        case .workout: if let workout = store.save(draft, start: true) { onStart(workout) }
        case .plan: if store.save(draft, start: false) != nil { dismiss() }
        case .template: if store.saveTemplate(draft) != nil { dismiss() }
        }
    }
    private func independentDraft() -> TrainingDraft {
        var copy = draft; copy.existing = nil; copy.date = Date()
        copy.moves = draft.moves.map { move in var fresh = move; fresh.id = UUID(); return fresh }
        return copy
    }
}

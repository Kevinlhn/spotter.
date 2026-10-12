import SwiftUI

struct TrainingSession: View {
    @EnvironmentObject private var store: TrainingStore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workout: WorkoutEntity
    private var selectedID: UUID? {
        get { workout.sessionState.exerciseID }
        nonmutating set { if let newValue { store.selectExercise(newValue, workout: workout) } }
    }
    @State private var weight = ""
    @State private var reps = "8"
    @State private var showLibrary = false
    @State private var showFinish = false
    @State private var showDiscard = false
    @State private var showTargets = false
    @State private var showGuide = false
    @State private var finished = false
    @State private var editingSet: WorkoutSetEntity?
    @AppStorage("spotter.weightStep") private var weightStep = 2.5
    private var restUntil: Double {
        get { workout.sessionState.restUntil }
        nonmutating set { store.setRest(workout: workout, until: newValue) }
    }
    @FocusState private var enteringSet: Bool
    @ScaledMetric(relativeTo: .body) private var minimumListHeight: CGFloat = 80
    @State private var controlsHeight: CGFloat = 0

    private var exercise: ExerciseEntity? { workout.sortedExercises.first { $0.id == selectedID } ?? workout.sortedExercises.first }
    private var setCount: Int { workout.sortedExercises.reduce(0) { $0 + $1.sortedSets.count } }
    private var parsedWeight: Double? { weight.isEmpty ? 0 : Double(weight.replacingOccurrences(of: ",", with: ".")) }
    private var validEntry: Bool { (parsedWeight?.isFinite == true) && (parsedWeight ?? -1) >= 0 && (1...999).contains(Int(reps) ?? 0) }
    private var nextExercise: ExerciseEntity? {
        guard let exercise, let index = workout.sortedExercises.firstIndex(where: { $0.id == exercise.id }),
              index + 1 < workout.sortedExercises.count else { return nil }
        return workout.sortedExercises[index + 1]
    }

    var body: some View {
        NavigationStack {
            Group {
                if finished { completion }
                else { session }
            }
        }
        .alert("Couldn’t save", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
            Button("OK") { store.error = nil }
        } message: { Text(store.error ?? "") }
    }

    private var session: some View {
        FeaturePage {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(workout.name).font(.headline).lineLimit(2)
                    Spacer(minLength: 8)
                    Text("\(setCount) sets saved").font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                }
                exercisePicker
            }
        } content: {
            if let exercise {
                // Keep the same input views mounted as the keyboard changes available height.
                // A fitting logger stays still while sets scroll; short content regions can scroll too.
                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: 12) {
                            VStack(spacing: 12) {
                                entryControls(for: exercise)
                                RestCountdown(until: Binding(get: { restUntil }, set: { restUntil = $0 }))
                            }
                            .fixedSize(horizontal: false, vertical: true)
                            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { controlsHeight = $0 }
                            loggedSets(for: exercise)
                                .frame(height: max(minimumListHeight, geometry.size.height - controlsHeight - 24))
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .scrollBounceBehavior(.basedOnSize)
                }
                .padding(.horizontal, 20).padding(.bottom, 12)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("Save & close") { dismiss() } }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Finish") { enteringSet = false; showFinish = true }
                    .disabled(setCount == 0).accessibilityLabel("Finish workout")
                Button { showDiscard = true } label: { Image(systemName: "trash") }
                    .accessibilityLabel("Discard workout")
            }
            ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { enteringSet = false } }
        }
        .confirmationDialog("Finish this session?", isPresented: $showFinish, titleVisibility: .visible) {
            Button("Finish & save") {
                if store.finish(workout) { finished = true }
            }
        } message: { Text("Your \(setCount) logged sets will be saved in Progress.") }
        .confirmationDialog("Discard this workout and its logged sets?", isPresented: $showDiscard, titleVisibility: .visible) {
            Button("Discard workout", role: .destructive) {
                if store.delete(workout) { dismiss() }
            }
        }
        .sheet(isPresented: $showLibrary) {
            MoveLibrary { store.addMove($0, to: workout); selectedID = workout.sortedExercises.last?.id; prefill() }
        }
        .sheet(item: $editingSet) { SetEditor(set: $0) }
        .sheet(isPresented: $showTargets) {
            if let exercise {
                MoveTargetsEditor(move: TrainingMove(exercise: exercise), weightUnit: workout.weightUnit) { move in
                    let saved = store.updateExerciseTargets(exercise, sets: move.targetSets, reps: move.targetReps, restSeconds: move.restSeconds, minimumReps: move.targetRepMinimum, targetWeight: move.targetWeight)
                    if saved { reps = String(move.targetReps) }
                    return saved
                }
            }
        }
        .sheet(isPresented: $showGuide) { exerciseGuide }
        .onAppear { prefill() }
        .onChange(of: selectedID) { _, _ in enteringSet = false; prefill() }
        .onChange(of: workout.sessionState) { old, new in
            // A saved set/recommendation refresh must not replace a partially typed draft.
            if old.exerciseID != new.exerciseID || old.selectedSetID != new.selectedSetID ||
                old.weight != new.weight || old.reps != new.reps { prefill() }
        }
        .onChange(of: weight) { _, _ in saveEntry() }
        .onChange(of: reps) { _, _ in saveEntry() }
    }

    private var exercisePicker: some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(Array(workout.sortedExercises.enumerated()), id: \.element.id) { index, move in
                    Button { selectedID = move.id } label: {
                        Label("\(index + 1). \(move.name)", systemImage: exercise?.id == move.id ? "checkmark.circle.fill" : "circle")
                    }
                }
                Divider().overlay(SpotterStyle.divider)
                Button("Add another exercise", systemImage: "plus") { showLibrary = true }
            } label: {
                HStack(spacing: 8) {
                    Text(exercise?.name ?? "Choose exercise").font(.headline).lineLimit(2)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.down").font(.caption.bold())
                }.padding(12).frame(maxWidth: .infinity, alignment: .leading).spotterControl(radius: 16)
            }.buttonStyle(.plain).accessibilityLabel("Choose exercise").accessibilityValue(exercise?.name ?? "")
            if let nextExercise {
                Button { selectedID = nextExercise.id } label: {
                    Image(systemName: "arrow.right").frame(width: 44, height: 44).spotterControl(radius: 16)
                }.buttonStyle(.plain).accessibilityLabel("Next: \(nextExercise.name)")
            }
        }
    }

    private func entryControls(for exercise: ExerciseEntity) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(exercise.sortedSets.count) of \(exercise.plannedSets) sets · target \(exercise.plannedReps) reps")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(SpotterStyle.foregroundAccent)
                    if let previous = store.previousSet(for: exercise) {
                        Text("Last time: \(previous.weight.formatted()) \(workout.weightLabel) × \(previous.reps) reps")
                            .font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                    }
                }
                Spacer(minLength: 4)
                Button { showGuide = true } label: { Image(systemName: "info.circle").frame(width: 44, height: 44) }
                    .accessibilityLabel("Exercise guide")
                Button { showTargets = true } label: { Image(systemName: "slider.horizontal.3").frame(width: 44, height: 44) }
                    .accessibilityLabel("Exercise targets")
            }
            Surface {
                VStack(spacing: 12) {
                    if workout.sessionState.selectedSetID == nil {
                        OverloadSuggestion(recommendation: store.recommendation(for: TrainingMove(exercise: exercise), unit: workout.weightUnit, current: exercise), unit: workout.weightUnit, entryWeight: parsedWeight, entryReps: Int(reps)) { suggestion in
                            store.setEntry(workout: workout, weight: suggestion.weight ?? workout.sessionState.weight,
                                           reps: suggestion.repRange.lowerBound)
                            prefill()
                        }
                    }
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 20) { weightInput; repsInput(for: exercise) }
                        VStack(alignment: .leading, spacing: 16) { weightInput; repsInput(for: exercise) }
                    }
                    PrimaryAction(title: workout.sessionState.selectedSetID == nil ? "Log set \(exercise.sortedSets.count + 1)" : "Save set changes", icon: "checkmark") {
                        enteringSet = false
                        if let load = parsedWeight, let count = Int(reps) {
                            store.setEntry(workout: workout, weight: load, reps: count)
                            store.performWorkoutAction(.complete, workout: workout, expectedRevision: workout.sessionState.revision)
                        }
                    }.disabled(!validEntry).opacity(validEntry ? 1 : 0.4).accessibilityIdentifier("log-set")
                    Text(workout.weightUnit == nil ? "No unit recorded. Keep using this workout’s original unit." : "Use 0 for bodyweight.")
                        .font(.caption).foregroundStyle(SpotterStyle.secondaryText).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var weightInput: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(workout.weightUnit.map { "Weight (\($0))" } ?? "Weight").font(.caption.weight(.semibold)).foregroundStyle(SpotterStyle.secondaryText)
            TextField("0", text: $weight).keyboardType(.decimalPad)
                .font(.system(.title, design: .rounded).bold()).focused($enteringSet)
                .accessibilityLabel("Set weight").accessibilityIdentifier("set-weight")
            Stepper("Weight", value: Binding(get: { parsedWeight ?? 0 }, set: { weight = String($0) }), in: 0...10000, step: EquipmentLoadStep.value(name: exercise?.name ?? "", unit: workout.weightUnit, preferred: weightStep))
                .labelsHidden().accessibilityLabel("Adjust weight")
                .accessibilityValue("\((parsedWeight ?? 0).formatted()) \(workout.weightLabel)")
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func repsInput(for exercise: ExerciseEntity) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Reps").font(.caption.weight(.semibold)).foregroundStyle(SpotterStyle.secondaryText)
            TextField("8", text: $reps).keyboardType(.numberPad)
                .font(.system(.title, design: .rounded).bold()).focused($enteringSet)
                .accessibilityLabel("Set reps").accessibilityIdentifier("set-reps")
            Stepper("Reps", value: Binding(get: { Int(reps) ?? exercise.plannedReps }, set: { reps = String($0) }), in: 1...999)
                .labelsHidden().accessibilityLabel("Adjust reps").accessibilityValue(reps)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private var loggedSetHeading: some View {
        HStack {
            Text("Logged sets").font(.headline)
            Spacer()
            Text("Tap to edit").font(.caption).foregroundStyle(SpotterStyle.secondaryText)
        }.accessibilityAddTraits(.isHeader)
    }

    private func loggedSets(for exercise: ExerciseEntity) -> some View {
        VStack(spacing: 4) {
            loggedSetHeading
            ScrollView {
                setRows(for: exercise)
            }.scrollBounceBehavior(.basedOnSize)
        }
    }

    private func setRows(for exercise: ExerciseEntity) -> some View {
        LazyVStack(spacing: 2) {
            if exercise.sortedSets.isEmpty {
                Text("Your logged sets will appear here.").font(.subheadline).foregroundStyle(SpotterStyle.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 12)
            }
            ForEach(Array(exercise.sortedSets.enumerated()), id: \.element.id) { index, set in
                HStack {
                    Button { editingSet = set } label: {
                        HStack {
                            Text("\(index + 1)").font(.system(.subheadline, design: .monospaced)).foregroundStyle(SpotterStyle.secondaryText)
                            Spacer()
                            Text("\(set.weight.formatted()) \(workout.weightLabel) × \(set.reps) reps").font(.headline)
                            Spacer()
                            Image(systemName: "pencil").foregroundStyle(SpotterStyle.secondaryText)
                        }.padding(.vertical, 12).contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityLabel("Edit set \(index + 1), \(set.weight.formatted()) \(workout.weightLabel), \(set.reps) reps")
                    Button { store.deleteSet(set) } label: { Image(systemName: "minus.circle").frame(width: 44, height: 44) }
                        .accessibilityLabel("Delete set \(index + 1)")
                }
            }
        }
    }

    private var exerciseGuide: some View {
        NavigationStack {
            SpotterPage {
                if let exercise {
                    FeatureHeading(title: exercise.name, subtitle: exercise.muscleGroup ?? "Exercise guide")
                    Text(ExerciseGuidance.cue(for: exercise.name))
                    Text("A starting point: 2–3 sets of 8–12 reps. Adjust the weight and repetitions to your ability.")
                        .foregroundStyle(SpotterStyle.secondaryText)
                }
            }.navigationTitle("Exercise guide").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showGuide = false } } }
        }.presentationDetents([.medium, .large])
    }

    private var completion: some View {
        FeaturePage { FeatureHeading(title: "You showed up.", subtitle: "SESSION COMPLETE") } content: {
            CompactContent {
                VStack(alignment: .leading, spacing: 20) {
                    Surface {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(workout.name).font(.title2.bold())
                            Text("\(setCount) sets logged · \(workout.sortedExercises.filter { !$0.sortedSets.isEmpty }.count) exercises trained")
                                .foregroundStyle(SpotterStyle.secondaryText)
                            Text("Your workout is saved in Progress.").font(.subheadline).foregroundStyle(SpotterStyle.secondaryText)
                        }
                    }
                    PrimaryAction(title: "Back to my day", icon: "checkmark") { dismiss() }
                }.padding(20)
            }
        }
    }

    private func prefill() {
        guard exercise != nil else { return }
        let state = workout.sessionState
        if parsedWeight != state.weight { weight = String(state.weight) }
        if Int(reps) != state.reps { reps = String(state.reps) }
    }
    private func saveEntry() {
        if let load = parsedWeight, let count = Int(reps), validEntry {
            store.setEntry(workout: workout, weight: load, reps: count)
        }
    }
}

import SwiftUI

private enum WatchStyle {
    static let accent = Color(red: 157 / 255, green: 180 / 255, blue: 200 / 255)
    static let text = Color(red: 244 / 255, green: 241 / 255, blue: 238 / 255)
    static let secondary = Color(red: 175 / 255, green: 168 / 255, blue: 164 / 255)
}

/// Every screen fits the viewport. The Crown edits a value; it never scrolls this flow.
struct WatchWorkoutView: View {
    @ObservedObject var store: WatchWorkoutStore
    @State private var page = 0
    @State private var editor: WatchWorkoutSnapshot?
    @State private var showMessage = false
    var body: some View {
        GeometryReader { geometry in
            Group {
                if let editor {
                    WatchTargetEditor(store: store, basis: editor) { self.editor = nil }
                } else if let workout = store.envelope?.workout {
                    if page == 1 { actions(workout) }
                    else { workoutPanel(workout) }
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "dumbbell.fill").foregroundStyle(WatchStyle.accent)
                        Text("Ready when you are").font(.headline)
                        Text("Start a workout on iPhone.").font(.caption).multilineTextAlignment(.center)
                        Button("Refresh") { store.refresh() }.disabled(store.pending != nil)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .foregroundStyle(WatchStyle.text).tint(WatchStyle.accent)
        .onAppear {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("WATCH_LAYOUT_ADJUST") { editor = store.envelope?.workout }
            if ProcessInfo.processInfo.arguments.contains("WATCH_LAYOUT_MORE") { page = 1 }
            #endif
        }
        .onChange(of: store.message) { _, value in if value != nil { showMessage = true } }
        .alert("Workout connection", isPresented: $showMessage) {
            Button("Refresh") { store.refresh() }
            Button("OK", role: .cancel) {}
        } message: { Text(store.message ?? "Open Spotter on iPhone to reconnect.") }
        .onChange(of: store.envelope?.workout?.workoutID) { _, _ in page = 0; editor = nil }
    }

    private func workoutPanel(_ workout: WatchWorkoutSnapshot) -> some View {
        VStack(spacing: 4) {
            Text(workout.exerciseName).font(.system(size: 13, weight: .semibold, design: .rounded))
                .lineLimit(2).minimumScaleFactor(0.85).multilineTextAlignment(.center)
                .frame(maxWidth: .infinity).frame(height: 30)
            Text("\(workout.loggedSets)/\(workout.targetSets) sets · Exercise \(workout.exerciseNumber)/\(workout.exerciseCount)")
                .font(.system(size: 11)).foregroundStyle(WatchStyle.secondary).lineLimit(1).minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            TimelineView(.periodic(from: .now, by: 1)) { context in
                if workout.editingSet {
                    Text("Finish editing on iPhone").font(.caption).multilineTextAlignment(.center)
                } else if workout.isResting(at: context.date), let end = workout.restEndsAt {
                    Text(end, style: .timer).font(.system(size: 30, weight: .semibold, design: .rounded)).monospacedDigit()
                        .foregroundStyle(WatchStyle.accent).accessibilityLabel("Rest remaining")
                    primary("End Rest", action: .skipRest)
                } else if workout.finishedExercise {
                    Text("Sets complete").font(.headline).foregroundStyle(WatchStyle.accent)
                    if workout.exerciseNumber < workout.exerciseCount { primary("Next exercise", action: .nextExercise) }
                    else { Text("Finish workout on iPhone").font(.caption).multilineTextAlignment(.center) }
                } else {
                    Button { editor = workout } label: {
                        Text("\(load(workout)) × \(workout.reps)").font(.system(size: 24, weight: .semibold, design: .rounded))
                            .lineLimit(1).minimumScaleFactor(0.6).frame(maxWidth: .infinity, minHeight: 38)
                    }.buttonStyle(.plain).disabled(!store.canAct).accessibilityLabel("Adjust weight and reps").accessibilityIdentifier("watch-adjust")
                    primary("Log Set", action: .complete)
                }
            }
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                if !store.canAct {
                    Button(store.pending == nil ? "Refresh" : "Syncing…") { store.refresh() }.disabled(store.pending != nil)
                } else {
                    Button("Adjust") { editor = workout }.disabled(workout.editingSet)
                }
                Button("More") { page = 1 }
            }.font(.caption).controlSize(.mini).frame(minHeight: 32)
        }.padding(.horizontal, 4)
    }

    private func actions(_ workout: WatchWorkoutSnapshot) -> some View {
        VStack(spacing: 5) {
            Text("Workout controls").font(.caption).foregroundStyle(WatchStyle.secondary)
            HStack(spacing: 5) {
                Button { store.perform(.previousExercise) } label: { Image(systemName: "arrow.left").frame(maxWidth: .infinity, minHeight: 32) }
                    .disabled(workout.exerciseNumber <= 1).accessibilityLabel("Previous exercise")
                Button { store.perform(.nextExercise) } label: { Image(systemName: "arrow.right").frame(maxWidth: .infinity, minHeight: 32) }
                    .disabled(workout.exerciseNumber >= workout.exerciseCount).accessibilityLabel("Next exercise")
            }.disabled(!store.canAct || workout.editingSet)
            Button("Undo last set") { store.perform(.undo) }
                .disabled(!store.canAct || workout.sessionSets == 0 || workout.editingSet)
            Button("Back to set") { page = 0 }
        }.font(.caption).buttonStyle(.bordered).padding(.horizontal, 4)
    }
    private func primary(_ title: String, action: WatchWorkoutAction) -> some View {
        Button(title) { store.perform(action) }.buttonStyle(.borderedProminent).controlSize(.small).foregroundStyle(Color.black)
            .frame(maxWidth: .infinity).disabled(!store.canAct).accessibilityIdentifier("watch-\(action.rawValue)")
    }
    private func load(_ workout: WatchWorkoutSnapshot) -> String {
        workout.weight == 0 ? "Bodyweight" : "\(workout.weight.formatted(.number.precision(.fractionLength(0...2)))) \(workout.unit)"
    }
}

private struct WatchTargetEditor: View {
    @ObservedObject var store: WatchWorkoutStore
    let basis: WatchWorkoutSnapshot
    let close: () -> Void
    @State private var weight: Double
    @State private var reps: Double
    @State private var editingWeight = true
    @FocusState private var crownFocused: Bool
    init(store: WatchWorkoutStore, basis: WatchWorkoutSnapshot, close: @escaping () -> Void) {
        self.store = store; self.basis = basis; self.close = close
        _weight = State(initialValue: basis.weight); _reps = State(initialValue: Double(basis.reps))
    }
    private var step: Double { editingWeight ? max(0.01, basis.weightStep ?? 2.5) : 1 }
    private var value: Binding<Double> {
        Binding(get: { editingWeight ? weight : reps }, set: {
            let value = min(editingWeight ? 10000 : 999, max(editingWeight ? 0 : 1, $0))
            if editingWeight { weight = (value * 100).rounded() / 100 } else { reps = value.rounded() }
        })
    }
    private var changedOnPhone: Bool { store.envelope?.workout?.revision != basis.revision }
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Button("Weight") { editingWeight = true }.tint(editingWeight ? WatchStyle.accent : .gray)
                Button("Reps") { editingWeight = false }.tint(editingWeight ? .gray : WatchStyle.accent)
            }.font(.caption2).controlSize(.mini)
            Text("\(value.wrappedValue.formatted(.number.precision(.fractionLength(0...2)))) \(editingWeight ? basis.unit : "reps")")
                .font(.system(size: 28, weight: .semibold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.6).monospacedDigit()
                .frame(maxWidth: .infinity)
                .focusable().focused($crownFocused)
                .digitalCrownRotation(value, from: editingWeight ? 0 : 1, through: editingWeight ? 10000 : 999,
                    by: step, sensitivity: .high, isContinuous: false, isHapticFeedbackEnabled: false)
            HStack(spacing: 5) {
                adjust("minus", amount: -step)
                adjust("plus", amount: step)
            }
            HStack(spacing: 5) {
                Button("−\((step * 10).formatted())") { value.wrappedValue -= step * 10 }
                Button("+\((step * 10).formatted())") { value.wrappedValue += step * 10 }
            }.font(.caption2).controlSize(.mini)
            HStack(spacing: 5) {
                Button("Cancel", action: close)
                Button(changedOnPhone ? "Changed" : "Apply") {
                    store.apply(.init(weight: weight, reps: Int(reps)), basedOn: basis)
                }.buttonStyle(.borderedProminent).foregroundStyle(Color.black).disabled(!store.canAct || changedOnPhone)
            }.font(.caption).controlSize(.small)
            if changedOnPhone { Text("Phone changed. Reopen Adjust.").font(.system(size: 10)).lineLimit(1).minimumScaleFactor(0.8) }
        }.padding(.horizontal, 4)
        .onAppear { crownFocused = true }
        .onChange(of: editingWeight) { _, _ in crownFocused = true }
        .onChange(of: store.appliedCount) { _, _ in close() }
    }
    private func adjust(_ symbol: String, amount: Double) -> some View {
        Button { value.wrappedValue += amount } label: { Image(systemName: symbol).frame(maxWidth: .infinity, minHeight: 26) }
            .buttonRepeatBehavior(.enabled).accessibilityLabel(symbol == "plus" ? "Increase value" : "Decrease value")
    }
}

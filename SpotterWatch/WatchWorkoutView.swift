import SwiftUI

/// The same steel blue and warm neutrals as Spotter's dark appearance.
private enum WatchStyle {
    static let accent = Color(red: 157 / 255, green: 180 / 255, blue: 200 / 255)
    static let text = Color(red: 244 / 255, green: 241 / 255, blue: 238 / 255)
    static let secondary = Color(red: 175 / 255, green: 168 / 255, blue: 164 / 255)
    static let ink = Color(red: 33 / 255, green: 30 / 255, blue: 29 / 255)
}

struct WatchWorkoutView: View {
    @ObservedObject var store: WatchWorkoutStore
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let workout = store.envelope?.workout {
                        Text(workout.exerciseName).font(.headline).fixedSize(horizontal: false, vertical: true)
                        Text("\(workout.loggedSets)/\(workout.targetSets) sets · \(workout.exerciseNumber)/\(workout.exerciseCount) exercises")
                            .font(.caption2).foregroundStyle(WatchStyle.secondary)
                        TimelineView(.periodic(from: .now, by: 1)) { timeline in
                            if workout.isResting(at: timeline.date), let end = workout.restEndsAt {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(end, style: .timer).font(.system(.largeTitle, design: .rounded).weight(.semibold))
                                        .monospacedDigit().foregroundStyle(WatchStyle.accent)
                                        .accessibilityLabel("Rest remaining")
                                    Text("Rest • next: \(load(workout)) × \(workout.reps)").font(.caption2)
                                        .lineLimit(1).minimumScaleFactor(0.75)
                                    primary("End Rest", symbol: "forward.fill", action: .skipRest)
                                }
                            } else if workout.editingSet {
                                Text("Finish editing your set on iPhone to continue here.").font(.callout)
                            } else if workout.finishedExercise {
                                Label("Sets complete", systemImage: "checkmark.circle.fill").foregroundStyle(WatchStyle.accent)
                                if workout.exerciseNumber < workout.exerciseCount {
                                    primary("Next exercise", symbol: "arrow.right", action: .nextExercise)
                                } else {
                                    Text("Finish and review your workout on iPhone.").font(.callout)
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("\(load(workout)) × \(workout.reps)")
                                        .font(.system(.title2, design: .rounded).weight(.semibold))
                                        .minimumScaleFactor(0.65).lineLimit(1).monospacedDigit()
                                    primary("Log Set", symbol: "checkmark", action: .complete)
                                }
                            }
                        }
                        if !workout.editingSet {
                            NavigationLink { adjustments } label: {
                                Label("Adjust & more", systemImage: "slider.horizontal.3").font(.caption)
                            }.accessibilityIdentifier("watch-adjust")
                        }
                    } else {
                        Image(systemName: "dumbbell.fill").font(.title).foregroundStyle(WatchStyle.accent)
                        Text("Ready when you are").font(.headline)
                        Text("Start a workout in Spotter on iPhone. Your next set will appear here.")
                            .font(.callout).foregroundStyle(WatchStyle.secondary)
                    }
                    if let message = store.message {
                        Text(message).font(.caption2).foregroundStyle(WatchStyle.secondary)
                    } else if !store.reachable {
                        Label("iPhone disconnected", systemImage: "iphone.slash").font(.caption2).foregroundStyle(WatchStyle.secondary)
                    }
                    if !store.canAct || store.envelope?.workout == nil {
                        Button(store.pending == nil ? "Refresh" : "Syncing…") { store.refresh() }
                            .disabled(store.pending != nil).font(.caption)
                            .accessibilityIdentifier("watch-refresh")
                    }
                }.padding(.horizontal, 4)
            }
            .navigationTitle("spotter.")
            .foregroundStyle(WatchStyle.text).tint(WatchStyle.accent)
        }
    }

    private func primary(_ title: String, symbol: String, action: WatchWorkoutAction) -> some View {
        Button { store.perform(action) } label: {
            HStack { Text(title); Spacer(minLength: 4); Image(systemName: symbol) }
                .font(.headline).frame(minHeight: 32)
        }
        .buttonStyle(.borderedProminent).tint(WatchStyle.accent).foregroundStyle(WatchStyle.ink)
        .disabled(!store.canAct).accessibilityIdentifier("watch-\(action.rawValue)")
    }

    private var adjustments: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let workout = store.envelope?.workout {
                    Text(load(workout)).font(.title3).monospacedDigit()
                    adjustment("Weight", down: .weightDown, up: .weightUp)
                    Text("\(workout.reps) reps").font(.title3).monospacedDigit()
                    adjustment("Reps", down: .repsDown, up: .repsUp)
                    if workout.sessionSets > 0 {
                        Button("Undo last set", systemImage: "arrow.uturn.backward") { store.perform(.undo) }
                    }
                    if workout.exerciseNumber < workout.exerciseCount {
                        Button("Next exercise", systemImage: "arrow.right") { store.perform(.nextExercise) }
                    }
                    if workout.exerciseNumber > 1 {
                        Button("Previous exercise", systemImage: "arrow.left") { store.perform(.previousExercise) }
                    }
                    if let message = store.message { Text(message).font(.caption2) }
                }
            }.disabled(!store.canAct || store.envelope?.workout?.editingSet == true)
        }.navigationTitle("Next set").tint(WatchStyle.accent)
    }

    private func adjustment(_ label: String, down: WatchWorkoutAction, up: WatchWorkoutAction) -> some View {
        HStack {
            Button { store.perform(down) } label: { Image(systemName: "minus").frame(minHeight: 32) }
                .accessibilityLabel("Decrease \(label.lowercased())")
            Button { store.perform(up) } label: { Image(systemName: "plus").frame(minHeight: 32) }
                .accessibilityLabel("Increase \(label.lowercased())")
        }
    }
    private func load(_ workout: WatchWorkoutSnapshot) -> String {
        workout.weight == 0 ? "Bodyweight" : "\(workout.weight.formatted(.number.precision(.fractionLength(0...2)))) \(workout.unit)"
    }
}

import SwiftUI
import ActivityKit
import WidgetKit

/// One primary action, plus a quiet correction affordance. Editing belongs in the app.
struct WorkoutActivityControls: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    private var state: WorkoutActivityAttributes.ContentState { context.state }
    private var resting: Bool { state.isResting(isStale: context.isStale) }
    private var resumeURL: URL { WorkoutActivityAttributes.resumeURL(workoutID: context.attributes.workoutID) }

    var body: some View {
        HStack(spacing: 10) {
            if let revision = state.revision, state.editingSet != true, !state.exerciseName.isEmpty {
                if resting {
                    Button(intent: intent(.skipRest, revision)) {
                        primaryLabel("End Rest", symbol: "forward.fill")
                    }.buttonStyle(.plain).accessibilityHint("Skip the remaining rest and return to your next set")
                } else if state.finishedExercise {
                    Link(destination: resumeURL) {
                        primaryLabel(state.exerciseNumber < state.exerciseCount ? "Next exercise" : "Review workout", symbol: "arrow.right")
                    }
                } else {
                    Button(intent: intent(.complete, revision)) {
                        primaryLabel("Log Set", symbol: "checkmark")
                    }.buttonStyle(.plain)
                        .accessibilityHint("Logs set \(state.setNumber ?? state.loggedSets + 1) with the displayed weight and reps")
                }
                if state.sessionSets > 0 {
                    Button(intent: intent(.undo, revision)) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 15, weight: .medium)).frame(width: 44, height: 44)
                            .background(SpotterStyle.foregroundAccent.opacity(0.10), in: Circle())
                    }.buttonStyle(.plain)
                        .accessibilityLabel("Undo last logged set")
                }
            } else {
                Link(destination: resumeURL) { primaryLabel("Review set", symbol: "arrow.up.right") }
            }
        }.tint(SpotterStyle.foregroundAccent)
    }

    private func primaryLabel(_ title: String, symbol: String) -> some View {
        HStack {
            Text(title)
            Spacer(minLength: 4)
            Image(systemName: symbol)
        }
        .font(.subheadline.weight(.semibold)).padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 44)
        .foregroundStyle(SpotterStyle.onAccent)
        .background(SpotterStyle.accent, in: Capsule())
    }
    private func intent(_ action: WorkoutAction, _ revision: String) -> WorkoutActionIntent {
        WorkoutActionIntent(workoutID: context.attributes.workoutID.uuidString, revision: revision, action: action)
    }
}

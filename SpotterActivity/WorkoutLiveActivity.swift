import ActivityKit
import SwiftUI
import WidgetKit
import UIKit

struct WorkoutLiveActivity: Widget {
    var previewColorScheme: ColorScheme? = nil

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            WorkoutActivityCard(context: context)
                .modifier(ActivityPreviewScheme(colorScheme: previewColorScheme))
                .widgetURL(WorkoutActivityAttributes.resumeURL(workoutID: context.attributes.workoutID))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("spotter.", systemImage: "dumbbell.fill")
                        .font(.subheadline.weight(.semibold)).lineLimit(1)
                        .foregroundStyle(SpotterStyle.blueLight)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        WorkoutActivitySummary(context: context, compact: true)
                        WorkoutActivityControls(context: context)
                    }.padding(.horizontal, 4).padding(.bottom, 4).environment(\.colorScheme, .dark)
                }
            } compactLeading: {
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(SpotterStyle.blueLight)
                    .accessibilityLabel("Spotter workout")
            } compactTrailing: {
                if context.state.isResting(isStale: context.isStale), let restEnd = context.state.restEndsAt {
                    RestTimer(endsAt: restEnd)
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .frame(width: 42)
                        .foregroundStyle(SpotterStyle.blueLight)
                } else {
                    Text("\(context.state.loggedSets)/\(context.state.targetSets)")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .accessibilityLabel("\(context.state.loggedSets) of \(context.state.targetSets) sets")
                }
            } minimal: {
                Image(systemName: context.state.isResting(isStale: context.isStale) ? "timer" : "dumbbell.fill")
                    .foregroundStyle(SpotterStyle.blueLight)
                    .accessibilityLabel("Spotter workout")
            }
            .widgetURL(WorkoutActivityAttributes.resumeURL(workoutID: context.attributes.workoutID))
            .keylineTint(SpotterStyle.blueLight)
        }
    }
}

private struct ActivityPreviewScheme: ViewModifier {
    var colorScheme: ColorScheme?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let colorScheme {
            content.environment(\.colorScheme, colorScheme)
        } else {
            content
        }
    }
}

private struct WorkoutActivityCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let context: ActivityViewContext<WorkoutActivityAttributes>

    // SpringBoard resolves the background outside the widget's trait environment.
    // Freeze it to the same appearance as the content to preserve text contrast.
    private var background: Color {
        Color(uiColor: UIColor(SpotterStyle.background).resolvedColor(with:
            UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WorkoutActivitySummary(context: context)
            WorkoutActivityControls(context: context)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .foregroundStyle(SpotterStyle.text)
        .activityBackgroundTint(background)
        .activitySystemActionForegroundColor(SpotterStyle.foregroundAccent)
    }
}

private struct WorkoutActivitySummary: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    var compact = false
    private var state: WorkoutActivityAttributes.ContentState { context.state }
    private var resting: Bool { state.isResting(isStale: context.isStale) }
    private var resumeURL: URL { WorkoutActivityAttributes.resumeURL(workoutID: context.attributes.workoutID) }

    var body: some View {
        Link(destination: resumeURL) {
            VStack(alignment: .leading, spacing: compact ? 4 : 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(state.exerciseName).font(.subheadline.weight(.semibold)).lineLimit(1).privacySensitive()
                    Spacer(minLength: 8)
                    Text("\(state.loggedSets)/\(state.targetSets) sets")
                        .font(.caption).monospacedDigit().foregroundStyle(SpotterStyle.secondaryText)
                }
                HStack(alignment: .center, spacing: 12) {
                    if resting, let end = state.restEndsAt {
                        RestTimer(endsAt: end).frame(width: 90)
                            .font(.system(size: compact ? 26 : 30, weight: .semibold, design: .rounded)).monospacedDigit()
                            .foregroundStyle(SpotterStyle.foregroundAccent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rest timer").font(.caption.weight(.semibold))
                            Text(state.lastSet ?? "Set saved").font(.caption2)
                                .foregroundStyle(SpotterStyle.secondaryText).lineLimit(1)
                        }
                    } else if state.finishedExercise {
                        Label("Planned sets complete", systemImage: "checkmark.circle")
                            .font(.headline).foregroundStyle(SpotterStyle.foregroundAccent).lineLimit(1).minimumScaleFactor(0.8)
                    } else {
                        Text(loadAndReps).font(.system(size: compact ? 22 : 24, weight: .semibold, design: .rounded))
                            .monospacedDigit().lineLimit(1).minimumScaleFactor(0.75)
                        Spacer(minLength: 0)
                        Image(systemName: "pencil").font(.caption)
                            .foregroundStyle(SpotterStyle.secondaryText)
                    }
                }.frame(height: compact ? 30 : 38, alignment: .leading)
            }
            .foregroundStyle(SpotterStyle.text)
        }.buttonStyle(.plain).accessibilityHint("Open workout to edit weight, reps, or exercise")
    }
    private var loadAndReps: String {
        let weight = state.currentWeight ?? 0
        let load = weight == 0 ? "Bodyweight" : "\(weight.formatted(.number.precision(.fractionLength(0...2)))) \(state.weightUnit ?? "load")"
        return "\(load) × \(state.currentReps ?? 8)"
    }
}

/// System-rendered time continues while the app is suspended and stops at zero.
/// System time remains accurate when the app sleeps. End Rest returns to logging even if iOS has not refreshed the layout.
private struct RestTimer: View {
    var endsAt: Date

    var body: some View {
        Text(timerInterval: Date(timeIntervalSince1970: 0)...max(endsAt, Date(timeIntervalSince1970: 0)), countsDown: true, showsHours: false)
            .multilineTextAlignment(.trailing)
            .accessibilityLabel("Rest time remaining")
    }
}

#if DEBUG
private extension WorkoutActivityAttributes {
    static let preview = WorkoutActivityAttributes(
        workoutID: UUID(), workoutName: "Upper body", startedAt: .now.addingTimeInterval(-1_080)
    )
}

private extension WorkoutActivityAttributes.ContentState {
    static let logging = Self(
        exerciseName: "Dumbbell bench press", exerciseNumber: 2, exerciseCount: 5,
        loggedSets: 2, targetSets: 3, sessionSets: 5, restEndsAt: nil, lastSet: "25 lb × 10", revision: "preview", currentWeight: 25, currentReps: 10, weightUnit: "lb", setNumber: 3, editingSet: false, targetReps: "8–10"
    )
    static let resting = Self(
        exerciseName: "Dumbbell bench press", exerciseNumber: 2, exerciseCount: 5,
        loggedSets: 2, targetSets: 3, sessionSets: 5, restEndsAt: .now.addingTimeInterval(75), lastSet: "25 lb × 10", revision: "preview", currentWeight: 25, currentReps: 10, weightUnit: "lb", setNumber: 3, editingSet: false, targetReps: "8–10"
    )
}

#Preview("Workout · light", as: .content, using: WorkoutActivityAttributes.preview) {
    WorkoutLiveActivity(previewColorScheme: .light)
} contentStates: {
    WorkoutActivityAttributes.ContentState.logging
    WorkoutActivityAttributes.ContentState.resting
}

#Preview("Workout · dark", as: .content, using: WorkoutActivityAttributes.preview) {
    WorkoutLiveActivity(previewColorScheme: .dark)
} contentStates: {
    WorkoutActivityAttributes.ContentState.resting
    WorkoutActivityAttributes.ContentState.logging
}
#Preview("Island · expanded", as: .dynamicIsland(.expanded), using: WorkoutActivityAttributes.preview) {
    WorkoutLiveActivity()
} contentStates: {
    WorkoutActivityAttributes.ContentState.logging
    WorkoutActivityAttributes.ContentState.resting
}
#Preview("Island · compact", as: .dynamicIsland(.compact), using: WorkoutActivityAttributes.preview) {
    WorkoutLiveActivity()
} contentStates: {
    WorkoutActivityAttributes.ContentState.logging
    WorkoutActivityAttributes.ContentState.resting
}
#Preview("Island · minimal", as: .dynamicIsland(.minimal), using: WorkoutActivityAttributes.preview) {
    WorkoutLiveActivity()
} contentStates: {
    WorkoutActivityAttributes.ContentState.logging
    WorkoutActivityAttributes.ContentState.resting
}
#endif

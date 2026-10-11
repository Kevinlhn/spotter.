import SwiftUI
import Charts

struct ProgressScreen: View {
    @EnvironmentObject private var store: TrainingStore
    @Environment(\.dynamicTypeSize) private var textSize
    let onOpen: (WorkoutEntity) -> Void
    let onTrends: () -> Void

    private var weeks: [TrainingWeek] { TrainingProgress.weeks(store.completed) }

    var body: some View {
        FeaturePage {
            VStack(alignment: .leading, spacing: 10) {
                FeatureHeading(title: "Progress", subtitle: "\(store.completed.count) completed sessions · \(store.totalSets) sets logged")
                Button(action: onTrends) {
                    HStack {
                        Label("Exercise trends", systemImage: "chart.line.uptrend.xyaxis")
                        Spacer()
                        SpotterChevron()
                    }.font(.subheadline.weight(.semibold)).padding(14).spotterControl().contentShape(Rectangle())
                }.buttonStyle(SpotterPressStyle()).accessibilityIdentifier("exercise-trends")
            }
        } content: {
            if textSize.isAccessibilitySize {
                // Keep navigation stable; the content region can scroll when text needs more room.
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        consistency
                        historyHeading
                        historyRows
                    }.padding(.horizontal, 20).padding(.bottom, 16)
                }.scrollBounceBehavior(.basedOnSize).accessibilityIdentifier("workout-history")
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    consistency.padding(.horizontal, 20)
                    historyHeading.padding(.horizontal, 20)
                    ScrollView {
                        LazyVStack(spacing: 12) { historyRows }
                            .padding(.horizontal, 20).padding(.bottom, 16)
                    }.scrollBounceBehavior(.basedOnSize).accessibilityIdentifier("workout-history")
                }
            }
        }
    }

    private var consistency: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeading(title: "Consistency", detail: "Last 6 weeks")
            Chart(weeks) { week in
                BarMark(x: .value("Week", week.date, unit: .weekOfYear), y: .value("Sessions", week.count))
                    .foregroundStyle(SpotterStyle.muted.gradient).cornerRadius(4)
                    .accessibilityLabel("Week of \(week.date.formatted(date: .abbreviated, time: .omitted))")
                    .accessibilityValue("\(week.count) completed sessions")
            }
            .chartYScale(domain: 0...max(4, (weeks.map(\.count).max() ?? 0) + 1))
            .chartXAxis { AxisMarks(values: weeks.map(\.date)) { _ in AxisValueLabel(format: .dateTime.month(.abbreviated).day()) } }
            .chartYAxis { AxisMarks(values: .stride(by: 1)) }
            .frame(minHeight: 70, idealHeight: 105, maxHeight: 120)
        }.padding(16).spotterGlass(radius: 22)
    }

    private var historyHeading: some View {
        SectionHeading(title: "Workout history", detail: "\(store.completed.count) sessions")
    }

    @ViewBuilder private var historyRows: some View {
        if store.completed.isEmpty {
            EmptyTrainingState(icon: "chart.xyaxis.line", title: "Your first session starts your history.", message: "Finish a workout to see it here with every set saved.")
        } else {
            ForEach(store.completed) { workout in
                Button { onOpen(workout) } label: { WorkoutListRow(workout: workout) }
                    .buttonStyle(SpotterPressStyle()).accessibilityIdentifier("history-\(workout.id)")
            }
        }
    }
}

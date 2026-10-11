import SwiftUI

struct WorkoutListRow: View {
    @ObservedObject var workout: WorkoutEntity
    var body: some View {
        HStack(spacing: 12) {
            Text(workout.date.formatted(.dateTime.day())).font(.system(.title3, design: .rounded).weight(.semibold)).monospacedDigit()
                .foregroundStyle(SpotterStyle.foregroundAccent)
                .frame(width: 42, height: 48)
                .spotterControl(radius: 14)
            VStack(alignment: .leading, spacing: 5) {
                Text(workout.name).font(.headline).foregroundStyle(SpotterStyle.text)
                Text("\(workout.sortedExercises.count) exercises · \(workout.date.formatted(.dateTime.month(.abbreviated).day()))")
                    .font(.caption).foregroundStyle(SpotterStyle.secondaryText)
            }
            Spacer(minLength: 0)
            Image(systemName: workout.workoutStatus == .completed ? "checkmark.circle.fill" : "arrow.up.right")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(SpotterStyle.foregroundAccent).accessibilityHidden(true)
        }.padding(16)
            .spotterGlass(radius: 22, interactive: true)
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

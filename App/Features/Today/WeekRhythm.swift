import SwiftUI

// MARK: - Week Rhythm

struct WeekRhythm: View {

    let workouts: [WorkoutEntity]

    private var days: [Date] {

        let calendar = Calendar.current

        let start =
            calendar.dateInterval(
                of: .weekOfYear,
                for: Date()
            )?.start ?? Date()

        return (0..<7).compactMap {
            calendar.date(
                byAdding: .day,
                value: $0,
                to: start
            )
        }
    }

    var body: some View {

        HStack(spacing: 8) {

            ForEach(
                days,
                id: \.self
            ) { day in

                let done =
                    workouts.contains {
                        Calendar.current.isDate(
                            $0.date,
                            inSameDayAs: day
                        )
                    }

                let today =
                    Calendar.current
                        .isDateInToday(day)

                VStack(spacing: 10) {

                    Text(
                        day.formatted(
                            .dateTime
                                .weekday(.narrow)
                        )
                    )
                    .font(
                        .system(
                            .caption2,
                            design: .rounded,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        today
                            ? SpotterStyle.text
                            : SpotterStyle.secondaryText
                    )

                    ZStack {

                        Circle()
                            .stroke(
                                SpotterStyle
                                    .foregroundAccent
                                    .opacity(
                                        done
                                            ? 1
                                            : 0.35
                                    ),
                                lineWidth: 1.5
                            )
                            .frame(
                                width: 25,
                                height: 25
                            )

                        if done {

                            Circle()
                                .fill(
                                    SpotterStyle
                                        .foregroundAccent
                                )
                                .frame(
                                    width: 25,
                                    height: 25
                                )

                            Image(
                                systemName: "checkmark"
                            )
                            .font(
                                .system(
                                    size: 10,
                                    weight: .bold
                                )
                            )
                            .foregroundStyle(
                                SpotterStyle.onAccent
                            )

                        } else if today {

                            Circle()
                                .fill(
                                    SpotterStyle
                                        .foregroundAccent
                                        .opacity(0.14)
                                )
                                .frame(
                                    width: 17,
                                    height: 17
                                )
                        }
                    }
                }
                .frame(
                    maxWidth: .infinity
                )
                .accessibilityElement(
                    children: .ignore
                )
                .accessibilityLabel(
                    "\(day.formatted(.dateTime.weekday(.wide))): \(done ? "Workout completed" : "No completed workout")"
                )
            }
        }
    }
}

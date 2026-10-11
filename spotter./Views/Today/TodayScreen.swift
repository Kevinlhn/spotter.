import SwiftUI

struct TodayScreen: View {
    @EnvironmentObject private var store: TrainingStore
    @Environment(\.dynamicTypeSize) private var textSize

    @AppStorage("profile.sessionsPerWeek")
    private var goal = 3

    let onQuickStart: () -> Void
    let onStart: (WorkoutEntity) -> Void
    let onPlan: (Date) -> Void
    let onOpen: (WorkoutEntity) -> Void
    let onSettings: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in

            let today = store.scheduled.first {
                Calendar.current.isDate(
                    $0.calendarDate,
                    inSameDayAs: timeline.date
                )
            }

            let upcoming = store.scheduled.first {
                $0.calendarDate > timeline.date &&
                !Calendar.current.isDate(
                    $0.calendarDate,
                    inSameDayAs: timeline.date
                )
            }

            FeaturePage {

                header(date: timeline.date)

            } content: {

                CompactContent {
                    VStack(
                        alignment: .leading,
                        spacing: 24
                    ) {

                        primaryWorkout(today: today)

                        rhythmSection.padding(.horizontal)

                        if let upcoming {

                            Button {
                                onPlan(upcoming.calendarDate)
                            } label: {
                                contextRow(
                                    title: upcoming.name,
                                    caption:
                                        "UP NEXT · " +
                                        upcoming.calendarDate.formatted(
                                            .dateTime
                                                .month(.abbreviated)
                                                .day()
                                        ),
                                    symbol: "calendar"
                                )
                            }
                            .buttonStyle(SpotterPressStyle())
                            .accessibilityIdentifier(
                                "today-upcoming"
                            )

                        } else if let last = store.completed.first {

                            Button {
                                onOpen(last)
                            } label: {
                                contextRow(
                                    title: last.name,
                                    caption:
                                        "LAST SESSION · " +
                                        last.date.formatted(
                                            .dateTime
                                                .month(.abbreviated)
                                                .day()
                                        ),
                                    symbol: "checkmark"
                                )
                            }
                            .buttonStyle(SpotterPressStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
        }
    }

    // MARK: - Header

    private func header(
        date: Date
    ) -> some View {

        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("spotter.").font(.system(.title2, design: .rounded, weight: .bold)).foregroundStyle(.accent)
                Text("by kevinlhn")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Button(action: onSettings) {

                Image(
                    systemName: "slider.horizontal.3"
                )
                .font(.system(size: 18, weight: .medium))
                .frame(width: 44, height: 44).contentShape(Circle())
                .foregroundStyle(
                    SpotterStyle.headerAccent
                )
        }.buttonStyle(SpotterPressStyle()).accessibilityLabel("Settings")
    }.padding(.horizontal)
    }

    // MARK: - Primary Workout

    private func primaryWorkout(
        today: WorkoutEntity?
    ) -> some View {

        let current = store.active ?? today

        return VStack(
            alignment: .leading,
            spacing: 20
        ) {

            if !textSize.isAccessibilitySize {

                HStack {

                    Text(
                        store.active != nil
                            ? "IN SESSION"
                            : today != nil
                                ? "TODAY’S PLAN"
                                : "YOUR TIME TO MOVE"
                    )
                    .font(
                        .system(
                            .caption2,
                            design: .monospaced
                        )
                        .weight(.medium)
                    )
                    .tracking(1.2)

                    Spacer()

                    Image(
                        systemName:
                            store.active == nil
                                ? "dumbbell"
                                : "waveform.path.ecg"
                    )
                    .font(
                        .system(
                            size: 18,
                            weight: .medium
                        )
                    )
                    .accessibilityHidden(true)
                }
                .foregroundStyle(
                    .white.opacity(0.80)
                )
            }

            VStack(
                alignment: .leading,
                spacing: 9
            ) {

                Text(
                    current?.name ??
                    (
                        textSize.isAccessibilitySize
                            ? "Ready to train."
                            : "A little stronger, today."
                    )
                )
                .font(
                    .system(
                        .title2,
                        design: .rounded,
                        weight: .semibold
                    )
                )
                .tracking(-0.5)

                if !textSize.isAccessibilitySize {

                    Text(
                        current.map {
                            "\($0.sortedExercises.count) exercises · " +
                            (
                                $0.workoutStatus == .active
                                ? "\($0.sortedExercises.flatMap(\.sortedSets).count) sets saved"
                                : "Ready when you are"
                            )
                        }
                        ??
                        "Pick a routine. Find your pace. We’ll keep the log."
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        .white.opacity(0.82)
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                }
            }

            Button {

                if let current {
                    onStart(current)
                } else {
                    onQuickStart()
                }

            } label: {

                HStack {

                    Text(
                        store.active != nil
                            ? "Resume workout"
                            : today != nil
                                ? "Start today’s workout"
                                : "Start workout"
                    )
                    .font(.headline)

                    Spacer(minLength: 8)

                    Image(
                        systemName: "arrow.up.right"
                    )
                    .font(
                        .system(
                            size: 17,
                            weight: .semibold
                        )
                    )
                }
                .padding(.top, 17)
                .padding(.bottom, 2)
                .contentShape(Rectangle())
                .overlay(
                    alignment: .top
                ) {
                    Rectangle()
                        .fill(
                            .white.opacity(0.18)
                        )
                        .frame(height: 0.5)
                }
            }
            .buttonStyle(
                SpotterPressStyle()
            )
            .accessibilityIdentifier(
                "today-next-workout"
            )
        }
        .padding(22)
        .foregroundStyle(.white)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background {
            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
            .fill(
                SpotterStyle.heroGradient
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 28,
                    style: .continuous
                )
                .stroke(
                    .white.opacity(0.11),
                    lineWidth: 0.8
                )
            }
            .shadow(
                color: SpotterStyle.shadow,
                radius: 14,
                x: 0,
                y: 7
            )
        }
    }

    // MARK: - Weekly Rhythm

    private var rhythmSection: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            // Similar visual hierarchy to Counter's
            // cardless macro section.

            HStack(
                alignment: .firstTextBaseline
            ) {

                HStack(spacing: 7) {

                    Circle()
                        .fill(
                            SpotterStyle.foregroundAccent
                        )
                        .frame(
                            width: 6,
                            height: 6
                        )

                    Text("YOUR RHYTHM")
                        .font(
                            .system(
                                .caption2,
                                design: .monospaced,
                                weight: .medium
                            )
                        )
                        .tracking(1.1)
                        .foregroundStyle(
                            SpotterStyle.secondaryText
                        )
                }

                Spacer()

                Text("THIS WEEK")
                    .font(
                        .system(
                            .caption2,
                            design: .monospaced,
                            weight: .medium
                        )
                    )
                    .tracking(0.7)
                    .foregroundStyle(
                        SpotterStyle.secondaryText
                    )
            }

            HStack(
                alignment: .firstTextBaseline,
                spacing: 6
            ) {

                Text(
                    "\(store.thisWeek.count)"
                )
                .font(
                    .system(
                        size: 38,
                        weight: .medium,
                        design: .rounded
                    )
                )
                .tracking(-1)
                .foregroundStyle(
                    SpotterStyle.text
                )
                .contentTransition(
                    .numericText()
                )
                .monospacedDigit()

                Text(
                    "/ \(max(1, goal)) sessions"
                )
                .font(.subheadline)
                .foregroundStyle(
                    SpotterStyle.secondaryText
                )

                Spacer(minLength: 8)

                Image(
                    systemName:
                        store.thisWeek.count >=
                        max(1, goal)
                            ? "checkmark.seal.fill"
                            : "figure.cooldown"
                )
                .font(
                    .system(
                        size: 21,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    SpotterStyle.foregroundAccent
                )
                .accessibilityHidden(true)
            }

            if textSize.isAccessibilitySize {

                Text(
                    store.thisWeek.isEmpty
                        ? "Start with one good session."
                        : "Every finished session counts."
                )
                .font(.caption)
                .foregroundStyle(
                    SpotterStyle.secondaryText
                )

            } else {

                WeekRhythm(
                    workouts: store.thisWeek
                )
            }

            GeometryReader { proxy in

                ZStack(
                    alignment: .leading
                ) {

                    Capsule()
                        .fill(
                            SpotterStyle.progressTrack
                        )

                    Capsule()
                        .fill(
                            SpotterStyle.foregroundAccent
                        )
                        .frame(
                            width:
                                proxy.size.width *
                                weeklyProgress
                        )
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 2)
    }

    private var weeklyProgress: CGFloat {

        let target = max(
            1,
            goal
        )

        return min(
            CGFloat(store.thisWeek.count) /
            CGFloat(target),
            1
        )
    }

    // MARK: - Context Row

    private func contextRow(
        title: String,
        caption: String,
        symbol: String
    ) -> some View {

        HStack(spacing: 12) {

            SpotterRowIcon(
                symbol: symbol
            )

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text(caption)
                    .font(
                        .system(
                            .caption2,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(
                        SpotterStyle.secondaryText
                    )

                Text(title)
                    .font(
                        .subheadline
                            .weight(.semibold)
                    )
                    .foregroundStyle(
                        SpotterStyle.text
                    )
            }

            Spacer(minLength: 4)

            SpotterChevron()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Week Rhythm

private struct WeekRhythm: View {

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

import SwiftUI

struct PlanScreen: View {
    @EnvironmentObject private var store: TrainingStore
    @Environment(\.dynamicTypeSize) private var textSize
    @Binding var selectedDate: Date
    let onAdd: (Date) -> Void
    let onOpen: (WorkoutEntity) -> Void
    @State private var showMonth = false
    private var week: [Date] {
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            FeaturePage {
                HStack {
                    FeatureHeading(title: "Plan", subtitle: "A little structure for your week")
                    Button { onAdd(selectedDate) } label: {
                        Image(systemName: "plus").font(.body.weight(.semibold)).frame(width: 44, height: 44)
                            .spotterGlass(radius: 22, interactive: true)
                    }.buttonStyle(SpotterPressStyle()).accessibilityLabel("Plan workout").accessibilityIdentifier("plan-workout")
                }
            } content: {
                VStack(spacing: 8) {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 4) {
                            monthButton.fixedSize(horizontal: true, vertical: false)
                            Spacer(minLength: 4)
                            weekNavigation(now: timeline.date).fixedSize(horizontal: true, vertical: false)
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            monthButton
                            HStack { Spacer(); weekNavigation(now: timeline.date) }
                        }
                    }.padding(.horizontal, 20)
                    if textSize.isAccessibilitySize {
                        HStack {
                            Button { shiftDay(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }.buttonStyle(SpotterPressStyle()).accessibilityLabel("Previous day")
                            Text(selectedDate.formatted(.dateTime.month(.abbreviated).day())).font(.headline).frame(maxWidth: .infinity)
                            Button { shiftDay(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }.buttonStyle(SpotterPressStyle()).accessibilityLabel("Next day")
                        }.padding(.horizontal, 20)
                    } else {
                        HStack(spacing: 2) {
                            ForEach(week, id: \.self) { day in
                                CalendarDay(day: day, selected: Calendar.current.isDate(day, inSameDayAs: selectedDate), entries: store.entries(on: day), now: timeline.date, showWeekday: true) { selectedDate = day }
                            }
                        }.padding(.horizontal, 16)
                    }
                    HStack {
                        Text(selectedDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())).font(.subheadline.bold())
                        Spacer()
                        Text("\(store.entries(on: selectedDate).count) workouts").font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                    }.padding(.horizontal, 20).padding(.top, 10)
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            let entries = store.entries(on: selectedDate)
                            if entries.isEmpty {
                                EmptyTrainingState(icon: "calendar", title: "Room to move. Or rest.", message: "Choose a saved workout or starter routine to plan this day.")
                                Button { onAdd(selectedDate) } label: {
                                    Text("Add a workout").font(.headline).frame(minHeight: 44)
                                }.buttonStyle(SpotterPressStyle())
                            }
                            ForEach(entries) { workout in
                                Button { onOpen(workout) } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(workout.name).font(.headline).foregroundStyle(SpotterStyle.text)
                                            Spacer(minLength: 8); SpotterChevron()
                                        }
                                        HStack {
                                            PlanningStatusLabel(state: workout.planningState(now: timeline.date) ?? .scheduled)
                                            Spacer()
                                            Text("\(workout.sortedExercises.count) exercises").font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                                        }
                                        if let assigned = workout.scheduledDate, !Calendar.current.isDate(assigned, inSameDayAs: workout.date), workout.workoutStatus != .scheduled {
                                            Text("Trained \(workout.date.formatted(.dateTime.month(.abbreviated).day()))").font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                                        }
                                    }.padding(16).spotterGlass(radius: 22, interactive: true).contentShape(Rectangle())
                                }.buttonStyle(SpotterPressStyle()).accessibilityIdentifier("planned-\(workout.id)")
                            }
                        }.padding(.horizontal, 20).padding(.vertical, 8)
                    }.scrollBounceBehavior(.basedOnSize).accessibilityIdentifier("planned-workouts-list")
                }
            }
            .sheet(isPresented: $showMonth) { WorkoutCalendar(selectedDate: $selectedDate) }
        }
    }
    private var monthButton: some View {
        Button { showMonth = true } label: {
            HStack(spacing: 8) {
                Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                    .font(.subheadline.weight(.semibold))
                Image(systemName: "chevron.down").font(.caption2.weight(.semibold)).accessibilityHidden(true)
            }.frame(minHeight: 44).contentShape(Rectangle())
        }.buttonStyle(SpotterPressStyle()).accessibilityIdentifier("open-month-calendar")
    }
    private func weekNavigation(now: Date) -> some View {
        HStack(spacing: 0) {
            Button { selectedDate = now } label: {
                Text("Today").font(.caption.weight(.semibold)).padding(.horizontal, 8).frame(minHeight: 44)
            }.buttonStyle(SpotterPressStyle())
            Button { shiftWeek(-1) } label: {
                Image(systemName: "chevron.left").font(.caption.weight(.semibold)).frame(width: 44, height: 44)
            }.buttonStyle(SpotterPressStyle()).accessibilityLabel("Previous week")
            Button { shiftWeek(1) } label: {
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).frame(width: 44, height: 44)
            }.buttonStyle(SpotterPressStyle()).accessibilityLabel("Next week")
        }
    }
    private func shiftDay(_ offset: Int) {
        selectedDate = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate) ?? selectedDate
    }
    private func shiftWeek(_ offset: Int) {
        selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: offset, to: selectedDate) ?? selectedDate
    }
}

struct PlanningStatusLabel: View {
    let state: WorkoutPlanningState
    private var symbol: String {
        switch state { case .scheduled: "calendar"; case .overdue: "clock.badge.exclamationmark"; case .active: "play.circle.fill"; case .completed: "checkmark.circle.fill" }
    }
    var body: some View {
        Label(state.label, systemImage: symbol).font(.caption.weight(.semibold))
            .foregroundStyle(state == .overdue ? SpotterStyle.warning : state == .completed ? SpotterStyle.success : SpotterStyle.foregroundAccent)
    }
}

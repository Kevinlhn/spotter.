import SwiftUI

struct WorkoutCalendar: View {
    @EnvironmentObject private var store: TrainingStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var textSize
    @Binding var selectedDate: Date
    @State private var month = Date()

    var body: some View {
        NavigationStack {
            FeaturePage {
                HStack {
                    Button { shift(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }.buttonStyle(SpotterPressStyle()).accessibilityLabel("Previous month")
                    Text(month.formatted(.dateTime.month(.wide).year())).font(.headline).frame(maxWidth: .infinity)
                    Button { shift(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }.buttonStyle(SpotterPressStyle()).accessibilityLabel("Next month")
                }
            } content: {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if textSize.isAccessibilitySize {
                            LazyVStack(spacing: 8) {
                                ForEach(TrainingCalendar.days(in: month).compactMap { $0 }, id: \.self) { day in
                                    Button { selectedDate = day; dismiss() } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())).font(.headline)
                                            Text("\(store.entries(on: day).count) workouts").font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                                        }.frame(maxWidth: .infinity, alignment: .leading).padding(12).spotterControl(selected: Calendar.current.isDate(day, inSameDayAs: selectedDate))
                                    }.buttonStyle(SpotterPressStyle()).foregroundStyle(Calendar.current.isDate(day, inSameDayAs: selectedDate) ? Color.white : SpotterStyle.text)
                                }
                            }
                        } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 4) {
                            ForEach(Array(TrainingCalendar.weekdaySymbols().enumerated()), id: \.offset) { _, symbol in
                                Text(symbol).font(.caption.weight(.medium)).foregroundStyle(SpotterStyle.secondaryText).accessibilityHidden(true)
                            }
                            ForEach(Array(TrainingCalendar.days(in: month).enumerated()), id: \.offset) { _, day in
                                if let day {
                                    CalendarDay(day: day, selected: Calendar.current.isDate(day, inSameDayAs: selectedDate), entries: store.entries(on: day), now: Date()) {
                                        selectedDate = day; dismiss()
                                    }
                                } else { Color.clear.frame(minHeight: 44) }
                            }
                        }
                        }
                        Text("Dots mark workout days. Select a day to see its plans and completed sessions.").font(.subheadline).foregroundStyle(SpotterStyle.secondaryText)
                        ForEach([WorkoutPlanningState.scheduled, .active, .completed, .overdue], id: \.rawValue) { PlanningStatusLabel(state: $0) }
                    }.padding(20)
                }
            }
            .navigationTitle("Workout calendar").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Today") { selectedDate = Date(); dismiss() } }
            }
        }.onAppear { month = selectedDate }
    }
    private func shift(_ amount: Int) {
        let start = Calendar.current.dateInterval(of: .month, for: month)?.start ?? month
        month = Calendar.current.date(byAdding: .month, value: amount, to: start) ?? start
    }
}

struct CalendarDay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let day: Date
    let selected: Bool
    let entries: [WorkoutEntity]
    let now: Date
    var showWeekday = false
    let onSelect: () -> Void
    private var states: [WorkoutPlanningState] {
        let present = Set(entries.compactMap { $0.planningState(now: now)?.rawValue })
        return [.scheduled, .active, .completed, .overdue].filter { present.contains($0.rawValue) }
    }
    private var accessibilitySummary: String {
        let date = day.formatted(.dateTime.weekday(.wide).month().day().year())
        let detail = entries.isEmpty ? "No workouts" : "\(entries.count) workouts, " + states.map(\.label).joined(separator: ", ")
        return date + (Calendar.current.isDate(day, inSameDayAs: now) ? ", today, " : ", ") + detail
    }
    var body: some View {
        Button(action: onSelect) { dayContent }
            .buttonStyle(SpotterPressStyle())
            .accessibilityLabel(accessibilitySummary)
            .accessibilityIdentifier("calendar-day-\(Calendar.current.startOfDay(for: day).timeIntervalSince1970)")
            .accessibilityAddTraits(selected ? .isSelected : [])
    }
    private var dayContent: some View {
        VStack(spacing: 3) {
            if showWeekday { Text(day.formatted(.dateTime.weekday(.narrow))).font(.caption2.weight(.medium)).opacity(selected ? 0.85 : 0.7) }
            Text(day.formatted(.dateTime.day())).font(.subheadline).fontWeight(selected ? .semibold : .medium).monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
            markers
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .foregroundStyle(selected ? Color.white : SpotterStyle.foregroundAccent)
        .background(selected ? SpotterStyle.accent : Color.clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            if !selected && Calendar.current.isDate(day, inSameDayAs: now) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(SpotterStyle.foregroundAccent.opacity(0.45), lineWidth: 1)
                    .allowsHitTesting(false)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: selected)
        .contentShape(Rectangle())
    }
    private var markers: some View {
        HStack(spacing: 2) {
            ForEach(states, id: \.rawValue) { state in
                Image(systemName: markerSymbol(state)).font(.system(size: 6, weight: .bold))
            }
        }.frame(height: 7)
    }
    private func markerSymbol(_ state: WorkoutPlanningState) -> String {
        switch state { case .completed: "checkmark"; case .active: "play.fill"; case .overdue: "exclamationmark"; case .scheduled: "circle.fill" }
    }
}

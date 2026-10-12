import Foundation

/// Display state derived from the stored lifecycle and local calendar day.
/// An overdue plan remains editable; it is never automatically marked as missed.
enum WorkoutPlanningState: String {
    case scheduled, overdue, active, completed

    var label: String {
        switch self {
        case .scheduled: "Planned"
        case .overdue: "Overdue"
        case .active: "In progress"
        case .completed: "Completed"
        }
    }
}

extension WorkoutEntity {
    func planningState(now: Date = Date(), calendar: Calendar = .current) -> WorkoutPlanningState? {
        switch workoutStatus {
        case .template: nil
        case .active: .active
        case .completed: .completed
        case .scheduled:
            calendar.startOfDay(for: calendarDate) < calendar.startOfDay(for: now) ? .overdue : .scheduled
        }
    }
}

/// Calendar arithmetic stays out of the view and respects locale, DST, and week starts.
enum TrainingCalendar {
    static func days(in month: Date, calendar: Calendar = .current) -> [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let leading = (calendar.component(.weekday, from: interval.start) - calendar.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: leading)
        days += range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: interval.start) }.map(Optional.some)
        let trailing = (7 - days.count % 7) % 7
        days += Array(repeating: nil, count: trailing)
        return days
    }

    static func weekdaySymbols(calendar: Calendar = .current) -> [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let offset = calendar.firstWeekday - 1
        return Array(symbols[offset...]) + Array(symbols[..<offset])
    }
}

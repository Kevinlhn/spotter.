//
//  WeeklyCalendar.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/2/25.
//

import SwiftUI

struct WeeklyCalendar: View {
    @Binding var selectedDate: Date
    
    var body: some View {
        HStack {
            ForEach(0..<7, id: \.self) { offset in
                let day = Calendar.current.date(byAdding: .day, value: offset, to: startOfWeek())!
                VStack {
                    Text(shortDayFormatter.string(from: day))
                        .font(.headline)
                    
                    Text(dayFormatter.string(from: day))
                        .font(.title3)
                        .foregroundColor(isSameDay(day, selectedDate) ? .white : .primary)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(isSameDay(day, selectedDate) ? Color(hex: "1E5A66") : Color.clear)
                        )
                }
                .onTapGesture {
                    selectedDate = day
                }
            }
        }
    }
    
    
    
    // MARK: - Formatters
    private let shortDayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "E"
        return df
    }()

    private let dayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "d"
        return df
    }()
    
    // MARK: - Helpers
    private func startOfWeek() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return calendar.date(from: components)!
    }
    
    private func isSameDay(_ d1: Date, _ d2: Date) -> Bool {
        Calendar.current.isDate(d1, inSameDayAs: d2)
    }
}

struct WeeklyCalendar_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyCalendar(selectedDate: .constant(Date()))
    }
}

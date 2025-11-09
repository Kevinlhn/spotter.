//
//  PerformanceView.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/29/25.
//


import SwiftUI
import Charts

struct PerformanceView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedMetric = "Volume"

    var body: some View {
        ZStack {
            SpotterBackground()

            VStack{
                Text("progress.")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(AppColors.bluePrimary.gradient)

                Picker("Metric", selection: $selectedMetric) {
                    Text("Volume").tag("Volume")
                    Text("PRs").tag("PRs")
                    Text("Streak").tag("Streak")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Chart {
                    ForEach(MockProgressData.data(for: selectedMetric)) { entry in
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Value", entry.value)
                        )
                        .foregroundStyle(AppColors.bluePrimary)
                        .symbol(.circle)
                    }
                }
                .frame(height: 240)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .padding(.horizontal)

                VStack(spacing: 10) {
                    Text("this week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
//                        ProgressRing(label: "Adherence", percent: 0.92, color: .green)
//                        ProgressRing(label: "Intensity", percent: 0.78, color: AppColors.bluePrimary)
//                        ProgressRing(label: "Consistency", percent: 0.84, color: .orange)
                    }
                }

                Spacer()
            }
        }
    }
}

struct ProgressEntry: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct MockProgressData {
    static func data(for metric: String) -> [ProgressEntry] {
        let values = stride(from: 0, to: 7, by: 1).map {
            ProgressEntry(date: Calendar.current.date(byAdding: .day, value: -$0, to: Date())!,
                          value: Double.random(in: 5...15))
        }
        return values.sorted { $0.date < $1.date }
    }
}

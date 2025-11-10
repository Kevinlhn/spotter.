//
//  ExerciseRow.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 11/9/25.
//


import SwiftUI
import CoreData

struct ExerciseRow: View {
    @ObservedObject var exercise: ExerciseEntity
    @Environment(\.managedObjectContext) private var context
    @Environment(\.colorScheme) private var colorScheme

    @State private var isExpanded = false
    @State private var reps = ""
    @State private var weight = ""

    private var sets: [WorkoutSetEntity] {
        (exercise.sets as? Set<WorkoutSetEntity>)?
            .sorted(by: { ($0.timestamp ?? .now) < ($1.timestamp ?? .now) }) ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // MARK: - Header
            HStack {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(AppColors.bluePrimary)

                Spacer()

                Button {
                    withAnimation(.spring()) { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppColors.bluePrimary)
                }
            }

            // MARK: - Summary
            if sets.isEmpty {
                Text("No sets yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                let totalSets = sets.count
                let avgReps = Int(sets.map { Int($0.reps) }.reduce(0, +) / totalSets)
                let lastWeight = Int(sets.last?.weight ?? 0)
                Text("\(totalSets) sets • avg \(avgReps) reps • last \(lastWeight) lbs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // MARK: - Expanded View
            if isExpanded {
                Divider().opacity(0.2)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(sets, id: \.id) { set in
                        SetRow(set: set, onDelete: deleteSet)
                    }

                    HStack(spacing: 8) {
                        TextField("Repetitions", text: $reps)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .cornerRadius(10)

                        TextField("Weight", text: $weight)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            addSet()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(AppColors.bluePrimary)
                                .font(.title3)
                        }
                        .disabled(reps.isEmpty || weight.isEmpty)
                    }
                    .padding(.top, 6)
                }
                .animation(.spring(), value: sets.count)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppColors.bluePrimary.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 0.5)
        )
    }

    // MARK: - Logic
    private func addSet() {
        guard let repsInt = Int16(reps), let weightVal = Double(weight) else { return }
        let newSet = WorkoutSetEntity(context: context)
        newSet.id = UUID()
        newSet.reps = repsInt
        newSet.weight = weightVal
        newSet.timestamp = Date()
        exercise.addToSets(newSet)
        try? context.save()
        reps = ""
        weight = ""
    }

    private func deleteSet(_ set: WorkoutSetEntity) {
        context.delete(set)
        try? context.save()
    }
}

#Preview {
    let ctx = Persistence.preview.container.viewContext
    let ex = ExerciseEntity(context: ctx)
    ex.name = "Bench Press"

    let s1 = WorkoutSetEntity(context: ctx)
    s1.id = UUID(); s1.reps = 10; s1.weight = 135; s1.timestamp = Date()

    let s2 = WorkoutSetEntity(context: ctx)
    s2.id = UUID(); s2.reps = 8; s2.weight = 145; s2.timestamp = Date().addingTimeInterval(120)

    ex.addToSets(s1)
    ex.addToSets(s2)

    return ExerciseRow(exercise: ex)
        .environment(\.managedObjectContext, ctx)
        .preferredColorScheme(.dark)
        .padding()
}

//
//  SetRow.swift
//  spotter
//
//  Created by Kevin Hernandez-Nino on 11/9/25.
//

import SwiftUI
import CoreData

struct SetRow: View {
    let set: WorkoutSetEntity
    var onDelete: (WorkoutSetEntity) -> Void

    var body: some View {
        HStack {
            Text("\(Int(set.reps)) reps × \(Int(set.weight)) lbs")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Button {
                onDelete(set)
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.8))
            }
        }
        .padding(.vertical, 2)
    }
}

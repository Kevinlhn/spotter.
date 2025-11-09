//
//  NewWorkout.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 11/8/25.
//

import SwiftUI

struct NewWorkout: View {
    @ObservedObject var viewModel: WorkoutViewModel
    var onDismiss: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    @State private var workoutName: String = ""
    @State private var notes: String = ""
    @State private var showSaved = false

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                // MARK: - Header
                Text("new workout.")
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(AppColors.bluePrimary)

                // MARK: - Card Container
                VStack(spacing: 20) {
                    SpotterTextField("Workout Name", text: $workoutName, systemImage: "dumbbell.fill")
                    SpotterTextField("Notes (optional)", text: $notes, systemImage: "square.and.pencil")

                    Divider().padding(.vertical, 4)

                    HStack(spacing: 12) {
                        Button("Cancel") {
                            withAnimation(.spring()) { onDismiss() }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.primary)

                        Button {
                            saveWorkout()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.bluePrimary)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        }
                    }

                    if showSaved {
                        SavedMessageView(message: "Workout Saved!")
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 40)
                .background(.ultraThinMaterial)
                .cornerRadius(40)
                .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
                .frame(maxWidth: 450)
                .transition(.scale.combined(with: .opacity))
            }
            .padding()
        }
    }

    // MARK: - Save Workout
    private func saveWorkout() {
        viewModel.createWorkout(
            name: workoutName.isEmpty ? "Untitled Workout" : workoutName,
            notes: notes
        )

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showSaved = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.easeOut(duration: 0.3)) {
                showSaved = false
                onDismiss()
            }
        }
    }
}

// MARK: - Reusable Text Field
private struct SpotterTextField: View {
    var placeholder: String
    @Binding var text: String
    var systemImage: String

    init(_ placeholder: String, text: Binding<String>, systemImage: String) {
        self.placeholder = placeholder
        self._text = text
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
            TextField(placeholder, text: $text)
                .font(.subheadline)
                .textInputAutocapitalization(.words)
        }
        .padding(12)
        .background(.secondary)
        .cornerRadius(12)
    }
}

// MARK: - Saved Message
private struct SavedMessageView: View {
    var message: String

    var body: some View {
        Text(message)
            .font(.headline)
            .padding(.vertical, 8)
            .padding(.horizontal, 20)
            .background(.ultraThinMaterial)
            .cornerRadius(25)
            .shadow(radius: 5)
            .transition(.scale.combined(with: .opacity))
    }
}

#Preview {
    ZStack {
        SpotterBackground()
        NewWorkout(viewModel: WorkoutViewModel(), onDismiss: {})
            .environment(\.colorScheme, .dark)
    }
}


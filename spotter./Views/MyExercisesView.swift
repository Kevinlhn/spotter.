//
//  MyExercisesView.swift
//  spotter.
//
//  Manage the exercise library:
//  - View all exercises
//  - Rename / change muscle
//  - Favorite / unfavorite
//  - Delete
//

import SwiftUI
import CoreData

struct MyExercisesView: View {
    @StateObject private var viewModel = ExerciseTemplateViewModel()
    @State private var searchText: String = ""

    @State private var editingTemplate: ExerciseTemplateEntity? = nil
    @State private var showEditSheet: Bool = false

    var body: some View {
        ZStack {
            SpotterBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                List {
                    if filteredTemplates.isEmpty {
                        emptyStateRow
                    } else {
                        ForEach(filteredTemplates) { template in
                            row(for: template)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle("My exercises")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search by name or muscle")
        .onAppear {
            viewModel.loadTemplates()
        }
        .sheet(isPresented: $showEditSheet) {
            if let template = editingTemplate {
                NavigationStack {
                    ExerciseTemplateEditSheet(
                        template: template,
                        onSave: { name, muscle in
                            viewModel.updateTemplate(template, name: name, primaryMuscle: muscle)
                            showEditSheet = false
                            editingTemplate = nil
                        },
                        onCancel: {
                            showEditSheet = false
                            editingTemplate = nil
                        }
                    )
                }
            }
        }
    }

    // MARK: - Derived

    private var filteredTemplates: [ExerciseTemplateEntity] {
        viewModel.filteredTemplates(searchText: searchText)
    }

    // MARK: - UI Pieces

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Exercise library")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("Your movements, saved.")
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyStateRow: some View {
        VStack(spacing: 8) {
            Text("No exercises yet.")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Create workouts and save custom moves, or add them directly to your library.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 40)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private func row(for template: ExerciseTemplateEntity) -> some View {
        Button {
            editingTemplate = template
            showEditSheet = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    if let muscle = template.primaryMuscle, !muscle.isEmpty {
                        Text(muscle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if template.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                viewModel.toggleFavorite(template)
            } label: {
                Label(template.isFavorite ? "Unfavorite" : "Favorite",
                      systemImage: template.isFavorite ? "star.slash" : "star")
            }
            .tint(.yellow)

            Button(role: .destructive) {
                viewModel.deleteTemplate(template)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .listRowBackground(Color.clear)
    }
}

// MARK: - Edit Sheet

private struct ExerciseTemplateEditSheet: View {
    let template: ExerciseTemplateEntity
    let onSave: (String, String?) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var muscle: String = ""

    var body: some View {
        Form {
            Section(header: Text("Exercise")) {
                TextField("Name", text: $name)
                TextField("Primary muscle", text: $muscle)
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Edit exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onCancel()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let trimmedName = name.trimmingCharacters(in: .whitespaces)
                    guard !trimmedName.isEmpty else { return }
                    let trimmedMuscle = muscle.trimmingCharacters(in: .whitespaces)
                    onSave(trimmedName, trimmedMuscle.isEmpty ? nil : trimmedMuscle)
                }
            }
        }
        .onAppear {
            name = template.name
            muscle = template.primaryMuscle ?? ""
        }
    }
}

#Preview {
    NavigationStack {
        MyExercisesView()
            .environment(\.managedObjectContext, Persistence.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
}
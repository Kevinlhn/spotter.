//
//  ExerciseLibraryPicker.swift
//  spotter.
//
//  Picker for exercises from the user's library.
//

import SwiftUI

struct ExerciseLibraryPicker: View {
    let onSelect: (ExerciseTemplateEntity) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ExerciseTemplateViewModel()
    @State private var searchText: String = ""

    var body: some View {
        List {
            ForEach(viewModel.filteredTemplates(searchText: searchText)) { template in
                Button {
                    onSelect(template)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(template.name)
                            .font(.subheadline.weight(.medium))
                        if let muscle = template.primaryMuscle, !muscle.isEmpty {
                            Text(muscle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search exercises or muscles")
        .navigationTitle("Exercise library")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .onAppear {
            viewModel.loadTemplates()
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseLibraryPicker { _ in }
            .environment(\.managedObjectContext, Persistence.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
}
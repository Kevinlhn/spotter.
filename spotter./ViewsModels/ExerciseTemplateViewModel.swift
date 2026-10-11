//
//  ExerciseTemplateViewModel.swift
//  spotter.
//

import Foundation
import Combine

final class ExerciseTemplateViewModel: ObservableObject {
    @Published var templates: [ExerciseTemplateEntity] = []

    private let manager = ExerciseTemplateDataManager.shared

    func loadTemplates() {
        manager.seedDefaultsIfNeeded()
        templates = manager.fetchAllTemplates()
    }

    func filteredTemplates(searchText: String) -> [ExerciseTemplateEntity] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return templates }

        return templates.filter { template in
            template.name.localizedCaseInsensitiveContains(query) ||
            (template.primaryMuscle?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    func addCustomTemplate(name: String, primaryMuscle: String?) {
        _ = manager.createTemplate(name: name, primaryMuscle: primaryMuscle, isCustom: true)
        loadTemplates()
    }

    func deleteTemplate(_ template: ExerciseTemplateEntity) {
        manager.deleteTemplate(template)
        loadTemplates()
    }
}
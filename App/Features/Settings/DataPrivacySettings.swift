import SwiftUI

struct DataPrivacySettings: View {
    @EnvironmentObject private var store: TrainingStore
    @State private var export: WorkoutExport?
    @State private var exportError: String?
    private var hasData: Bool { !store.workouts.isEmpty || !store.library.isEmpty }

    private struct WorkoutExport: Identifiable {
        let id = UUID()
        let url: URL
    }

    var body: some View {
        SettingsForm(title: "Data & privacy") {
            Section {
                SettingsRow(title: "Stored on this device", symbol: "iphone",
                            detail: "Your workouts and exercise library are saved locally. Spotter does not require an account or upload your training log to a server.")
                LabeledContent("Workout records", value: "\(store.workouts.count)")
                LabeledContent("Library exercises", value: "\(store.library.count)")
            } header: { Text("Storage") } footer: {
                Text("Deleting the app removes its local data. Device backups are managed by iOS and your device settings.")
            }
            Section {
                Button(action: shareExport) {
                    SettingsRow(title: "Export workout data", symbol: "square.and.arrow.up", detail: "Create and share a fresh JSON copy")
                }
                .disabled(!hasData)
                .accessibilityIdentifier("export-workout-data")
            } header: { Text("Export") } footer: {
                Text(hasData
                     ? "Includes your workouts, saved templates, exercise library, dates, status, targets, units, notes, and logged sets. App preferences are not included. Import is not currently supported."
                     : "Available after you save a workout or exercise.")
            }
        }
        .sheet(item: $export) { item in ShareSheet(items: [item.url]) }
        .alert("Export unavailable", isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
            Button("OK") { exportError = nil }
        } message: { Text(exportError ?? "") }
    }

    private func shareExport() {
        do {
            // Regenerate at the moment of sharing; never reuse a stale snapshot.
            export = WorkoutExport(url: try SpotterExportManager.shared.exportJSONFile(from: store.context))
        } catch { exportError = error.localizedDescription }
    }
}

struct AboutSettings: View {
    private var version: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? "—"
        let build = info["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
    var body: some View {
        SettingsForm(title: "About Spotter") {
            Section {
                SettingsRow(title: "spotter.", symbol: "dumbbell", detail: "A little structure. A stronger you.")
                LabeledContent("Created by", value: "kevinlhn.")
                LabeledContent("Version", value: version)
            }
        }
    }
}

import SwiftUI

struct LibraryScreen: View {
    @Binding var query: String
    @State private var showCustom = false
    var body: some View {
        FeaturePage {
            HStack {
                FeatureHeading(title: "Library", subtitle: "Exercises, technique, and your history")
                Button { showCustom = true } label: {
                    Image(systemName: "plus").frame(width: 44, height: 44).spotterGlass(radius: 22, interactive: true)
                }.accessibilityLabel("Create exercise")
            }
        } content: { ExerciseBrowser(query: $query, onSelect: nil) }
        .sheet(isPresented: $showCustom) { CustomExerciseEditor { _ in } }
    }
}

//
//  Library.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/2/25.
//


import SwiftUI

struct Library: View {
    // Sample data – you can hook this up to your Exercise model later
    @State private var searchText = ""
    let exercises = [
        "Bench Press",
        "Squat",
        "Deadlift",
        "Pull-Up",
        "Plank"
    ]
    
    var filteredExercises: [String] {
        searchText.isEmpty ? exercises : exercises.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            List(filteredExercises, id: \.self) { exercise in
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(.blue)
                    Text(exercise)
                }
            }
            .navigationTitle("Library")
            .searchable(text: $searchText, prompt: "Search exercises")
        }
    }
}

struct Library_Previews: PreviewProvider {
    static var previews: some View {
        Library()
    }
}

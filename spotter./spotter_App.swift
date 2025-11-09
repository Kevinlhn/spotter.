//
//  spotter_App.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 9/25/25.
//

import SwiftUI
import CoreData

@main
struct spotter_App: App {
    let persistenceController = Persistence.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

//
//  TabBar.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/2/25.
//

import Foundation
import SwiftUI

struct TabBar: View {
    
    @State private var selectedTab = 2
    @StateObject var exerciseLibrary = ExerciseLibrary()
    
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // 2. Muscle Map / Progress
            Progress()
                .tabItem { Label("Progress", systemImage: "figure.strengthtraining.functional") }
                .tag(0)
            
            // 3. Calendar / Schedule
            Schedule()
                .tabItem { Label("Schedule", systemImage: "calendar") }
                .tag(1)
                .environmentObject(exerciseLibrary)
            
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(2)
            
            // 4. Exercise Library
            Library()
                .tabItem { Label("Library", systemImage: "books.vertical.fill") }
                .tag(3)
            
            // 5. Profile / Settings
            Profile()
                .tabItem { Label("Profile", systemImage: "person.circle.fill") }
                .tag(4)
        }
        .accentColor(.white)
    }
}

struct TabBar_Previews: PreviewProvider{
    static var previews: some View{
        TabBar()
    }
}


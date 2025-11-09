//
//  ContentView.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 9/25/25.
//
import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 2
    
    var body: some View {
        ZStack {
            SpotterBackground()
            
            TabView(selection: $selectedTab){
                SpotterView()
                    .tabItem {
                        Label("Spotter", systemImage: "brain.head.profile")
                    }.tag(0)
                WorkoutsView()
                    .tabItem {
                        Label("Workouts", systemImage: "figure.strengthtraining.traditional")
                    }.tag(1)
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }.tag(2)
                PerformanceView()
                    .tabItem {
                        Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                    }.tag(3)
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle")
                    }.tag(4)
            }
            .accentColor(.primary)
        }
    }
}

#Preview {
    ContentView()
}

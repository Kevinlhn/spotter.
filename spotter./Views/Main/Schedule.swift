//
//  Schedule.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/2/25.
//

import SwiftUI

struct Schedule: View {
    @EnvironmentObject var exerciseLibrary: ExerciseLibrary
    @State private var selectedDate = Date()
    @State private var showingEditor = false
    @State private var scheduledWorkouts: [Date: [(workout: Workout, tags: [String])]] = [:]
    
    var allExercises: [Exercise] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("spotter.")
                    .foregroundStyle(Color(hex: "1E5A66"))
                    .font(.title)
                    .fontWeight(.bold)
                
                ScrollView {
                    VStack(spacing: 16) {
                        if let workouts = scheduledWorkouts[selectedDate.startOfDay()] {
                            ForEach(workouts, id: \.workout.id) { item in
                                WorkoutCard(workout: item.workout, tags: item.tags)
                            }
                        } else {
                            Text("No workouts scheduled for this day.")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                                .padding()
                        }
                    }
                    .padding(.vertical)
                }
                
                Spacer()
                
                WeeklyCalendar(selectedDate: $selectedDate)
                
                Button {
                    showingEditor = true
                } label: {
                    Label("Add Workout Plan", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "1E5A66"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.bottom)
                .padding(.horizontal)
            }
            .sheet(isPresented: $showingEditor) {
                WorkoutEditor(allExercises: allExercises) { workout, tags in
                    let day = workout.date.startOfDay()
                    if scheduledWorkouts[day] != nil {
                        scheduledWorkouts[day]?.append((workout: workout, tags: tags))
                    } else {
                        scheduledWorkouts[day] = [(workout: workout, tags: tags)]
                    }
                }.environmentObject(exerciseLibrary)
            }
        }
    }
    
}

extension Date {
    func startOfDay() -> Date {
        Calendar.current.startOfDay(for: self)
    }
}

struct Schedule_Previews: PreviewProvider{
    static var previews: some View{
        Schedule()
    }
}


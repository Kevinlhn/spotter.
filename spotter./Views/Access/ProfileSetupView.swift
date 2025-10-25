//
//  ProfileSetupView.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 9/30/25.
//

import SwiftUI

struct ProfileSetupView: View {
    @State private var question = 0
    private let totalQuestions = 8
    @State private var goToWelcome = false
    // Temporary profile data (before saving to model)
    @State private var name = ""
    @State private var age = ""
    @State private var weight = ""
    @State private var height = ""
    @State private var goals: [FitnessGoal] = []
    @State private var activityLevel: ActivityLevel = .sedentary
    @State private var injuries: [Injury] = []
    
    var body: some View {
        VStack {
            // MARK: - Progress Bar
            if question != totalQuestions - 1 {
                ProgressView(value: Double(question + 1), total: Double(totalQuestions))
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "1E5A66")))
                    .padding(.horizontal, 140)
                    .animation(.easeInOut, value: question)
            }
            // MARK: - Question Content
            // Fill remaining space
            ZStack {
                switch question {
                case 0:
                    QTextView(question: "What’s your name?", text: $name, placeholder: "Name:")
                case 1:
                    VStack {
                        Text("When's your birthday?")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color(hex: "1E5A66"))
                            .padding()
                        
                        // Temporary birthday storage
                        @State var birthday: Date = Calendar.current.date(byAdding: .year, value: 0, to: Date()) ?? Date()
                        
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { birthday },
                                set: { newDate in
                                    birthday = newDate
                                    // calculate age from birthday
                                    let now = Date()
                                    let ageComponents = Calendar.current.dateComponents([.year], from: newDate, to: now)
                                    if let calculatedAge = ageComponents.year {
                                        age = "\(calculatedAge)"
                                    }
                                }
                            ),
                            displayedComponents: .date
                        )
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                    }
                case 2:
                    QTextView(question: "Your weight (lbs)?", text: $weight, placeholder: "Enter your weight", keyboard: .decimalPad)
                case 3:
                    QTextView(question: "Your height (cm)?", text: $height, placeholder: "Enter your height", keyboard: .decimalPad)
                case 4:
                    QChoiceView(
                        question: "What are your fitness goals?",
                        choices: FitnessGoal.allCases.map { $0.rawValue.capitalized },
                        allowsMultipleSelection: true
                    ) { selected in
                        goals = selected.compactMap { FitnessGoal(rawValue: $0.lowercased()) }
                    }
                case 5:
                    QChoiceView(
                        question: "What’s your activity level?",
                        choices: ActivityLevel.allCases.map { $0.rawValue.capitalized },
                        allowsMultipleSelection: false
                    ) { selected in
                        if let choice = selected.first {
                            activityLevel = ActivityLevel(rawValue: choice.lowercased()) ?? .sedentary
                        }
                    }
                case 6:
                    QChoiceView(
                        question: "Do you have any injuries?",
                        choices: Injury.allCases.map { $0.rawValue.capitalized },
                        allowsMultipleSelection: true
                    ) { selected in
                        injuries = selected.compactMap { Injury(rawValue: $0.lowercased()) }
                    }
                default:
                    ProfileCard(
                        name: name,
                        age: Int(age) ?? 0,
                        weight: Double(weight) ?? 0,
                        height: Double(height) ?? 0,
                        goals: goals,
                        activityLevel: activityLevel,
                        injuries: injuries
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // ✅ fill remaining space
            // MARK: - Navigation Buttons
            VStack(spacing: 12) {
                if question > 0 {
                    Button("Back") { question -= 1 }
                        .foregroundColor(.gray)
                }
                if question < totalQuestions - 1 {
                    Button(action: { question += 1 }) {
                        Text("Next")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 30/255, green: 90/255, blue: 102/255))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                
                if question == totalQuestions - 1 {
                    Button(action: {
                        goToWelcome = true
                    }) {
                        Text("Save Profile")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(minWidth: 300)
                            .background(Color(hex: "1E5A66"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding(.horizontal, 40)
        }
        .fullScreenCover(isPresented: $goToWelcome) {
            WelcomeView()
        }
    }
}
    
struct ProfileSetupView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSetupView()
    }
}

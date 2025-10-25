//  ProfileCard.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 9/30/25.
//

import SwiftUI

struct ProfileCard: View {
    var name: String
    var age: Int
    var weight: Double
    var height: Double
    var goals: [FitnessGoal]
    var activityLevel: ActivityLevel
    var injuries: [Injury]
    
    var body: some View {
        VStack{
            Spacer()
            Spacer()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with icon and title
                    HStack {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color(hex: "1E5A66"))
                            .cornerRadius(10)
                        Text("Your Profile")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    
                    // Profile info
                    VStack(alignment: .leading, spacing: 12) {
                        infoRow(label: "Name", value: name)
                        infoRow(label: "Age", value: "\(age)")
                        infoRow(label: "Weight", value: "\(weight) lbs")
                        infoRow(label: "Height", value: "\(height) cm")
                        infoRow(label: "Goals", value: goals.isEmpty ? "None" : goals.map { $0.rawValue.capitalized }.joined(separator: ", "))
                        infoRow(label: "Activity", value: activityLevel.rawValue.capitalized)
                        infoRow(label: "Injuries", value: injuries.isEmpty ? "None" : injuries.map { $0.rawValue.capitalized }.joined(separator: ", "))
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "C6DEE2"), lineWidth: 1)
            )
            .cornerRadius(16)
            .shadow(radius: 2)
            .padding()
            Spacer()
            Spacer()
        }
}
    
    @ViewBuilder
    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text("\(label):")
                .fontWeight(.semibold)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct ProfileCard_Previews: PreviewProvider {
    static var previews: some View {
        ProfileCard(
            name: "Kevin Hernandez",
            age: 30,
            weight: 180,
            height: 175,
            goals: [.strength, .hypertrophy, .endurance, .general],
            activityLevel: .active,
            injuries: [.knees, .back, .shoulders]
        )
    }
}

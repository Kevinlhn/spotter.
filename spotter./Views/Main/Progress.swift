//
//  Progress.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/2/25.
//
import SwiftUI

struct Progress: View {
    var body: some View {
            VStack{
                // MARK: - Header
                    Text("spotter.")
                        .foregroundStyle(Color(hex: "1E5A66"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Track your weekly progress")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                
                    
                    MuscleMap()
                        .padding()
                        .shadow(color: Color.black, radius: 8, x: 0, y: 4)
                
                // MARK: - Progress Cards
                    ProgressCard()
                Spacer(minLength: 30)
                }
    }
}

struct Progress_Previews: PreviewProvider {
    static var previews: some View {
        Progress()
    }
}

//
//  NewbieView.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 9/26/25.
//

import SwiftUI

struct NewbieView: View {
    
    var body: some View {
        NavigationView {
                VStack {
                    // Title + Welcome Text
                    VStack{
                        Text("spotter.")
                            .foregroundStyle(Color(hex: "1E5A66"))
                            .font(.system(size: 50, weight: .bold))
                            .fontWeight(.bold)
                        
                        Text("Built to keep you moving forward.")
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 10)
                            .foregroundStyle(Color(hex: "1E5A66"))
                    }
                    
                    // App Logo / Illustration
                    Image(systemName: "figure.strengthtraining.traditional")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundStyle(Color(hex: "1E5A66"))
                        .padding(.bottom, 20)
                    
                    Spacer()
                    // Navigation to Profile Setup
                    NavigationLink(destination: ProfileSetupView()) {
                        Text("Let’s Start")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(minWidth: 300)
                            .background(Color(hex: "1E5A66"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 40)
                    
                    // Sign In Link
                    HStack(spacing: 4) {
                        Text("Already have an account? AWESOME.")
                        Button("Sign in") {
                            // handle sign in
                        }
                        .underline()
                    }
                    .font(.footnote)
                    .foregroundStyle(.gray)
                }
            }
        }
}

struct NewbieView_Previews: PreviewProvider {
    static var previews: some View {
        NewbieView()
    }
}

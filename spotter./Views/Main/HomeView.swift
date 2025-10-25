//
//  HomeView.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 9/26/25.
//
import SwiftUI

struct HomeView: View {
    
    @Environment(\.colorScheme) var colorScheme
    // MARK: - Colors
    private var accentBlue: Color { Color(hex: "486B89") }
    private var bgScheme: Color { (colorScheme == .dark ? .black : .white) }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [bgScheme,accentBlue.opacity(0.2),accentBlue],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            VStack {
                Text("spotter.")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(accentBlue)
                
                Text("Never lift alone.")
                    .font(.caption2)
                    .foregroundColor(accentBlue.opacity(0.7))
            Spacer()
            }
        }
    }
}

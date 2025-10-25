//
//  ProgressCard.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/2/25.
//

import SwiftUI

struct ProgressCard: View {
    var fullBody: Double = 0.7
    var upperBody: Double = 0.55
    var lowerBody: Double = 0.4
    var core: Double = 0.6
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ProgressRow(title: "Full Body", progress: fullBody, highlight: true, color: Color(hex: "1E5A66"))
            ProgressRow(title: "Upper Body", progress: upperBody, color: Color.red)
            ProgressRow(title: "Lower Body", progress: lowerBody, color: Color.green)
            ProgressRow(title: "Core", progress: core, color: Color.yellow)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.white, Color(hex: "E6F0F2")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
        .padding(.horizontal)
    }
}

struct ProgressRow: View {
    var title: String
    var progress: Double
    var highlight: Bool = false
    var color: Color
    
    private var clampedProgress: Double { min(max(progress, 0), 1) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(highlight ? .caption : .caption2)
                    .fontWeight(highlight ? .semibold : .regular)
                    .foregroundColor(color)
                Spacer()
                Text("\(Int(clampedProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: highlight ? 10 : 6)

                Capsule()
                    .fill(LinearGradient(colors: [color.opacity(0.8), color], startPoint: .leading, endPoint: .trailing))
                    .frame(maxWidth: .infinity)
                    .frame(height: highlight ? 10 : 6)
                    .scaleEffect(x: clampedProgress, y: 1, anchor: .leading)
                    .animation(.easeInOut(duration: 0.5), value: clampedProgress)
            }
        }
    }
}

struct ProgressCard_Previews: PreviewProvider {
    static var previews: some View {
        ProgressCard()
    }
}

//
//  QTextView.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 9/30/25.
//

import SwiftUI

struct QTextView: View {
    var question: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboard: UIKeyboardType = .default
    
    var body: some View {
        VStack(spacing: 20) {
            // Question
            Text(question)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(hex: "1E5A66"))
                .padding()
            
            // Input field with glass style
            TextField(placeholder, text: $text)
                .padding()
                .keyboardType(keyboard)
                .foregroundColor(Color(hex: "1E5A66"))
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color(hex: "1E5A66"), lineWidth: 2)
                ).padding(.horizontal)
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .padding()
    }
}

/// BlurView helper to get frosted glass
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

#Preview {
    QTextView(
        question: "What’s your name?",
        text: .constant(""),
        placeholder: "Enter your name"
    )
}

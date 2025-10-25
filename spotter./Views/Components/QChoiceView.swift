//
//  QChoiceView.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 9/30/25.
//
import SwiftUI

struct QChoiceView: View {
    var question: String
    var choices: [String]
    var allowsMultipleSelection: Bool = false
    
    @State private var bounce: Bool = false
    
    @State private var selectedChoices: Set<String> = []
    var onSelection: (([String]) -> Void)?
    
    struct BlurView: UIViewRepresentable {
        var style: UIBlurEffect.Style
        func makeUIView(context: Context) -> UIVisualEffectView {
            return UIVisualEffectView(effect: UIBlurEffect(style: style))
        }
        func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Question
            Text(question)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(hex: "1E5A66"))
                .padding()
            
            Image(systemName: "chevron.down")
                .foregroundColor(Color(hex: "1E5A66"))
                .padding(.top)
                .offset(y: bounce ? 5 : -5)
                .animation(
                    Animation.easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true),
                    value: bounce
                )
                .onAppear {
                    bounce = true
                }
            // Scrollable choices
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(choices, id: \.self) { choice in
                        Button(action: {
                            toggleSelection(for: choice)
                            onSelection?(Array(selectedChoices))
                        }) {
                            HStack {
                                Text(choice)
                                    .font(.body)
                                    .fontWeight(selectedChoices.contains(choice) ? .semibold : .regular)
                                    .foregroundColor(selectedChoices.contains(choice) ? .white :  Color(hex: "1E5A66"))
                                
                                Spacer()
                                
                                if selectedChoices.contains(choice) {
                                    Image(systemName: allowsMultipleSelection ? "checkmark.circle.fill" : "checkmark.circle.fill")
                                        .foregroundColor(.white)
                                        .cornerRadius(100)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    // Frosted glass background
                                    BlurView(style: .systemThinMaterial)
                                    // Accent tint when selected
                                    if selectedChoices.contains(choice) {
                                        Color(hex: "1E5A66")
                                    } else {
                                        Color.white
                                    }
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color(hex: "1E5A66"), lineWidth: 2)
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                    }
                }.padding(.top)
                .padding(.horizontal)
            }
            .frame(maxHeight: 300)
        }
        .padding()
    }
    private func toggleSelection(for choice: String) {
        if allowsMultipleSelection {
            if selectedChoices.contains(choice) {
                selectedChoices.remove(choice)
            } else {
                selectedChoices.insert(choice)
            }
        } else {
            selectedChoices = [choice]
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        QChoiceView(
            question: "Pick your favorite workouts",
            choices: ["Running", "Cycling", "Yoga", "Weights"],
            allowsMultipleSelection: true
        ) { selections in
            print("Selected: \(selections)")
        }
    }
}

//
//  SpotterView.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/29/25.
//

import SwiftUI

struct SpotterView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var messages: [String] = [
        "👋 Hey Kevin! How was your last workout?",
        "Want me to build you a power session today?"
    ]
    @State private var input = ""

    var body: some View {
        ZStack {
            SpotterBackground()

            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(messages, id: \.self) { msg in
                            HStack {
                                Text(msg)
                                    .padding(10)
                                    .background(AppColors.blueLight.opacity(0.15))
                                    .cornerRadius(10)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                }

                HStack {
                    TextField("Ask your coach...", text: $input)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)

                    Button {
                        send()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(AppColors.bluePrimary)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("AI Coach")
    }

    func send() {
        guard !input.isEmpty else { return }
        messages.append(input)
        input = ""
        // TODO: connect to AI backend later
    }
}

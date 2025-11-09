//
//  HomeView.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/29/25.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var showWorkoutList = false
    @State private var showAIChat = false

    var body: some View {
        ZStack {
            SpotterBackground()
                .ignoresSafeArea()

            VStack {
                // MARK: - Header
                VStack(spacing: -5) {
                    Text("spotter.")
                        .font(.system(size: 50, weight: .heavy))
                        .foregroundStyle(AppColors.bluePrimary.gradient)
                        .accessibilityAddTraits(.isHeader)

                    Text("Built to keep you moving forward.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
                // MARK: - AI Coach Button
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showAIChat.toggle()
                    }
                } label: {
                    Label("Talk to your AI spotter.", systemImage: "brain.head.profile")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                }
                .padding(.horizontal)
                .accessibilityHint("Open your AI chat assistant")

                // MARK: - Daily Summary
                VStack(spacing: 16) {
                    Text("Today's Summary")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.white)

                    HStack(spacing: 16) {
                        MetricCard(label: "Calories", value: "620", icon: "flame.fill")
                        MetricCard(label: "Sets", value: "24", icon: "square.grid.3x3.fill")
                        MetricCard(label: "PRs", value: "2", icon: "star.fill")
                    }

                    Button {
                        showWorkoutList = true
                    } label: {
                        Label("Start Workout", systemImage: "figure.strengthtraining.traditional")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.bluePrimary)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(radius: 5)
                    }
                    .accessibilityLabel("Start your workout")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.05))
                )
                .padding()
            }
        }
        .sheet(isPresented: $showWorkoutList) {
            // WorkoutListView()
        }
        .sheet(isPresented: $showAIChat) {
            // CoachChatView()
        }
    }
}

// MARK: - MetricCard Component
struct MetricCard: View {
    var label: String
    var value: String
    var icon: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .padding(.bottom, 2)
            }

            Text(value)
                .font(.title.bold())
                .foregroundColor(.white)

            Text(label.uppercased())
                .font(.caption2)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppColors.bluePrimary.opacity(0.2))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

#Preview {
    HomeView()
}

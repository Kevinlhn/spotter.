//
//  ProfileView.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 12/13/25.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("profile.goal") private var goal: Goal = .hypertrophy
    @AppStorage("profile.sessionsPerWeek") private var sessionsPerWeek: Int = 4
    @AppStorage("profile.units") private var units: Units = .imperial
    @AppStorage("profile.aiTone") private var aiTone: AITone = .direct

    @State private var showDeleteConfirm = false
    @State private var showExportSheet = false

    var body: some View {
        ZStack {
            SpotterBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    header

                    SpotterPanel(style: .hero) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("GOALS")
                                .font(.caption2.weight(.semibold))
                                .tracking(1.3)
                                .foregroundStyle(.secondary)

                            Picker("Goal", selection: $goal) {
                                ForEach(Goal.allCases, id: \.self) { g in
                                    Text(g.title).tag(g)
                                }
                            }
                            .pickerStyle(.segmented)

                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Sessions / week".uppercased())
                                        .font(.caption2.weight(.semibold))
                                        .tracking(1.2)
                                        .foregroundStyle(.secondary)
                                    Text("\(sessionsPerWeek)")
                                        .font(.system(size: 20, weight: .bold))
                                }

                                Spacer()

                                Stepper("", value: $sessionsPerWeek, in: 1...7)
                                    .labelsHidden()
                            }
                        }
                    }

                    SpotterPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PREFERENCES")
                                .font(.caption2.weight(.semibold))
                                .tracking(1.3)
                                .foregroundStyle(.secondary)

                            HStack {
                                Label("Units", systemImage: "ruler")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Picker("Units", selection: $units) {
                                    Text("Imperial").tag(Units.imperial)
                                    Text("Metric").tag(Units.metric)
                                }
                                .pickerStyle(.menu)
                            }

                            Divider().opacity(0.15)

                            HStack {
                                Label("Coach tone", systemImage: "sparkles")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Picker("AI tone", selection: $aiTone) {
                                    ForEach(AITone.allCases, id: \.self) { tone in
                                        Text(tone.title).tag(tone)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                    }

                    SpotterPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DATA & PRIVACY")
                                .font(.caption2.weight(.semibold))
                                .tracking(1.3)
                                .foregroundStyle(.secondary)

                            Button {
                                showExportSheet = true
                            } label: {
                                row(icon: "square.and.arrow.up", title: "Export my data", subtitle: "Download a file of your workouts")
                            }
                            .buttonStyle(.plain)

                            Divider().opacity(0.15)

                            Button {
                                // TODO: implement share sheet once export exists
                                showExportSheet = true
                            } label: {
                                row(icon: "square.and.arrow.up.on.square", title: "Share data", subtitle: "Send your export to a coach")
                            }
                            .buttonStyle(.plain)

                            Divider().opacity(0.15)

                            Button(role: .destructive) {
                                showDeleteConfirm = true
                            } label: {
                                row(icon: "trash", title: "Delete all data", subtitle: "This cannot be undone", destructive: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    SpotterPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ABOUT")
                                .font(.caption2.weight(.semibold))
                                .tracking(1.3)
                                .foregroundStyle(.secondary)

                            row(icon: "info.circle", title: "Version", subtitle: Bundle.main.appVersionString)
                        }
                    }

                    Spacer(minLength: 12)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .padding(10)
                        .background(Circle().fill(Color.white.opacity(0.06)))
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("PROFILE")
                    .font(.caption.weight(.bold))
                    .tracking(1.8)
                    .foregroundStyle(.secondary)
            }
        }
        .confirmationDialog("Delete all data?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Everything", role: .destructive) {
                // TODO: wire to Core Data wipe (see note below)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete your workouts, exercises, and sets from this device.")
        }
        .sheet(isPresented: $showExportSheet) {
            NavigationStack {
                ExportDataView()
            }
        }
    }

    private var header: some View {
        SpotterPanel(style: .hero) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 52, height: 52)
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.10), lineWidth: 1))

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Your Profile")
                        .font(.system(size: 18, weight: .bold))
                    Text("Set goals • control data • tune your coach")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }

    private func row(icon: String, title: String, subtitle: String, destructive: Bool = false) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 34, height: 34)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.10), lineWidth: 1))

                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(destructive ? AnyShapeStyle(Color.red) : AnyShapeStyle(.secondary))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(destructive ? Color.red : Color.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary.opacity(0.8))
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }
}

// MARK: - Export placeholder (wire later)

private struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            SpotterBackground().ignoresSafeArea()
            VStack(spacing: 14) {
                SpotterPanel(style: .hero) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("EXPORT")
                            .font(.caption2.weight(.semibold))
                            .tracking(1.3)
                            .foregroundStyle(.secondary)
                        Text("Export coming next")
                            .font(.system(size: 18, weight: .bold))
                        Text("We’ll generate a JSON/CSV file from Core Data and let you share/save it.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.caption.weight(.bold))
                        .tracking(1.4)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Models

private enum Goal: String, CaseIterable {
    case strength
    case hypertrophy
    case weightLoss
    case athletic

    var title: String {
        switch self {
        case .strength: return "Strength"
        case .hypertrophy: return "Size"
        case .weightLoss: return "Cut"
        case .athletic: return "Athletic"
        }
    }
}

private enum Units: String {
    case imperial
    case metric
}

private enum AITone: String, CaseIterable {
    case direct
    case supportive
    case savage

    var title: String {
        switch self {
        case .direct: return "Direct"
        case .supportive: return "Supportive"
        case .savage: return "Savage"
        }
    }
}

// MARK: - App Version helper

private extension Bundle {
    var appVersionString: String {
        let v = infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
    }
}

// MARK: - Local SpotterPanel (delete if you already have a shared one)

private struct SpotterPanel<Content: View>: View {
    enum Style { case normal, hero }
    let style: Style
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder let content: () -> Content

    init(style: Style = .normal, @ViewBuilder content: @escaping () -> Content) {
        self.style = style
        self.content = content
    }

    var body: some View {
        content()
            .padding(style == .hero ? 16 : 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .overlay(border)
            .clipShape(RoundedRectangle(cornerRadius: style == .hero ? 26 : 22, style: .continuous))
    }

    private var background: some View {
        ZStack {
            RoundedRectangle(cornerRadius: style == .hero ? 26 : 22, style: .continuous)
                .fill(AppColors.scheme(for: colorScheme).opacity(style == .hero ? 0.45 : 0.35))

            if style == .hero {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppColors.bluePrimary.opacity(0.22), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: style == .hero ? 26 : 22, style: .continuous)
            .strokeBorder(Color.white.opacity(style == .hero ? 0.14 : 0.10), lineWidth: 1)
    }
}
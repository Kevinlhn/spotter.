//
//  AppColors.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/25/25.
//

import SwiftUI

enum AppColors {
    // Base palette
    static let bluePrimary: Color = Color(hex: "3A5A7A")
    static let blueLight: Color = Color(hex: "A7B6C4")
    static let blueDark: Color = Color(hex: "233A50")

    // Scheme-aware helpers
    static func scheme(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? blueDark : blueLight
    }

    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .black : .white
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// Parametric mathematical wave shape
struct ParametricWaveShape: Shape {
    var a: CGFloat
    var b: CGFloat
    var c: CGFloat
    var upwardBias: CGFloat = 0.0
    var phase: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height / 2
        let step = CGFloat.pi / 180
        var x: CGFloat = 0

        path.move(to: CGPoint(x: 0, y: height))

        for angle in stride(from: 0 as CGFloat, to: 2 * .pi, by: step) {
            let normalizedX = CGFloat(angle) / (2 * CGFloat.pi)
            x = normalizedX * width

            let waveY = sin(angle * a + phase) * 40
                     + cos(angle * b + phase) * 20
                     + sin(angle * c * 2 + phase) * 10

            let upwardY = height - (upwardBias * normalizedX * height)
            let y = upwardY + waveY
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
    }

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
}

struct SpotterBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var phase: CGFloat = 0.0
    
    // 👇 Randomized parameters (only generated once)
    @State private var wave1 = (a: CGFloat.random(in: 0.5...2.0),
                                b: CGFloat.random(in: 0.5...2.0),
                                c: CGFloat.random(in: 0.3...1.5))
    @State private var wave2 = (a: CGFloat.random(in: 0.5...2.0),
                                b: CGFloat.random(in: 0.5...2.0),
                                c: CGFloat.random(in: 0.3...1.5))
    @State private var wave3 = (a: CGFloat.random(in: 0.5...2.0),
                                b: CGFloat.random(in: 0.5...2.0),
                                c: CGFloat.random(in: 0.3...1.5))

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    AppColors.bluePrimary,
                    AppColors.scheme(for: colorScheme).opacity(0.5),
                    AppColors.background(for: colorScheme)
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()

            // Wavy layers
            Group {
                ParametricWaveShape(a: wave1.a, b: wave1.b, c: wave1.c, phase: phase)
                    .stroke(AppColors.blueLight.opacity(0.5), lineWidth: 1)
                    .blur(radius: 3)
                    .offset(y: 250)

                ParametricWaveShape(a: wave2.a, b: wave2.b, c: wave2.c, phase: phase * 1.2)
                    .stroke(AppColors.bluePrimary.opacity(0.5), lineWidth: 1)
                    .blur(radius: 2)
                    .offset(y: 200)

                ParametricWaveShape(a: wave3.a, b: wave3.b, c: wave3.c, phase: phase * 1.5)
                    .stroke(AppColors.blueDark.opacity(0.5), lineWidth: 1)
                    .blendMode(.overlay)
                    .offset(y: 150)
            }
            .scaleEffect(1.25)

            // Subtle radial glow
            RadialGradient(
                colors: [.black.opacity(0.25), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 600
            )
            .ignoresSafeArea()
        }
        .onAppear {
            // Animate continuously
            withAnimation(.linear(duration: 50).repeatForever(autoreverses: true)) {
                phase = .pi * 2
            }
        }
    }
}

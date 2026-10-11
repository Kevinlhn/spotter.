import SwiftUI

struct SpotterWallpaper: View {

    @Environment(\.accessibilityReduceTransparency)
    private var reduceTransparency

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                base

                if !reduceTransparency {
                    atmosphere(
                        size: proxy.size
                    )
                }
            }
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }

    // MARK: - Base

    private var base: some View {
        SpotterStyle.background
    }

    // MARK: - Atmosphere

    private func atmosphere(
        size: CGSize
    ) -> some View {
        RadialGradient(
            colors: [
                SpotterStyle.ambient,
                .clear
            ],
            center: .topLeading,
            startRadius: 0,
            endRadius: max(
                size.width,
                size.height
            )
        )
    }
}

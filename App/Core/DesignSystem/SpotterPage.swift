import SwiftUI

/// Stable navigation/header chrome with a flexible content region. Lists own their scrolling.
struct FeaturePage<Header: View, Content: View>: View {
    @ViewBuilder var header: () -> Header
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header().padding(.horizontal, 20)
            content().frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding(.top, 8)
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(SpotterWallpaper())
        .foregroundStyle(SpotterStyle.text)
    }
}

/// Fixed when content fits; only its content region scrolls for small heights or accessibility type.
struct CompactContent<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        GeometryReader { geometry in
            ViewThatFits(in: .vertical) {
                content().frame(width: geometry.size.width).fixedSize(horizontal: false, vertical: true)
                ScrollView { content().frame(width: geometry.size.width) }.scrollBounceBehavior(.basedOnSize)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
    }
}

struct FeatureHeading: View {
    @Environment(\.dynamicTypeSize) private var textSize
    let title: String
    var subtitle: String = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(.title, design: .rounded).weight(.semibold)).tracking(-0.5).accessibilityAddTraits(.isHeader)
            if !subtitle.isEmpty && !textSize.isAccessibilitySize { Text(subtitle).font(.caption).foregroundStyle(SpotterStyle.secondaryText) }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// For a focused, variable-length detail document, never the primary tab shell.
struct SpotterPage<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18, content: content)
                .padding(20).frame(maxWidth: 700).frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(SpotterWallpaper())
        .foregroundStyle(SpotterStyle.text)
    }
}

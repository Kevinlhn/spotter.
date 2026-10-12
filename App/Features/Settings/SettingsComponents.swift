import SwiftUI

/// Navigation stays outside the scrolling form, including at accessibility sizes.
struct SettingsForm<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content
    var body: some View {
        Form { content().listRowBackground(SpotterStyle.raisedSurface) }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background { SpotterWallpaper()}
            .foregroundStyle(SpotterStyle.text)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsRow: View {
    let title: String
    let symbol: String
    var detail: String = ""
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            SpotterRowIcon(symbol: symbol)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).foregroundStyle(SpotterStyle.text)
                if !detail.isEmpty { Text(detail).font(.caption).foregroundStyle(SpotterStyle.secondaryText) }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
    }
}

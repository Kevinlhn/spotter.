import SwiftUI

/// Let the native material supply depth. Only primary actions need a stronger
/// blue fill; passive panels and rows avoid stacking heavy borders and shadows.
struct SpotterGlass: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    var radius: CGFloat = 24
    var highlighted = false
    var interactive = false

    private var dark: Bool { colorScheme == .dark }
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: radius, style: .continuous) }
    private var glassTint: Color {
        highlighted ? SpotterStyle.accent : SpotterStyle.blueLight.opacity(dark ? 0.10 : 0.06)
    }
    private var solidFill: Color {
        if highlighted { return SpotterStyle.accent }
        return SpotterStyle.raisedSurface
    }

    func body(content: Content) -> some View {
        content
            .background {
                shape.fill(reduceTransparency ? solidFill : highlighted ? SpotterStyle.accent.opacity(0.90) : .clear)
                    .allowsHitTesting(false)
            }
            .glassEffect(reduceTransparency ? .identity : .regular.tint(glassTint).interactive(interactive), in: shape)
            .overlay {
                if contrast == .increased {
                    shape.strokeBorder(highlighted ? Color.white.opacity(0.65) : SpotterStyle.foregroundAccent.opacity(0.55), lineWidth: 1)
                        .allowsHitTesting(false)
                }
            }
            .shadow(color: (dark ? Color.black : SpotterStyle.blueDark).opacity(highlighted ? 0.12 : interactive ? 0.055 : 0.025), radius: highlighted ? 10 : 6, x: 0, y: highlighted ? 4 : 2)
    }
}

/// A quiet inset treatment for controls already contained by a glass panel.
struct SpotterControl: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    var selected = false
    var radius: CGFloat = 16

    private var fill: Color {
        if selected { return SpotterStyle.accent }
        if reduceTransparency { return SpotterStyle.surface }
        return SpotterStyle.foregroundAccent.opacity(colorScheme == .dark ? 0.13 : 0.075)
    }

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .background { shape.fill(fill).allowsHitTesting(false) }
            .overlay {
                if contrast == .increased {
                    shape.strokeBorder((selected ? Color.white : SpotterStyle.foregroundAccent).opacity(0.45), lineWidth: 1)
                        .allowsHitTesting(false)
                }
            }
    }
}

/// Feedback stays on the label, preserving the button's original hit region.
/// Reduce Motion replaces the small compression with a simple opacity change.
struct SpotterPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .contentShape(Rectangle())
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

extension View {
    func spotterGlass(radius: CGFloat = 24, highlighted: Bool = false, interactive: Bool = false) -> some View {
        modifier(SpotterGlass(radius: radius, highlighted: highlighted, interactive: interactive))
    }

    func spotterControl(selected: Bool = false, radius: CGFloat = 16) -> some View {
        modifier(SpotterControl(selected: selected, radius: radius))
    }
}

struct SpotterRowIcon: View {
    let symbol: String
    var body: some View {
        Image(systemName: symbol)
            .font(.system(.body, design: .rounded).weight(.semibold))
            .foregroundStyle(SpotterStyle.foregroundAccent)
            .frame(width: 40, height: 40)
            .spotterControl(radius: 13)
            .accessibilityHidden(true)
    }
}

struct SpotterChevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
    }
}

struct Eyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased()).font(.caption2.weight(.semibold))
            .tracking(1.2).foregroundStyle(SpotterStyle.secondaryText)
    }
}

struct PageHeading: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: eyebrow)
            Text(title).font(.system(.title, design: .rounded).weight(.semibold)).tracking(-0.6)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle).font(.subheadline).foregroundStyle(SpotterStyle.secondaryText)
        }
    }
}

struct SectionHeading: View {
    @Environment(\.dynamicTypeSize) private var textSize
    let title: String
    var detail: String = ""
    var body: some View {
        if textSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
                titleLabel
                if !detail.isEmpty { detailLabel }
            }
        } else {
            HStack(alignment: .firstTextBaseline) {
                titleLabel
                Spacer()
                if !detail.isEmpty { detailLabel }
            }
        }
    }
    private var titleLabel: some View { Text(title).font(.headline).accessibilityAddTraits(.isHeader) }
    private var detailLabel: some View { Text(detail).font(.caption).foregroundStyle(SpotterStyle.secondaryText).monospacedDigit() }
}

struct Surface<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        content().padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .spotterGlass()
    }
}

struct PrimaryAction: View {
    let title: String
    var icon: String = "arrow.up.right"
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title).font(.headline)
                Spacer(minLength: 8)
                Image(systemName: icon).font(.headline).accessibilityHidden(true)
            }
            .padding(.horizontal, 18).padding(.vertical, 17).foregroundStyle(SpotterStyle.onAccent)
            .spotterGlass(radius: 20, highlighted: true, interactive: true)
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }.buttonStyle(SpotterPressStyle()).accessibilityLabel(title)
    }
}

struct EmptyTrainingState: View {
    let icon: String
    let title: String
    let message: String
    var body: some View {
        Surface {
            VStack(alignment: .leading, spacing: 12) {
                SpotterRowIcon(symbol: icon)
                Text(title).font(.headline)
                Text(message).font(.subheadline).foregroundStyle(SpotterStyle.secondaryText).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

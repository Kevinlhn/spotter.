import SwiftUI

/// The same compact navigation structure as Counter: one glass capsule and a quick-action circle.
struct SpotterDock: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Binding var selection: SpotterTab
    let activeWorkout: WorkoutEntity?
    let onStart: () -> Void
    let onPlan: () -> Void
    let onCreate: () -> Void
    @Namespace private var selectionAnimation

    private let tabs: [SpotterTab] = [.progress, .library, .plan, .today]
    var body: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                HStack(spacing: 0) {
                    ForEach(tabs, id: \.self) { tab in
                        Button {
                            withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.86)) { selection = tab }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: tab.symbol).font(.system(size: 19, weight: .semibold))
                                Text(tab.title).font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundStyle(selection == tab ? SpotterStyle.foregroundAccent : SpotterStyle.secondaryText)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .contentShape(Rectangle())
                            .background {
                                if selection == tab {
                                    Capsule().fill(SpotterStyle.foregroundAccent.opacity(0.14))
                                        .matchedGeometryEffect(id: "selected-tab", in: selectionAnimation)
                                        .allowsHitTesting(false)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(tab.title)
                        .accessibilityIdentifier("tab-" + tab.rawValue)
                        .accessibilityAddTraits(selection == tab ? .isSelected : [])
                    }
                }
                .padding(5)
                .background(reduceTransparency ? SpotterStyle.surface : Color.clear, in: Capsule())
                .glassEffect(reduceTransparency ? .identity : .regular, in: Capsule())
                Menu {
                    Button(activeWorkout == nil ? "Start workout" : "Resume workout", systemImage: "play.fill", action: onStart)
                    Button("Plan workout", systemImage: "calendar.badge.plus", action: onPlan)
                    Button("Create saved workout", systemImage: "square.and.pencil", action: onCreate)
                } label: {
                    Image(systemName: "plus").font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(SpotterStyle.foregroundAccent)
                        .frame(width: 58, height: 58)
                        .background(reduceTransparency ? SpotterStyle.surface : .clear, in: Circle())
                        .glassEffect(reduceTransparency ? .identity : .regular.tint(SpotterStyle.accent.opacity(0.16)).interactive(), in: .circle)
                        .contentShape(Circle())
                }.accessibilityLabel("Quick actions").accessibilityIdentifier("quick-actions")
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .frame(maxWidth: 620)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("spotter-dock")
    }
}

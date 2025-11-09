import SwiftUI
import UIKit

/// A SwiftUI wrapper for `UIVisualEffectView` to present blur and vibrancy effects.
public struct VisualEffectView: UIViewRepresentable {
    public typealias UIViewType = UIVisualEffectView

    public var effect: UIVisualEffect?

    public init(effect: UIVisualEffect?) {
        self.effect = effect
    }

    public func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: effect)
    }

    public func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect
    }
}

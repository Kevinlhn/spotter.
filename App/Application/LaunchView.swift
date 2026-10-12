import SwiftUI
import UIKit
import Combine
import CoreData

@MainActor
final class SpotterLaunchCoordinator: ObservableObject {
    @Published private(set) var store: TrainingStore?
    @Published private(set) var error: String?
    private var isPreparing = false

    func prepare() async {
        guard store == nil, !isPreparing else { return }
        isPreparing = true
        error = nil
        defer { isPreparing = false }

        do {
            let readyStore = try await WorkoutRuntime.shared.store()
            readyStore.reload()
            if let loadError = readyStore.error {
                error = loadError
                return
            }
            // Warm the shared starter library before the Library tab appears.
            _ = TrainingRoutine.starters
            store = readyStore
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct SpotterLaunchView: View {
    @ObservedObject var launch: SpotterLaunchCoordinator
    @Binding var incomingURL: URL?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("spotter.appearance") private var appearance = "system"
    private let isUITesting = ProcessInfo.processInfo.arguments.contains("UI_TESTING")

    var body: some View {
        ZStack {
            if launch.store == nil { SpotterWallpaper().ignoresSafeArea() }
            if let store = launch.store {
                TabBar(store: store, incomingURL: $incomingURL)
                    .environment(\.managedObjectContext, store.context)
                    .transition(.opacity)
                    .zIndex(0)
            } else {
                intro
                    .transition(.modifier(
                        active: LaunchDissolve(blur: reduceMotion ? 0 : 10, opacity: 0),
                        identity: LaunchDissolve(blur: 0, opacity: 1)
                    ))
                    .zIndex(1)
            }
        }
        .foregroundStyle(SpotterStyle.text)
        .tint(SpotterStyle.foregroundAccent)
        .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
        .animation(isUITesting ? nil : .easeInOut(duration: reduceMotion ? 0.16 : 0.38), value: launch.store != nil)
    }

    private var intro: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 24)
            VStack(spacing: 18) {
                Image(systemName: "dumbbell.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(SpotterStyle.foregroundAccent)
                    .accessibilityHidden(true)
                Text("by kevinlhn.")
                    .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                    .tracking(-1)
                    .accessibilityIdentifier("launch-signature")
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 28)
            .spotterGlass(radius: 34)

            if let error = launch.error {
                VStack(spacing: 16) {
                    Text("Your workouts couldn’t load.").font(.headline)
                    Text(error).font(.subheadline).foregroundStyle(SpotterStyle.secondaryText)
                        .multilineTextAlignment(.center)
                    Button("Try again") { Task { await launch.prepare() } }
                        .buttonStyle(.glassProminent)
                        .tint(SpotterStyle.accent)
                        .accessibilityIdentifier("retry-launch")
                }
                .padding(24)
                .frame(maxWidth: 380)
                .spotterGlass(radius: 28)
                .accessibilityElement(children: .contain)
            } else {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Preparing your workouts")
            }
            Spacer(minLength: 24)
            Text("SPOTTER")
                .font(.system(.caption, design: .monospaced).weight(.medium))
                .tracking(3)
                .foregroundStyle(SpotterStyle.secondaryText)
                .padding(.bottom, 16)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            FirstLaunchFrame {
                Task { await launch.prepare() }
            }
            .frame(width: 1, height: 1)
            .accessibilityHidden(true)
        }
    }
}

private struct LaunchDissolve: ViewModifier {
    let blur: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content.blur(radius: blur).opacity(opacity)
    }
}

/// Begin initialization after the intro's first drawing pass, without a timer
/// or a minimum branding duration. The asynchronous load can then do its work
/// while SwiftUI keeps the intro and progress indicator responsive.
private struct FirstLaunchFrame: UIViewRepresentable {
    let onReady: () -> Void

    func makeUIView(context: Context) -> FirstDrawView {
        let view = FirstDrawView()
        view.backgroundColor = .clear
        view.isOpaque = false
        view.isUserInteractionEnabled = false
        view.onReady = onReady
        return view
    }

    func updateUIView(_ uiView: FirstDrawView, context: Context) {
        uiView.onReady = onReady
    }

    final class FirstDrawView: UIView {
        var onReady: (() -> Void)?
        private var hasDrawn = false

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window != nil { setNeedsDisplay() }
        }

        override func draw(_ rect: CGRect) {
            guard !hasDrawn else { return }
            hasDrawn = true
            DispatchQueue.main.async { [weak self] in self?.onReady?() }
        }
    }
}

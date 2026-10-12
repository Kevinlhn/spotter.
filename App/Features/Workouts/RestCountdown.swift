import SwiftUI

struct RestCountdown: View {
    @Binding var until: Double
    var body: some View {
        if until > 0 {
            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                let remaining = max(0, Int(ceil(until - timeline.date.timeIntervalSince1970)))
                if remaining > 0 {
                    ViewThatFits(in: .horizontal) {
                        HStack { countdown(remaining); Spacer(); controls }
                        VStack(alignment: .leading, spacing: 4) { countdown(remaining); controls }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 4).spotterControl(radius: 16)
                    .accessibilityElement(children: .contain)
                }
                Color.clear.frame(height: 0)
                    .onChange(of: timeline.date) { _, now in
                        if until > 0 && until <= now.timeIntervalSince1970 { until = 0 }
                    }
            }
        }
    }

    private func countdown(_ seconds: Int) -> some View {
        Label(String(format: "%d:%02d rest", seconds / 60, seconds % 60), systemImage: "timer")
            .font(.subheadline.monospacedDigit().bold())
            .accessibilityLabel("Rest, \(seconds / 60) minutes \(seconds % 60) seconds remaining")
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button { until += 30 } label: { Text("+30s").frame(minWidth: 44, minHeight: 44) }
                .accessibilityLabel("Add 30 seconds of rest")
            Button { until = 0 } label: { Text("Skip").frame(minWidth: 44, minHeight: 44) }
                .accessibilityLabel("Skip rest")
        }.font(.caption.bold()).buttonStyle(.borderless).frame(minHeight: 44)
    }
}

import SwiftUI

/// One quiet, explainable suggestion component shared by planning and the active logger.
struct OverloadSuggestion: View {
    let recommendation: OverloadRecommendation
    let unit: String?
    var entryWeight: Double? = nil
    var entryReps: Int? = nil
    let apply: (OverloadPrescription) -> Void
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(recommendation.scope.rawValue)
                    .font(.caption.weight(.semibold)).foregroundStyle(SpotterStyle.foregroundAccent)
                    .accessibilityIdentifier("suggestion-scope")
                Spacer()
                if let suggested = recommendation.suggested {
                    let inUse = entryWeight == suggested.weight && entryReps == suggested.repRange.lowerBound
                    Button(inUse ? "In use" : "Use Suggestion") { apply(suggested) }
                        .font(.caption.weight(.semibold)).buttonStyle(.borderless)
                        .disabled(inUse).accessibilityIdentifier("use-overload-suggestion")
                }
            }
            if let suggested = recommendation.suggested {
                Text("\(load(suggested.weight)) × \(reps(suggested.repRange))")
                    .font(.subheadline.weight(.semibold)).monospacedDigit()
                    .accessibilityIdentifier("suggestion-target")
            }
            Text(recommendation.reason)
                .font(.caption).foregroundStyle(SpotterStyle.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("suggestion-reason")
            if recommendation.previous != nil {
                DisclosureGroup("Training history", isExpanded: $expanded) {
                    VStack(alignment: .leading, spacing: 5) {
                        if let previous = recommendation.previous { Text("Last: \(summary(previous))") }
                        Text("\(recommendation.confidence.rawValue) · \(recommendation.trend.rawValue) · \(recommendation.sessionCount) completed sessions")
                        if let baseline = recommendation.baseline { Text("Baseline: \(summary(baseline))") }
                        if let best = recommendation.bestRecent { Text("Best recent: \(summary(best))") }
                        Text("Local guidance from your saved sets. Apply only when it feels appropriate.")
                    }.foregroundStyle(SpotterStyle.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 5)
                }.font(.caption).tint(SpotterStyle.foregroundAccent)
            }
        }
        .padding(12)
        .background(SpotterStyle.foregroundAccent.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .contain)
    }
    private func reps(_ range: ClosedRange<Int>) -> String {
        range.lowerBound == range.upperBound ? "\(range.lowerBound) reps" : "\(range.lowerBound)–\(range.upperBound) reps"
    }
    private func load(_ value: Double?) -> String {
        guard let value else { return "Choose load" }
        return value == 0 ? "Bodyweight" : "\(value.formatted(.number.precision(.fractionLength(0...2)))) \(unit ?? "load")"
    }
    private func summary(_ performance: ExercisePerformance) -> String {
        if let weight = performance.uniformLoad {
            return "\(load(weight)) × " + performance.sets.map { String($0.reps) }.joined(separator: ", ")
        }
        return performance.sets.map { "\(load($0.weight)) × \($0.reps)" }.joined(separator: "; ")
    }
}

//
//  StepGoalSettingsView.swift
//  StepOrbit
//
//  Created by Francisco Roldán on 26/10/2026.
//



import SwiftUI

/// Goal editor modeled on the Activity app's "Change Move Goal" screen:
/// large value, − / + buttons and Digital Crown. Changes are only applied
/// when the user confirms, so the complication reloads once per edit.
struct StepGoalSettingsView: View {

    private static let range = 500.0...50_000.0
    private static let step = 500.0
    private static let suggestedGoal = 10_000

    let onSave: (Int?) -> Void

    private let hasGoal: Bool

    @State private var crownValue: Double

    @Environment(\.dismiss) private var dismiss

    init(goal: Int?, onSave: @escaping (Int?) -> Void) {
        self.onSave = onSave
        self.hasGoal = goal != nil
        _crownValue = State(
            initialValue: Double(goal ?? Self.suggestedGoal)
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                HStack(spacing: 4) {
                    adjustButton(systemImage: "minus", delta: -Self.step)

                    VStack(spacing: 0) {
                        Text(goal, format: .number)
                            .font(.system(size: 34, weight: .semibold, design: .rounded))
                            .contentTransition(.numericText(value: Double(goal)))
                            .animation(.snappy, value: goal)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)

                        Text("goal.unit")
                            .font(.caption2.weight(.semibold))
                            .textCase(.uppercase)
                            .foregroundStyle(Color.accentColor)
                    }
                    .frame(maxWidth: .infinity)

                    adjustButton(systemImage: "plus", delta: Self.step)
                }
                .focusable()
                .digitalCrownRotation(
                    $crownValue,
                    from: Self.range.lowerBound,
                    through: Self.range.upperBound,
                    by: Self.step,
                    sensitivity: .medium,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )
                .focusEffectDisabled()

                Button("common.save") {
                    onSave(goal)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)

                if hasGoal {
                    Button("goal.remove", role: .destructive) {
                        onSave(nil)
                        dismiss()
                    }
                    .font(.footnote)
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("goal.shortTitle")
        }
    }

    /// Crown values are snapped to the step so the label never shows
    /// intermediate numbers while the crown is spinning.
    private var goal: Int {
        Int((crownValue / Self.step).rounded() * Self.step)
    }

    private func adjustButton(systemImage: String, delta: Double) -> some View {
        let newValue = crownValue + delta

        return Button {
            crownValue = min(max(newValue, Self.range.lowerBound), Self.range.upperBound)
        } label: {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .tint(Color.accentColor)
        .frame(width: 44, height: 44)
        .disabled(!Self.range.contains(newValue))
        .sensoryFeedback(.selection, trigger: goal)
    }
}

#Preview {
    StepGoalSettingsView(goal: 8_000) { _ in }
}

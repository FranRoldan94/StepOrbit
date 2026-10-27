//
//  StepGoalSettingsView.swift
//  StepOrbit
//
//  Created by Francisco Roldán on 26/10/2026.
//



import SwiftUI

/// Goal picker presented as a sheet. Changes are only applied when the
/// user confirms, so the complication reloads once per edit.
struct StepGoalSettingsView: View {

    private static let noGoal = 0
    private static let suggestedGoal = 10_000
    private static let options = Array(stride(from: 500, through: 50_000, by: 500))

    let onSave: (Int?) -> Void

    @State private var selection: Int

    @Environment(\.dismiss) private var dismiss

    init(goal: Int?, onSave: @escaping (Int?) -> Void) {
        self.onSave = onSave
        _selection = State(
            initialValue: goal ?? Self.suggestedGoal
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 4) {
                Picker("goal.title", selection: $selection) {
                    Text("goal.none")
                        .tag(Self.noGoal)

                    ForEach(Self.options, id: \.self) { option in
                        Text(option, format: .number)
                            .tag(option)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()

                Text("goal.unit")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("goal.shortTitle")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save", systemImage: "checkmark") {
                        onSave(selection == Self.noGoal ? nil : selection)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    StepGoalSettingsView(goal: 8_000) { _ in }
}

//
//  StepGoalSettingsView.swift
//  StepOrbit
//
//  Created by Francisco Roldán on 26/10/2026.
//



import SwiftUI
import WidgetKit

struct StepGoalSettingsView: View {

    @State private var goal: Int?
    @State private var draftGoal: Int

    private let store = StepGoalStore()

    init() {
        let savedGoal = StepGoalStore().getGoal()

        _goal = State(initialValue: savedGoal)
        _draftGoal = State(
            initialValue: savedGoal ?? 10_000
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Label(
                "Objetivo diario",
                systemImage: "target"
            )
            .font(.headline)
            .foregroundStyle(Color.accentColor)

            Toggle(
                "Activar objetivo",
                isOn: Binding(
                    get: { goal != nil },
                    set: { enabled in
                        saveGoal(enabled ? draftGoal : nil)
                    }
                )
            )

            if goal != nil {
                Stepper(
                    value: $draftGoal,
                    in: 500...50_000,
                    step: 500
                ) {
                    Text(
                        draftGoal,
                        format: .number
                    )
                    .font(.headline)
                }
                .task(id: draftGoal) {
                    // Debounce: save once the crown stops moving.
                    guard draftGoal != goal else {
                        return
                    }

                    try? await Task.sleep(for: .milliseconds(600))

                    guard !Task.isCancelled else {
                        return
                    }

                    saveGoal(draftGoal)
                }
            }
        }
        .padding(12)
        .background(
            .white.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    private func saveGoal(_ newGoal: Int?) {
        guard newGoal != goal else {
            return
        }

        goal = newGoal
        store.setGoal(newGoal)

        WidgetCenter.shared.reloadTimelines(
            ofKind: WidgetKind.steps
        )
    }
}

//
//  StepOrbitWidgets.swift
//  StepOrbitWidgets
//
//  Created by Francisco Roldán on 26/10/2026.
//


import SwiftUI
import WidgetKit

struct StepOrbitWidgets: Widget {

    let kind = WidgetKind.steps

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: StepsProvider()
        ) { entry in
            StepsComplicationView(entry: entry)
        }
        .configurationDisplayName("StepOrbit")
        .description(Text("widget.description"))
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner,
            .accessoryInline
        ])
    }
}


#Preview("Circular", as: .accessoryCircular) {
    StepOrbitWidgets()
} timeline: {
    StepsEntry.previewNoGoal
    StepsEntry.previewInProgress
    StepsEntry.previewGoalReached
}

#Preview("Rectangular", as: .accessoryRectangular) {
    StepOrbitWidgets()
} timeline: {
    StepsEntry.previewNoGoal
    StepsEntry.previewInProgress
    StepsEntry.previewGoalReached
}

#Preview("Corner", as: .accessoryCorner) {
    StepOrbitWidgets()
} timeline: {
    StepsEntry.previewNoGoal
    StepsEntry.previewInProgress
    StepsEntry.previewGoalReached
}

#Preview("Inline", as: .accessoryInline) {
    StepOrbitWidgets()
} timeline: {
    StepsEntry.previewNoGoal
    StepsEntry.previewInProgress
    StepsEntry.previewGoalReached
}

private extension StepsEntry {
    static let previewNoGoal = StepsEntry(date: .now, steps: 1_523, goal: nil)
    static let previewInProgress = StepsEntry(date: .now, steps: 8_542, goal: 10_000)
    static let previewGoalReached = StepsEntry(date: .now, steps: 12_730, goal: 10_000)
}

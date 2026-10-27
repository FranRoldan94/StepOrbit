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
        .description("Your daily steps and progress")
        .supportedFamilies([.accessoryCircular])
    }
}


#Preview(as: .accessoryCircular) {
    StepOrbitWidgets()
} timeline: {
    StepsEntry(
        date: .now,
        steps: 8542,
        goal: nil
    )

    StepsEntry(
        date: .now,
        steps: 8542,
        goal: 10000
    )

    StepsEntry(
        date: .now,
        steps: 10000,
        goal: 10000
    )
}

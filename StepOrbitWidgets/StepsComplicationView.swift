//
//  StepsComplicationView.swift
//  StepOrbit
//
//  Created by Francisco Roldán on 26/10/2026.
//

import SwiftUI
import WidgetKit

struct StepsComplicationView: View {

    let entry: StepsEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        content
            .containerBackground(.clear, for: .widget)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryRectangular:
            rectangular
        case .accessoryCorner:
            corner
        case .accessoryInline:
            inline
        default:
            circular
        }
    }

    // MARK: - Circular

    private var circular: some View {
        Gauge(
            value: gaugeValue,
            in: 0...Double(entry.target)
        ) {
            statusIcon
        } currentValueLabel: {
            Text(Self.compact(entry.steps))
                .fontDesign(.rounded)
                .fontWeight(.semibold)
                .privacySensitive()
        }
        .gaugeStyle(.accessoryCircular)
        .tint(gaugeGradient)
    }

    // MARK: - Rectangular

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label {
                Text(entry.isGoalReached ? "widget.steps.goalReached" : "widget.steps.title")
            } icon: {
                statusIcon
            }
            .font(.headline)
            .foregroundStyle(Color.accentColor)
            .widgetAccentable()

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(entry.steps, format: .number)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .privacySensitive()

                if entry.hasGoal {
                    Text(verbatim: "/ \(entry.target.formatted())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            if entry.hasGoal {
                Gauge(
                    value: gaugeValue,
                    in: 0...Double(entry.target)
                ) {
                    EmptyView()
                }
                .gaugeStyle(.accessoryLinearCapacity)
                .tint(Color.accentColor)
            } else {
                Text("widget.steps.today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Corner

    @ViewBuilder
    private var corner: some View {
        let steps = Text(Self.compact(entry.steps))
            .fontDesign(.rounded)
            .fontWeight(.semibold)
            .minimumScaleFactor(0.6)
            .privacySensitive()
            .widgetCurvesContent()

        if entry.hasGoal {
            steps.widgetLabel {
                Gauge(
                    value: gaugeValue,
                    in: 0...Double(entry.target)
                ) {
                    Text("widget.steps.title")
                } currentValueLabel: {
                    Text(Self.compact(entry.steps))
                } minimumValueLabel: {
                    Text(verbatim: "0")
                } maximumValueLabel: {
                    Text(Self.compact(entry.target))
                }
                .tint(gaugeGradient)
            }
        } else {
            steps.widgetLabel {
                Text("widget.steps.today")
            }
        }
    }

    // MARK: - Inline

    private var inline: some View {
        Label {
            if entry.hasGoal {
                Text("widget.steps.progress \(entry.steps.formatted()) \(entry.target.formatted())")
            } else {
                Text("widget.steps.count \(entry.steps.formatted())")
            }
        } icon: {
            statusIcon
        }
        .privacySensitive()
    }

    // MARK: - Shared

    private var gaugeValue: Double {
        Double(min(entry.steps, entry.target))
    }

    /// Accent gradient with a goal, neutral when showing the reference goal.
    private var gaugeGradient: Gradient {
        guard entry.hasGoal else {
            return Gradient(colors: [.gray, .gray])
        }

        if entry.isGoalReached {
            return Gradient(colors: [.accentColor, .accentColor])
        }

        return Gradient(colors: [.accentColor.opacity(0.6), .accentColor])
    }

    private var statusIcon: some View {
        Image(systemName: entry.isGoalReached ? "checkmark" : "shoeprints.fill")
            .widgetAccentable()
    }

    private var accessibilityLabel: Text {
        if entry.hasGoal {
            return Text("widget.steps.accessibilityGoal \(entry.steps) \(entry.target)")
        }

        return Text("widget.steps.accessibility \(entry.steps)")
    }

    /// 950 → "950", 1.523 → "1,5k", 12.700 → "12k". Always rounds down so
    /// the complication never shows more steps than were actually walked.
    static func compact(_ value: Int) -> String {
        switch value {
        case ..<1_000:
            return value.formatted()
        case ..<10_000:
            let thousands = Double(value / 100) / 10
            return thousands.formatted(
                .number.precision(.fractionLength(1))
            ) + "k"
        default:
            return (value / 1_000).formatted() + "k"
        }
    }
}

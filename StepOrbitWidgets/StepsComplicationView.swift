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
    
    private let gap: CGFloat = 0.16

    var body: some View {
        GeometryReader { geometry in
            let size = min(
                geometry.size.width,
                geometry.size.height
            )
            
            ZStack {
                if entry.hasGoal {
                    progressRing(size: size)
                }
                
                Text(compactSteps)
                    .font(.system(
                        size: size * 0.30,
                        weight: .bold,
                        design: .rounded
                    ))
                    .monospaced()
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .foregroundStyle(.white)
                
                Image(systemName: "shoeprints.fill")
                    .font(.system(
                        size: size * 0.16,
                        weight: .semibold
                    ))
                    .foregroundStyle(Color.accentColor)
                    .offset(
                        y: entry.hasGoal ? -size * 0.38 : -size * 0.24
                    )
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .containerBackground(.clear, for: .widget)
        .accessibilityLabel("\(entry.steps) steps")
    }
    
    private func progressRing(size: CGFloat) -> some View {
        let start = gap / 2
        let end = 1 - gap / 2
        let arcLength = end - start
        
        return ZStack {
            Circle()
                .trim(from: start, to: end)
                .stroke((
                    Color.accentColor.opacity(0.25)
                ), style: StrokeStyle(
                    lineWidth: size * 0.075,
                    lineCap: .round
                ))
            
            Circle()
                .trim(
                    from: start,
                    to: start + arcLength * entry.progress
                )
                .stroke((
                    Color.accentColor
                ), style: StrokeStyle(
                    lineWidth: size * 0.075,
                    lineCap: .round
                ))
        }
        .rotationEffect(.degrees(-90))
        .padding(size * 0.06)
    }
    
    private var compactSteps: String {
        if entry.steps >= 1000 {
            let value = Double(entry.steps) / 1000
            
            return value.formatted(
                .number.precision(.fractionLength(1))
            ) + "k"
        }
        
        return entry.steps.formatted()
    }
    
    
}

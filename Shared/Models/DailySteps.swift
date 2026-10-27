//
//  DailySteps.swift
//  StepOrbit
//
//  Created by Francisco Roldán on 26/10/2026.
//
import Foundation

struct DailySteps: Equatable, Sendable {
    let date: Date
    let count: Int
    
    init(date: Date, count: Int) {
        self.date = date
        self.count = max(0, count)
    }
}

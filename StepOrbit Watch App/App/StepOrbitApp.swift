//
//  StepOrbitApp.swift
//  StepOrbit Watch App
//
//  Created by Francisco Roldán on 26/10/2026.
//

import SwiftUI

@main
struct StepOrbit_Watch_AppApp: App {

    // Created once at launch (also on background launches triggered by
    // HealthKit background delivery) so the step observer is registered early.
    private let viewModel = StepsViewModel(
        repository: HealthKitStepsRepository()
    )

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}

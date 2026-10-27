//
//  StepsRepository.swift
//  StepOrbit
//
//  Created by Francisco Roldán on 26/10/2026.
//

protocol StepsRepository: Sendable {
    func requestAuthorization() async throws
    func fetchTodaySteps() async throws -> DailySteps

    /// Emits today's steps every time HealthKit receives new samples.
    func todayStepsUpdates() -> AsyncThrowingStream<DailySteps, any Error>

    /// Registers a background observer that calls `onChange` when new step
    /// samples arrive. Does nothing until authorization has been requested,
    /// and only registers once per process.
    func startObservingStepChanges(
        _ onChange: @escaping @Sendable () async -> Void
    ) async throws
}

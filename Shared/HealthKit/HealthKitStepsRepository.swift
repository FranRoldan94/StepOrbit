//
//  HealthKitStepsRepository.swift
//  StepOrbit
//
//  Created by Francisco Roldán on 26/10/2026.
//

import Foundation
import HealthKit
import Synchronization

enum StepsRepositoryError: LocalizedError {
    case healthDataUnavailable
    case queryFailed

    var errorDescription: String? {
        switch self {
        case .healthDataUnavailable:
            return "Health data is unavailable."
        case .queryFailed:
            return "Unable to retrieve step data."
        }
    }
}

final class HealthKitStepsRepository: StepsRepository {

    /// Apple recommends a single `HKHealthStore` per process.
    private static let sharedHealthStore = HKHealthStore()
    private static let isObservingStepChanges = Mutex(false)
    private static let stepType = HKQuantityType(.stepCount)

    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore = HealthKitStepsRepository.sharedHealthStore) {
        self.healthStore = healthStore
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw StepsRepositoryError.healthDataUnavailable
        }

        try await healthStore.requestAuthorization(
            toShare: [],
            read: [Self.stepType]
        )
    }

    func fetchTodaySteps() async throws -> DailySteps {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw StepsRepositoryError.healthDataUnavailable
        }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)

        let descriptor = HKStatisticsQueryDescriptor(
            predicate: Self.stepsPredicate(
                start: startOfDay,
                end: now
            ),
            options: .cumulativeSum
        )

        let statistics = try await descriptor.result(for: healthStore)

        let count = statistics?
            .sumQuantity()?
            .doubleValue(for: .count()) ?? 0

        return DailySteps(date: now, count: Int(count))
    }

    func todayStepsUpdates() -> AsyncThrowingStream<DailySteps, any Error> {
        let healthStore = healthStore

        return AsyncThrowingStream { continuation in
            let task = Task {
                guard HKHealthStore.isHealthDataAvailable() else {
                    continuation.finish(
                        throwing: StepsRepositoryError.healthDataUnavailable
                    )
                    return
                }

                let startOfDay = Calendar.current.startOfDay(for: .now)

                // Daily buckets with no end date: `statistics(for: .now)`
                // keeps returning the current day after midnight.
                let descriptor = HKStatisticsCollectionQueryDescriptor(
                    predicate: Self.stepsPredicate(
                        start: startOfDay,
                        end: nil
                    ),
                    options: .cumulativeSum,
                    anchorDate: startOfDay,
                    intervalComponents: DateComponents(day: 1)
                )

                do {
                    for try await result in descriptor.results(for: healthStore) {
                        let now = Date()
                        let count = result.statisticsCollection
                            .statistics(for: now)?
                            .sumQuantity()?
                            .doubleValue(for: .count()) ?? 0

                        continuation.yield(
                            DailySteps(date: now, count: Int(count))
                        )
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func startObservingStepChanges(
        _ onChange: @escaping @Sendable () async -> Void
    ) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw StepsRepositoryError.healthDataUnavailable
        }

        let status = try await healthStore.statusForAuthorizationRequest(
            toShare: [],
            read: [Self.stepType]
        )

        guard status == .unnecessary else {
            return
        }

        let alreadyObserving = Self.isObservingStepChanges.withLock { isObserving in
            defer { isObserving = true }
            return isObserving
        }

        guard !alreadyObserving else {
            return
        }

        let query = HKObserverQuery(
            sampleType: Self.stepType,
            predicate: nil
        ) { _, completionHandler, error in
            guard error == nil else {
                completionHandler()
                return
            }

            // The completion handler is safe to call from any thread
            // but is not marked as Sendable.
            nonisolated(unsafe) let completionHandler = completionHandler
            
            Task {
                await onChange()
                completionHandler()
            }
        }

        healthStore.execute(query)

        try await healthStore.enableBackgroundDelivery(
            for: Self.stepType,
            frequency: .hourly
        )
    }

    private static func stepsPredicate(
        start: Date,
        end: Date?
    ) -> HKSamplePredicate<HKQuantitySample> {
        .quantitySample(
            type: stepType,
            predicate: HKQuery.predicateForSamples(
                withStart: start,
                end: end,
                options: .strictStartDate
            )
        )
    }
}

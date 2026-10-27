//
//  StepsProvider.swift
//  StepOrbit
//
//  Created by Francisco Roldán on 26/10/2026.
//

import Foundation
import OSLog
import WidgetKit

struct StepsEntry: TimelineEntry {
    /// Used to draw the ring when the user has not set a goal.
    static let referenceGoal = 10_000

    let date: Date
    let steps: Int
    let goal: Int?

    var hasGoal: Bool {
        guard let goal else { return false }
        return goal > 0
    }

    var target: Int {
        guard let goal, goal > 0 else {
            return Self.referenceGoal
        }

        return goal
    }

    var isGoalReached: Bool {
        hasGoal && steps >= target
    }

    var progress: Double {
        guard let goal, goal > 0 else {
            return 0
        }

        return min(
            Double(steps) / Double(goal),
            1.0
        )
    }
}

struct StepsProvider: TimelineProvider {

    private static let refreshInterval: TimeInterval = 15 * 60
    private static let logger = Logger(
        subsystem: "es.roltek.StepOrbit",
        category: "StepsProvider"
    )

    private let repository = HealthKitStepsRepository()
    private let goalStore = StepGoalStore()
    private let cache = StepsCache()

    func placeholder(in context: Context) -> StepsEntry {
        StepsEntry(
            date: .now,
            steps: 8542,
            goal: nil
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (StepsEntry) -> Void
    ) {
        guard !context.isPreview else {
            completion(placeholder(in: context))
            return
        }

        completion(
            StepsEntry(
                date: .now,
                steps: cache.load()?.count ?? 0,
                goal: goalStore.getGoal()
            )
        )
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<StepsEntry>) -> Void
    ) {
        // WidgetKit accepts the completion from any thread,
        // but it is not marked as Sendable.
        nonisolated(unsafe) let completion = completion

        Task {
            let now = Date()
            let steps: Int

            do {
                let dailySteps = cache.merge(
                    try await repository.fetchTodaySteps()
                )
                steps = dailySteps.count
            } catch {
                // HealthKit is inaccessible while the watch is locked:
                // keep showing the last known value instead of 0.
                Self.logger.error("HealthKit error: \(error.localizedDescription)")
                steps = cache.load()?.count ?? 0
            }

            let goal = goalStore.getGoal()
            let calendar = Calendar.current
            let startOfTomorrow = calendar.date(
                byAdding: .day,
                value: 1,
                to: calendar.startOfDay(for: now)
            ) ?? now.addingTimeInterval(Self.refreshInterval)
            let nextRefresh = min(
                now.addingTimeInterval(Self.refreshInterval),
                startOfTomorrow
            )

            // The midnight entry resets the count even if the next
            // reload is delayed by the system.
            let entries = [
                StepsEntry(date: now, steps: steps, goal: goal),
                StepsEntry(date: startOfTomorrow, steps: 0, goal: goal)
            ]

            completion(
                Timeline(
                    entries: entries,
                    policy: .after(nextRefresh)
                )
            )
        }
    }
}

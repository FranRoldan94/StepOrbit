//
//  StepGoalStore.swift
//  StepOrbit
//
//  Created by Francisco Roldán on 26/10/2026.
//


import Foundation

enum AppGroup {
    nonisolated static let id = "group.es.roltek.StepOrbit"
    // UserDefaults is thread-safe but not marked as Sendable.
    nonisolated(unsafe) static let defaults = UserDefaults(suiteName: id)
}

enum WidgetKind {
    static let steps = "StepOrbitSteps"
}

struct StepGoalStore: Sendable {

    private static let goalKey = "dailyStepGoal"

    private var defaults: UserDefaults? {
        AppGroup.defaults
    }

    func getGoal() -> Int? {
        guard let defaults,
              let goal = defaults.object(
                forKey: Self.goalKey
              ) as? Int,
              goal > 0 else {
            return nil
        }

        return goal
    }

    func setGoal(_ goal: Int?) {
        guard let defaults else {
            return
        }

        if let goal, goal > 0 {
            defaults.set(goal, forKey: Self.goalKey)
        } else {
            defaults.removeObject(forKey: Self.goalKey)
        }
    }
}

/// Last known step count, shared between the app and the widget so the
/// complication can fall back to it when HealthKit is unavailable
/// (for example, while the watch is locked).
struct StepsCache: Sendable {

    private static let countKey = "lastStepCount"
    private static let dateKey = "lastStepDate"

    private var defaults: UserDefaults? {
        AppGroup.defaults
    }

    /// Returns the cached steps only if they belong to today.
    func load() -> DailySteps? {
        guard let defaults,
              let date = defaults.object(
                forKey: Self.dateKey
              ) as? Date,
              Calendar.current.isDateInToday(date) else {
            return nil
        }

        return DailySteps(
            date: date,
            count: defaults.integer(forKey: Self.countKey)
        )
    }

    /// Steps only grow during a day, so keep the highest count seen today.
    /// The app and the complication both go through here, so neither can
    /// show fewer steps than the other already displayed.
    func merge(_ steps: DailySteps) -> DailySteps {
        var merged = steps

        if let cached = load(),
           Calendar.current.isDate(cached.date, inSameDayAs: steps.date),
           cached.count > steps.count {
            merged = DailySteps(date: steps.date, count: cached.count)
        }

        save(merged)
        return merged
    }

    func save(_ steps: DailySteps) {
        guard let defaults else {
            return
        }

        defaults.set(steps.count, forKey: Self.countKey)
        defaults.set(steps.date, forKey: Self.dateKey)
    }
}

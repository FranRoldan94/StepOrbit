//
//  StepsViewModel.swift
//  StepOrbit
//
//  Created by Francisco Roldán on 26/10/2026.
//

import Foundation
import Observation
import WidgetKit

@MainActor
@Observable
final class StepsViewModel {

    enum State: Equatable {
        case idle
        case loading
        case loaded(DailySteps)
        case failed
    }

    /// Minimum time between complication reloads triggered by live updates.
    private static let liveWidgetReloadInterval: TimeInterval = 60

    private let repository: any StepsRepository
    private let cache = StepsCache()
    private let goalStore = StepGoalStore()

    private(set) var state: State = .idle
    private(set) var goal: Int?

    @ObservationIgnored private var isAuthorized = false
    @ObservationIgnored private var liveUpdatesTask: Task<Void, Never>?
    @ObservationIgnored private var widgetStepCount: Int?
    @ObservationIgnored private var lastWidgetReload: Date?

    init(repository: any StepsRepository) {
        self.repository = repository
        self.goal = goalStore.getGoal()

        if let cachedSteps = cache.load() {
            state = .loaded(cachedSteps)
        }

        // Registers the background observer right away when authorization
        // was already granted in a previous launch.
        startBackgroundSync()
    }

    func load() async {
        if case .loaded = state {} else {
            state = .loading
        }

        do {
            if !isAuthorized {
                try await repository.requestAuthorization()
                isAuthorized = true
                startBackgroundSync()
            }

            publish(try await repository.fetchTodaySteps())
            reloadWidgetIfNeeded()
            startLiveUpdates()
        } catch {
            state = .failed
        }
    }

    /// Called when the app returns to the foreground or the user asks for it.
    func refresh() async {
        guard isAuthorized else {
            await load()
            return
        }

        do {
            publish(try await repository.fetchTodaySteps())
            reloadWidgetIfNeeded()
            startLiveUpdates()
        } catch {
            if case .loaded = state {} else {
                state = .failed
            }
        }
    }

    /// Called when the app leaves the foreground.
    func pause() {
        liveUpdatesTask?.cancel()
        liveUpdatesTask = nil
        reloadWidgetIfNeeded()
    }

    func updateGoal(_ newGoal: Int?) {
        guard newGoal != goal else {
            return
        }

        goal = newGoal
        goalStore.setGoal(newGoal)
        reloadWidget()
    }

    // MARK: - Private

    private func startLiveUpdates() {
        guard liveUpdatesTask == nil else {
            return
        }

        liveUpdatesTask = Task { [repository] in
            do {
                for try await steps in repository.todayStepsUpdates() {
                    publish(steps)
                    reloadWidgetIfNeeded(throttled: true)
                }
            } catch {
                // Keep showing the last known value.
            }

            if !Task.isCancelled {
                liveUpdatesTask = nil
            }
        }
    }

    private func startBackgroundSync() {
        Task { [weak self, repository] in
            try? await repository.startObservingStepChanges { [weak self] in
                await self?.syncFromBackground()
            }
        }
    }

    private func syncFromBackground() async {
        // While in the foreground the live query already keeps us updated.
        guard liveUpdatesTask == nil else {
            return
        }

        guard let steps = try? await repository.fetchTodaySteps() else {
            return
        }

        publish(steps)
        reloadWidgetIfNeeded()
    }

    private func publish(_ steps: DailySteps) {
        state = .loaded(cache.merge(steps))
    }

    /// Reloads the complication only when it is showing a different value.
    private func reloadWidgetIfNeeded(throttled: Bool = false) {
        guard case .loaded(let steps) = state,
              steps.count != widgetStepCount else {
            return
        }

        if throttled,
           let lastWidgetReload,
           Date().timeIntervalSince(lastWidgetReload) < Self.liveWidgetReloadInterval {
            return
        }

        widgetStepCount = steps.count
        reloadWidget()
    }

    private func reloadWidget() {
        lastWidgetReload = .now
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.steps)
    }
}

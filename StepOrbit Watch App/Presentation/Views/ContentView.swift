

import SwiftUI

struct ContentView: View {

    let viewModel: StepsViewModel

    @State private var isEditingGoal = false

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            StepsSection(viewModel: viewModel) {
                isEditingGoal = true
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isEditingGoal = true
                    } label: {
                        Label("goal.title", systemImage: "target")
                    }
                }
            }
            .sheet(isPresented: $isEditingGoal) {
                StepGoalSettingsView(goal: viewModel.goal) { newGoal in
                    viewModel.updateGoal(newGoal)
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task {
                    await viewModel.refresh()
                }
            } else {
                viewModel.pause()
            }
        }
    }
}

// MARK: - Steps

/// Separate view so that step updates only re-render this section.
private struct StepsSection: View {

    let viewModel: StepsViewModel
    let onEditGoal: () -> Void

    var body: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()

        case .loaded(let dailySteps):
            VStack(spacing: 6) {
                if let goal = viewModel.goal {
                    goalProgress(steps: dailySteps.count, goal: goal)
                } else {
                    stepsOnly(steps: dailySteps.count)
                }

                UpdatedLabel(date: dailySteps.date) {
                    Task {
                        await viewModel.refresh()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .failed:
            VStack(spacing: 8) {
                Text("steps.error")
                    .font(.caption2)
                    .multilineTextAlignment(.center)

                Button("common.retry") {
                    Task {
                        await viewModel.load()
                    }
                }
            }
        }
    }

    private func goalProgress(steps: Int, goal: Int) -> some View {
        let progress = min(Double(steps) / Double(goal), 1)
        let isGoalReached = steps >= goal

        return ZStack {
            ProgressRing(progress: progress)

            VStack(spacing: 2) {
                stepsValue(steps)

                Text(isGoalReached ? "goal.reached" : "steps.goalProgress \(goal.formatted())")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 12)

            Image(systemName: isGoalReached ? "checkmark" : "shoeprints.fill")
                .font(.caption)
                .foregroundStyle(Color.accentColor)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .combine)
    }

    private func stepsOnly(steps: Int) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "shoeprints.fill")
                .font(.title3)
                .foregroundStyle(Color.accentColor)

            Text("steps.today")
                .font(.caption)
                .foregroundStyle(.secondary)

            stepsValue(steps)

            Button("goal.set", action: onEditGoal)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .buttonStyle(.plain)
        }
    }

    private func stepsValue(_ steps: Int) -> some View {
        Text(steps, format: .number)
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .contentTransition(.numericText(value: Double(steps)))
            .animation(.snappy, value: steps)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
    }
}

// MARK: - Progress ring

/// Same open ring as the complication gauge: gap at the bottom, clockwise.
private struct ProgressRing: View {

    let progress: Double

    private let gap = 0.16
    private let lineWidth: CGFloat = 8

    var body: some View {
        let start = gap / 2
        let end = 1 - gap / 2

        ZStack {
            Circle()
                .trim(from: start, to: end)
                .stroke(
                    Color.accentColor.opacity(0.25),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            Circle()
                .trim(from: start, to: start + (end - start) * progress)
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .animation(.easeOut, value: progress)
        }
        .rotationEffect(.degrees(90))
        .padding(lineWidth / 2)
    }
}

// MARK: - Last update

/// "Updated just now" / "Updated 5 min ago". Tapping it refreshes.
private struct UpdatedLabel: View {

    let date: Date
    let onRefresh: () -> Void

    var body: some View {
        Button(action: onRefresh) {
            TimelineView(.everyMinute) { context in
                Group {
                    if context.date.timeIntervalSince(date) < 60 {
                        Text("steps.updated.now")
                    } else {
                        Text("steps.updated \(relativeDate)")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var relativeDate: String {
        date.formatted(
            .relative(presentation: .named, unitsStyle: .abbreviated)
        )
    }
}

// MARK: - Preview

#Preview("With goal") {
    ContentView(
        viewModel: StepsViewModel(
            repository: PreviewStepsRepository()
        )
    )
}

private struct PreviewStepsRepository: StepsRepository {

    func requestAuthorization() async throws {}

    func fetchTodaySteps() async throws -> DailySteps {
        DailySteps(
            date: Date().addingTimeInterval(-5 * 60),
            count: 8542
        )
    }

    func todayStepsUpdates() -> AsyncThrowingStream<DailySteps, any Error> {
        AsyncThrowingStream { $0.finish() }
    }

    func startObservingStepChanges(
        _ onChange: @escaping @Sendable () async -> Void
    ) async throws {}
}

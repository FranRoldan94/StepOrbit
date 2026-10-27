

import SwiftUI

struct ContentView: View {

    let viewModel: StepsViewModel

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                StepsSection(viewModel: viewModel)

                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                StepGoalSettingsView()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
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

/// Separate view so that step updates only re-render this section,
/// not the goal controls.
private struct StepsSection: View {

    let viewModel: StepsViewModel

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "shoeprints.fill")
                .font(.system(size: 28))
                .foregroundStyle(.green)

            Text("steps.today")
                .font(.caption)
                .foregroundStyle(.secondary)

            stepsContent
        }
        .frame(maxWidth: .infinity)
        .containerRelativeFrame(.vertical)
    }

    @ViewBuilder
    private var stepsContent: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()

        case .loaded(let dailySteps):
            Text(
                dailySteps.count,
                format: .number
            )
            .font(
                .system(
                    size: 42,
                    weight: .bold,
                    design: .rounded
                )
            )
            .minimumScaleFactor(0.5)
            .lineLimit(1)

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
}

// MARK: - Preview

#Preview {
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
            date: Date(),
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

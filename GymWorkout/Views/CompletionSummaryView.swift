import SwiftUI

struct CompletionSummaryView: View {
    let completedCount: Int
    let totalCount: Int
    let onDone: () -> Void
    let onStartNewWorkout: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 32)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 76))
                    .foregroundStyle(WorkoutTheme.green)
                    .accessibilityHidden(true)

                VStack(spacing: 10) {
                    Text("Workout complete")
                        .font(.largeTitle.bold())
                        .foregroundStyle(WorkoutTheme.forest)
                        .multilineTextAlignment(.center)

                    Text("\(completedCount) of \(totalCount) exercises completed")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(WorkoutTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }

                Text("Strong work. Your completed workout stays saved until you start a new one.")
                    .font(.body)
                    .foregroundStyle(WorkoutTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 12) {
                    Button(action: onDone) {
                        Text("Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 54)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(WorkoutTheme.green)
                    .accessibilityHint("Returns home and keeps this completed workout saved.")

                    Button(action: onStartNewWorkout) {
                        Text("Start New Workout")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 54)
                    }
                    .buttonStyle(.bordered)
                    .tint(WorkoutTheme.green)
                    .accessibilityHint("Clears completion and returns to the first exercise.")
                }
                .padding(.top, 8)
            }
            .padding(24)
        }
        .background(WorkoutTheme.canvas.ignoresSafeArea())
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .accessibilityElement(children: .contain)
    }
}

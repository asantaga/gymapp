import SwiftUI

enum WorkoutPlayerLayout {
    static let exercisePhotoHeight: CGFloat = 180
}

struct WorkoutPlayerView: View {
    let store: WorkoutSessionStore
    let onReturnHome: () -> Void

    @State private var isShowingSummary = false

    var body: some View {
        ZStack {
            WorkoutTheme.canvas.ignoresSafeArea()

            if let exercise = store.currentExercise {
                ScrollView {
                    VStack(spacing: 0) {
                        playerHeader

                        VStack(spacing: 18) {
                            ExerciseDetailCard(exercise: exercise)
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 18)
                        .padding(.bottom, 150)
                    }
                }
                .scrollIndicators(.hidden)
                .ignoresSafeArea(edges: .top)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    VStack(spacing: 10) {
                        completionButton(for: exercise)
                        navigationButtons
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 10)
                    .background(.ultraThinMaterial)
                }
            } else {
                ContentUnavailableView(
                    "No exercises",
                    systemImage: "dumbbell",
                    description: Text("Return home and start a workout after adding an exercise.")
                )
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .onChange(of: store.isFinished, initial: true) { _, isFinished in
            isShowingSummary = isFinished
        }
        .sheet(isPresented: $isShowingSummary) {
            CompletionSummaryView(
                completedCount: store.completedCount,
                totalCount: store.exercises.count,
                onDone: {
                    isShowingSummary = false
                    onReturnHome()
                },
                onStartNewWorkout: {
                    store.startNewWorkout()
                    isShowingSummary = false
                }
            )
            .interactiveDismissDisabled()
            .presentationDetents([.large])
        }
    }

    private var playerHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                Button(action: onReturnHome) {
                    Image(systemName: "chevron.left")
                        .font(.headline.bold())
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.14), in: Circle())
                }
                .foregroundStyle(.white)
                .accessibilityLabel("Return to home")
                .accessibilityHint("Saves your progress and closes the workout player.")

                VStack(alignment: .leading, spacing: 3) {
                    Text("Workout A")
                        .font(.title2.bold())
                    Text(WorkoutPlayerCopy.progress(
                        position: store.currentPosition + 1,
                        total: store.exercises.count
                    ))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.78))
                }
                .foregroundStyle(.white)

                Spacer(minLength: 8)

                Text("\(store.completedCount)/\(store.exercises.count)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.14), in: Capsule())
                    .accessibilityLabel("\(store.completedCount) exercises completed")
            }

            ProgressView(
                value: Double(store.completedCount),
                total: Double(store.exercises.count)
            )
            .progressViewStyle(.linear)
            .tint(.white)
            .scaleEffect(x: 1, y: 1.4, anchor: .center)
            .accessibilityLabel("Workout progress")
            .accessibilityValue(
                "\(store.completedCount) of \(store.exercises.count) completed, exercise \(store.currentPosition + 1) of \(store.exercises.count)"
            )
            .accessibilityHint("Updates when an exercise is marked complete.")
        }
        .padding(.horizontal, 18)
        .padding(.top, 54)
        .padding(.bottom, 18)
        .background(WorkoutTheme.forest)
    }

    private func completionButton(for exercise: Exercise) -> some View {
        let isComplete = store.isCompleted(exercise)

        return Button {
            store.toggleCompletion(for: exercise)
        } label: {
            Label(
                WorkoutPlayerCopy.completeButton(isComplete: isComplete),
                systemImage: isComplete ? "checkmark.circle.fill" : "circle"
            )
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 54)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isComplete ? WorkoutTheme.forest : .white)
        .padding(.horizontal, 16)
        .background(
            isComplete ? WorkoutTheme.mint : WorkoutTheme.green,
            in: RoundedRectangle(cornerRadius: 15, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(isComplete ? WorkoutTheme.green : .clear, lineWidth: 2)
        }
        .accessibilityLabel(WorkoutPlayerCopy.completeButton(isComplete: isComplete))
        .accessibilityHint(
            isComplete
                ? "Marks \(exercise.name) as not complete."
                : "Marks \(exercise.name) as complete."
        )
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            navigationButton(
                title: "Previous",
                systemImage: "chevron.left",
                isDisabled: store.currentPosition == 0,
                hint: store.currentPosition == 0
                    ? "This is the first exercise."
                    : "Shows exercise \(store.currentPosition).",
                action: store.goPrevious
            )

            navigationButton(
                title: "Next",
                systemImage: "chevron.right",
                isDisabled: store.currentPosition == store.exercises.count - 1,
                hint: store.currentPosition == store.exercises.count - 1
                    ? "This is the last exercise."
                    : "Shows exercise \(store.currentPosition + 2).",
                action: store.goNext
            )
        }
    }

    private func navigationButton(
        title: String,
        systemImage: String,
        isDisabled: Bool,
        hint: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.bordered)
        .tint(WorkoutTheme.green)
        .disabled(isDisabled)
        .accessibilityLabel("\(title) exercise")
        .accessibilityHint(hint)
    }
}

import SwiftUI

enum WorkoutPlayerLayout {
    static let minimumExercisePhotoHeight: CGFloat = 300
    static let maximumExercisePhotoHeight: CGFloat = 420
    static var contentBottomPadding: CGFloat { 24 }
    static let controlsFollowExerciseDetails = true
    static let controlsAnchorToBottom = true
    static let supportsSwipeNavigation = true

    static func exercisePhotoHeight(forCardHeight height: CGFloat) -> CGFloat {
        min(maximumExercisePhotoHeight, max(minimumExercisePhotoHeight, height - 220))
    }
}

struct WorkoutPlayerView: View {
    let store: WorkoutSessionStore
    let onReturnHome: () -> Void

    var body: some View {
        ZStack {
            WorkoutTheme.canvas.ignoresSafeArea()

            if let exercise = store.currentExercise {
                VStack(spacing: 0) {
                    playerHeader

                    ExerciseDetailCard(exercise: exercise)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, 18)
                        .padding(.top, 6)

                }
                .ignoresSafeArea(edges: .top)
                .contentShape(Rectangle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 30)
                        .onEnded { value in
                            handleSwipe(value.translation)
                        }
                )
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

                Text("\(store.currentPosition + 1)/\(store.exercises.count)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.14), in: Capsule())
                    .accessibilityLabel("Exercise \(store.currentPosition + 1) of \(store.exercises.count)")
            }

            ProgressView(
                value: Double(store.currentPosition + 1),
                total: Double(store.exercises.count)
            )
            .progressViewStyle(.linear)
            .tint(.white)
            .scaleEffect(x: 1, y: 1.4, anchor: .center)
            .accessibilityLabel("Workout progress")
            .accessibilityValue(
                "Exercise \(store.currentPosition + 1) of \(store.exercises.count)"
            )
            .accessibilityHint("Updates as you move through the workout.")
        }
        .padding(.horizontal, 18)
        .padding(.top, 54)
        .padding(.bottom, 18)
        .background(WorkoutTheme.forest)
    }

    private func handleSwipe(_ translation: CGSize) {
        guard abs(translation.width) > abs(translation.height) else { return }

        if translation.width < 0 {
            store.goNext()
        } else {
            store.goPrevious()
        }
    }
}

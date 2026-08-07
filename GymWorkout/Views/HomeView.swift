import SwiftData
import SwiftUI

enum WorkoutTheme {
    static let forest = Color(red: 0.06, green: 0.24, blue: 0.16)
    static let green = Color(red: 0.10, green: 0.39, blue: 0.27)
    static let mint = Color(red: 0.90, green: 0.95, blue: 0.92)
    static let canvas = Color(red: 0.97, green: 0.96, blue: 0.92)
    static let secondaryText = Color(red: 0.28, green: 0.34, blue: 0.30)
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.position) private var workouts: [Workout]

    @State private var activeStore: WorkoutSessionStore?
    @State private var isShowingPlayer = false
    @State private var isShowingAddWorkout = false
    @State private var newlyCreatedWorkout: Workout?

    var body: some View {
        NavigationStack {
            ZStack {
                WorkoutTheme.canvas.ignoresSafeArea()

                if workouts.isEmpty {
                    ProgressView("Preparing your workouts…")
                        .tint(WorkoutTheme.green)
                } else {
                    homeContent
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $isShowingPlayer) {
                if let activeStore {
                    WorkoutPlayerView(store: activeStore) {
                        isShowingPlayer = false
                    }
                }
            }
            .navigationDestination(item: $newlyCreatedWorkout) { workout in
                ManageExercisesView(workout: workout)
            }
            .sheet(isPresented: $isShowingAddWorkout) {
                WorkoutEditView(workout: nil) { created in
                    newlyCreatedWorkout = created
                }
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }

    private var homeContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                header

                VStack(spacing: 16) {
                    ForEach(workouts) { workout in
                        workoutCard(workout: workout)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 32)
        }
        .ignoresSafeArea(edges: .top)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("GYM WORKOUT")
                    .font(.caption.weight(.bold))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.78))

                Text("Your Workouts")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("\(workouts.count) workout\(workouts.count == 1 ? "" : "s")")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.82))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                isShowingAddWorkout = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(WorkoutTheme.forest)
                    .frame(width: 44, height: 44)
                    .background(WorkoutTheme.mint, in: Circle())
            }
            .accessibilityLabel("Add workout")
        }
        .padding(.horizontal, 24)
        .padding(.top, 42)
        .padding(.bottom, 28)
        .background(WorkoutTheme.forest)
    }

    private func workoutCard(workout: Workout) -> some View {
        let session = workout.sessions.first
        let exerciseCount = workout.exercises.count
        let completedCount = session?.completedExerciseIDs.count ?? 0
        let isFinished = session?.isFinished ?? false
        let hasActiveWorkout = !isFinished && completedCount > 0

        return VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: isFinished ? "checkmark.seal.fill" : "figure.strengthtraining.traditional")
                    .font(.title)
                    .foregroundStyle(WorkoutTheme.green)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text(workout.name)
                        .font(.title2.bold())
                        .foregroundStyle(WorkoutTheme.forest)

                    Text("\(completedCount) of \(exerciseCount) exercises completed")
                        .font(.body)
                        .foregroundStyle(WorkoutTheme.secondaryText)
                }

                Spacer()

                NavigationLink {
                    ManageExercisesView(workout: workout)
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(WorkoutTheme.green)
                }
                .accessibilityLabel("Manage exercises for \(workout.name)")
            }

            ProgressView(value: Double(completedCount), total: Double(max(exerciseCount, 1)))
                .tint(WorkoutTheme.green)
                .accessibilityLabel("Workout completion")
                .accessibilityValue("\(completedCount) of \(exerciseCount) exercises completed")

            if exerciseCount == 0 {
                Text("No exercises yet. Tap the pencil to add some.")
                    .font(.subheadline)
                    .foregroundStyle(WorkoutTheme.secondaryText)
            } else {
                if hasActiveWorkout {
                    Button {
                        play(workout: workout)
                    } label: {
                        Label("Resume workout", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(WorkoutTheme.green)
                }

                Button {
                    startNew(workout: workout)
                } label: {
                    Label("Start New Workout", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.plain)
                .foregroundStyle(hasActiveWorkout ? WorkoutTheme.green : .white)
                .padding(.horizontal, 16)
                .background(
                    hasActiveWorkout ? .clear : WorkoutTheme.green,
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(WorkoutTheme.green, lineWidth: 1.5)
                }
            }
        }
        .padding(22)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
    }

    @MainActor
    private func play(workout: Workout) {
        activeStore = WorkoutSessionStore(workout: workout, modelContext: modelContext)
        isShowingPlayer = true
    }

    @MainActor
    private func startNew(workout: Workout) {
        let store = WorkoutSessionStore(workout: workout, modelContext: modelContext)
        store.startNewWorkout()
        activeStore = store
        isShowingPlayer = true
    }
}

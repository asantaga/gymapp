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
    @Query(sort: \Exercise.position) private var exercises: [Exercise]
    @Query private var sessions: [WorkoutSession]

    @State private var store: WorkoutSessionStore?
    @State private var isShowingPlayer = false

    var body: some View {
        NavigationStack {
            ZStack {
                WorkoutTheme.canvas.ignoresSafeArea()

                if exercises.isEmpty || store == nil {
                    ProgressView("Preparing Workout A…")
                        .tint(WorkoutTheme.green)
                        .accessibilityHint("The offline workout is being prepared.")
                } else if let store {
                    homeContent(store: store)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $isShowingPlayer) {
                if let store {
                    WorkoutPlayerView(store: store) {
                        isShowingPlayer = false
                    }
                }
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .task {
            prepareStoreIfNeeded()
        }
        .onChange(of: exercises.map(\.id)) {
            prepareStoreIfNeeded()
        }
    }

    private func homeContent(store: WorkoutSessionStore) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("GYM WORKOUT")
                        .font(.caption.weight(.bold))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.78))

                    Text("Workout A")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text("Strength • \(exercises.count) exercises")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.82))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 42)
                .padding(.bottom, 28)
                .background(WorkoutTheme.forest)

                workoutCard(store: store)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 32)
        }
        .ignoresSafeArea(edges: .top)
    }

    private func workoutCard(store: WorkoutSessionStore) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: store.isFinished ? "checkmark.seal.fill" : "figure.strengthtraining.traditional")
                    .font(.title)
                    .foregroundStyle(WorkoutTheme.green)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text(store.isFinished ? "Workout complete" : "Ready when you are")
                        .font(.title2.bold())
                        .foregroundStyle(WorkoutTheme.forest)

                    Text("\(store.completedCount) of \(exercises.count) exercises completed")
                        .font(.body)
                        .foregroundStyle(WorkoutTheme.secondaryText)
                }
            }

            ProgressView(value: Double(store.completedCount), total: Double(exercises.count))
                .tint(WorkoutTheme.green)
                .accessibilityLabel("Workout completion")
                .accessibilityValue("\(store.completedCount) of \(exercises.count) exercises completed")
                .accessibilityHint("Shows your saved progress for Workout A.")

            if hasActiveWorkout(store) {
                Button {
                    isShowingPlayer = true
                } label: {
                    Label("Resume workout", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(WorkoutTheme.green)
                .accessibilityHint("Returns to exercise \(store.currentPosition + 1).")
            }

            Button {
                store.startNewWorkout()
                isShowingPlayer = true
            } label: {
                Label("Start New Workout", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.plain)
            .foregroundStyle(hasActiveWorkout(store) ? WorkoutTheme.green : .white)
            .padding(.horizontal, 16)
            .background(
                hasActiveWorkout(store) ? .clear : WorkoutTheme.green,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(WorkoutTheme.green, lineWidth: 1.5)
            }
            .accessibilityHint("Clears saved completion and opens the first exercise.")
        }
        .padding(22)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
    }

    private func hasActiveWorkout(_ store: WorkoutSessionStore) -> Bool {
        !store.isFinished && (store.completedCount > 0 || store.currentPosition > 0)
    }

    @MainActor
    private func prepareStoreIfNeeded() {
        guard store == nil, !exercises.isEmpty else {
            return
        }

        let session: WorkoutSession
        if let savedSession = sessions.first {
            session = savedSession
        } else {
            session = WorkoutSession()
            modelContext.insert(session)
            do {
                try modelContext.save()
            } catch {
                assertionFailure("Unable to create the workout session: \(error)")
            }
        }

        store = WorkoutSessionStore(
            exercises: exercises,
            session: session,
            modelContext: modelContext
        )
    }
}

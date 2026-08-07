import SwiftData
import SwiftUI

@main
struct GymWorkoutApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Workout.self, Exercise.self, WorkoutSession.self)
        } catch {
            fatalError("Unable to create the model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            SeededRootView()
        }
        .modelContainer(modelContainer)
    }
}

private struct SeededRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var workouts: [Workout]

    var body: some View {
        HomeView()
            .task {
                guard workouts.isEmpty else {
                    return
                }

                do {
                    try SeedWorkoutFactory.seedIfNeeded(in: modelContext)
                } catch {
                    assertionFailure("Unable to seed Workout A: \(error)")
                }
            }
    }
}

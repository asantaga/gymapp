import SwiftData
import SwiftUI

@main
struct GymWorkoutApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Exercise.self, WorkoutSession.self)
        } catch {
            fatalError("Unable to create the model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            Text("Gym Workout")
        }
        .modelContainer(modelContainer)
    }
}

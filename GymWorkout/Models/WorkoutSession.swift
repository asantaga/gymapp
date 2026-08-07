import Foundation
import SwiftData

@Model
final class WorkoutSession {
    @Attribute(.unique) var id: UUID
    var currentExerciseID: UUID?
    var completedExerciseIDs: [UUID]
    var isFinished: Bool
    var workout: Workout?

    init(
        currentExerciseID: UUID? = nil,
        completedExerciseIDs: [UUID] = [],
        isFinished: Bool = false,
        workout: Workout? = nil
    ) {
        self.id = UUID()
        self.currentExerciseID = currentExerciseID
        self.completedExerciseIDs = completedExerciseIDs
        self.isFinished = isFinished
        self.workout = workout
    }
}

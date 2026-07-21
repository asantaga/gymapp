import Foundation
import SwiftData

@Model
final class WorkoutSession {
    @Attribute(.unique) var id: UUID
    var currentExerciseID: UUID?
    var completedExerciseIDs: [UUID]
    var isFinished: Bool

    init(
        currentExerciseID: UUID? = nil,
        completedExerciseIDs: [UUID] = [],
        isFinished: Bool = false
    ) {
        self.id = UUID()
        self.currentExerciseID = currentExerciseID
        self.completedExerciseIDs = completedExerciseIDs
        self.isFinished = isFinished
    }
}

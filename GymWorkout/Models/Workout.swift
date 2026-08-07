import Foundation
import SwiftData

@Model
final class Workout {
    @Attribute(.unique) var id: UUID
    var name: String
    var position: Int
    @Relationship(deleteRule: .cascade, inverse: \Exercise.workout) var exercises: [Exercise] = []
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSession.workout) var sessions: [WorkoutSession] = []

    init(name: String, position: Int) {
        self.id = UUID()
        self.name = name
        self.position = position
    }
}

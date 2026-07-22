import Observation
import SwiftData

@MainActor
@Observable
final class WorkoutSessionStore {
    let exercises: [Exercise]
    private let session: WorkoutSession
    private let modelContext: ModelContext

    init(exercises: [Exercise], session: WorkoutSession, modelContext: ModelContext) {
        self.exercises = exercises
        self.session = session
        self.modelContext = modelContext
    }

    var currentExercise: Exercise? {
        exercises[safe: currentPosition]
    }

    var currentPosition: Int {
        guard
            let currentExerciseID = session.currentExerciseID,
            let position = exercises.firstIndex(where: { $0.id == currentExerciseID })
        else {
            return 0
        }

        return position
    }

    var completedCount: Int {
        exercises.count(where: isCompleted)
    }

    var isFinished: Bool {
        session.isFinished
    }

    func isCompleted(_ exercise: Exercise) -> Bool {
        session.completedExerciseIDs.contains(exercise.id)
    }

    func toggleCompletion(for exercise: Exercise) {
        if let index = session.completedExerciseIDs.firstIndex(of: exercise.id) {
            session.completedExerciseIDs.remove(at: index)
        } else {
            session.completedExerciseIDs.append(exercise.id)
        }
        session.isFinished = !exercises.isEmpty && completedCount == exercises.count
        save()
    }

    func goNext() {
        move(to: min(currentPosition + 1, exercises.count - 1))
    }

    func goPrevious() {
        move(to: max(currentPosition - 1, 0))
    }

    func startNewWorkout() {
        session.currentExerciseID = exercises.first?.id
        session.completedExerciseIDs = []
        session.isFinished = false
        save()
    }

    func finishIfComplete() {
        guard !exercises.isEmpty, completedCount == exercises.count else {
            return
        }

        session.isFinished = true
        save()
    }

    private func move(to position: Int) {
        guard let exercise = exercises[safe: position] else {
            return
        }

        session.currentExerciseID = exercise.id
        save()
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Unable to save workout session: \(error)")
        }
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

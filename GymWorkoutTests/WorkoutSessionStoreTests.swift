import SwiftData
import XCTest
@testable import GymWorkout

@MainActor
final class WorkoutSessionStoreTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var workout: Workout!
    private var exercises: [Exercise]!
    private var session: WorkoutSession!
    private var store: WorkoutSessionStore!

    override func setUpWithError() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Workout.self, Exercise.self, WorkoutSession.self, configurations: configuration)
        context = ModelContext(container)
        workout = Workout(name: "Workout A", position: 0)
        exercises = [
            Exercise(position: 1, name: "Warm-up", setsText: "1", repsText: "10", weightText: "", notes: ""),
            Exercise(position: 2, name: "Squat", setsText: "3", repsText: "8", weightText: "60", notes: ""),
            Exercise(position: 3, name: "Row", setsText: "3", repsText: "8", weightText: "50", notes: "")
        ]
        exercises.forEach { $0.workout = workout }

        context.insert(workout)
        exercises.forEach(context.insert)
        try context.save()

        store = WorkoutSessionStore(workout: workout, modelContext: context)
        session = workout.sessions.first
    }

    override func tearDownWithError() throws {
        store = nil
        session = nil
        exercises = nil
        workout = nil
        context = nil
        container = nil
    }

    func testSessionWithoutSavedPositionStartsAtFirstExercise() {
        XCTAssertEqual(store.currentPosition, 0)
        XCTAssertEqual(store.currentExercise?.id, exercises[0].id)
    }

    func testCompletingExerciseUpdatesProgress() {
        store.toggleCompletion(for: exercises[0])

        XCTAssertEqual(store.completedCount, 1)
        XCTAssertTrue(store.isCompleted(exercises[0]))
    }

    func testNextDoesNotMarkExerciseComplete() {
        store.goNext()

        XCTAssertEqual(store.currentExercise?.id, exercises[1].id)
        XCTAssertEqual(store.completedCount, 0)
    }

    func testNavigationClampsAtFirstAndLastExercises() {
        store.goPrevious()
        XCTAssertEqual(store.currentExercise?.id, exercises[0].id)

        store.goNext()
        store.goNext()
        store.goNext()
        XCTAssertEqual(store.currentExercise?.id, exercises[2].id)
    }

    func testStartNewWorkoutClearsCompletionAndReturnsToFirstExercise() {
        store.toggleCompletion(for: exercises[0])
        store.goNext()

        store.startNewWorkout()

        XCTAssertEqual(store.completedCount, 0)
        XCTAssertEqual(store.currentExercise?.id, exercises[0].id)
        XCTAssertFalse(session.isFinished)
    }

    func testFinishOnlyMarksSessionFinishedWhenEveryExerciseIsComplete() {
        store.goNext()
        store.goNext()
        store.finishIfComplete()
        XCTAssertFalse(session.isFinished)

        exercises.forEach(store.toggleCompletion)
        store.finishIfComplete()

        XCTAssertTrue(session.isFinished)
    }

    func testStoreReflectsFinishedSessionState() {
        XCTAssertFalse(store.isFinished)

        exercises.forEach(store.toggleCompletion)

        XCTAssertTrue(store.isFinished)
    }

    func testUncompletingAnExerciseClearsFinishedStateAndPersists() throws {
        exercises.forEach(store.toggleCompletion)
        store.finishIfComplete()
        XCTAssertTrue(session.isFinished)

        store.toggleCompletion(for: exercises[0])

        XCTAssertFalse(session.isFinished)

        let persistenceContext = ModelContext(container)
        let persistedSession = try XCTUnwrap(persistenceContext.fetch(FetchDescriptor<WorkoutSession>()).first)
        XCTAssertFalse(persistedSession.isFinished)
    }

    func testMutationsPersistToTheModelContainer() throws {
        store.toggleCompletion(for: exercises[0])
        store.goNext()

        let persistenceContext = ModelContext(container)
        let persistedSession = try XCTUnwrap(persistenceContext.fetch(FetchDescriptor<WorkoutSession>()).first)

        XCTAssertEqual(persistedSession.currentExerciseID, exercises[1].id)
        XCTAssertEqual(persistedSession.completedExerciseIDs, [exercises[0].id])
    }
}

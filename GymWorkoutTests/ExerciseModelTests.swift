import XCTest
@testable import GymWorkout

final class ExerciseModelTests: XCTestCase {
    func testExerciseStoresEditablePrescription() throws {
        let exercise = Exercise(
            position: 1, name: "Cable row", setsText: "3", repsText: "8",
            weightText: "52", notes: "Machine", bundledPhotoName: "cable-row"
        )

        XCTAssertEqual(exercise.name, "Cable row")
        XCTAssertEqual(exercise.weightText, "52")
        XCTAssertEqual(exercise.bundledPhotoName, "cable-row")
        XCTAssertNil(exercise.userPhotoFilename)
    }

    func testWorkoutSessionStoresProgress() throws {
        let currentExerciseID = UUID()
        let completedExerciseID = UUID()
        let session = WorkoutSession(
            currentExerciseID: currentExerciseID,
            completedExerciseIDs: [completedExerciseID],
            isFinished: false
        )

        XCTAssertEqual(session.currentExerciseID, currentExerciseID)
        XCTAssertEqual(session.completedExerciseIDs, [completedExerciseID])
        XCTAssertFalse(session.isFinished)
    }
}

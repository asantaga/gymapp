import XCTest
@testable import GymWorkout

final class WorkoutPlayerViewTests: XCTestCase {

    func testPhoneLayoutUsesACompactExercisePhoto() {
        XCTAssertLessThanOrEqual(WorkoutPlayerLayout.exercisePhotoHeight, 190)
    }
    func testCompleteButtonUsesNonColourCompletionCopy() {
        XCTAssertEqual(WorkoutPlayerCopy.completeButton(isComplete: false), "Mark complete")
        XCTAssertEqual(WorkoutPlayerCopy.completeButton(isComplete: true), "Completed")
    }

    func testProgressCopyIncludesCurrentPositionAndTotal() {
        XCTAssertEqual(WorkoutPlayerCopy.progress(position: 3, total: 14), "Exercise 3 of 14")
    }
}

import XCTest
@testable import GymWorkout

final class WorkoutPlayerViewTests: XCTestCase {

    func testPhoneLayoutPrioritizesTheExercisePhoto() {
        XCTAssertGreaterThanOrEqual(WorkoutPlayerLayout.exercisePhotoHeight, 220)
    }

    func testPhoneLayoutUsesTwentyPercentLargerPhotoFrame() {
        XCTAssertEqual(WorkoutPlayerLayout.exercisePhotoHeight, 288)
    }

    func testPhoneLayoutUsesNormalSpacingBelowExerciseDetails() {
        XCTAssertLessThanOrEqual(WorkoutPlayerLayout.contentBottomPadding, 32)
    }

    func testPhoneLayoutPlacesControlsDirectlyAfterExerciseDetails() {
        XCTAssertTrue(WorkoutPlayerLayout.controlsFollowExerciseDetails)
    }

    func testPhoneLayoutAnchorsControlsAtTheBottom() {
        XCTAssertTrue(WorkoutPlayerLayout.controlsAnchorToBottom)
    }
    func testCompleteButtonUsesNonColourCompletionCopy() {
        XCTAssertEqual(WorkoutPlayerCopy.completeButton(isComplete: false), "Mark complete")
        XCTAssertEqual(WorkoutPlayerCopy.completeButton(isComplete: true), "Completed")
    }

    func testProgressCopyIncludesCurrentPositionAndTotal() {
        XCTAssertEqual(WorkoutPlayerCopy.progress(position: 3, total: 14), "Exercise 3 of 14")
    }
}

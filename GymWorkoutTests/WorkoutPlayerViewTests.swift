import XCTest
@testable import GymWorkout

final class WorkoutPlayerViewTests: XCTestCase {

    func testPhoneLayoutPrioritizesTheExercisePhoto() {
        XCTAssertGreaterThanOrEqual(WorkoutPlayerLayout.minimumExercisePhotoHeight, 220)
    }

    func testPhoneLayoutExpandsPortraitPhotoWhenCardHasSpace() {
        XCTAssertEqual(WorkoutPlayerLayout.exercisePhotoHeight(forCardHeight: 640), 420)
        XCTAssertEqual(WorkoutPlayerLayout.exercisePhotoHeight(forCardHeight: 500), 300)
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
    func testPlayerSupportsSwipeNavigation() {
        XCTAssertTrue(WorkoutPlayerLayout.supportsSwipeNavigation)
    }

    func testProgressCopyIncludesCurrentPositionAndTotal() {
        XCTAssertEqual(WorkoutPlayerCopy.progress(position: 3, total: 14), "Exercise 3 of 14")
    }
}

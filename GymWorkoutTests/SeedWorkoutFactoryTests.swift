import SwiftData
import XCTest
@testable import GymWorkout

final class SeedWorkoutFactoryTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Exercise.self, configurations: configuration)
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
    }

    func testSeedCreatesFourteenOrderedExercises() throws {
        try SeedWorkoutFactory.seedIfNeeded(in: context)
        let exercises = try fetchExercises()

        XCTAssertEqual(exercises.count, 14)
        XCTAssertEqual(exercises.first?.name, "Cross trainer")
        XCTAssertEqual(exercises[4].name, "Leg Extension")
        XCTAssertEqual(exercises.last?.name, "Dumbbell curls")
    }

    func testSeedPreservesSpreadsheetPrescriptionsAndNotes() throws {
        try SeedWorkoutFactory.seedIfNeeded(in: context)

        XCTAssertEqual(
            try fetchExercises().map(SeededExercise.init),
            [
                SeededExercise(position: 1, name: "Cross trainer", setsText: "N/A", repsText: "N/A", weightText: "N/A", notes: "10 mins"),
                SeededExercise(position: 2, name: "Wall Agents", setsText: "2", repsText: "12", weightText: "", notes: ""),
                SeededExercise(position: 3, name: "Shoulder dislocates (with band or bar)", setsText: "2", repsText: "12", weightText: "", notes: ""),
                SeededExercise(position: 4, name: "Body weight squats", setsText: "2", repsText: "12", weightText: "", notes: ""),
                SeededExercise(position: 5, name: "Leg Extension", setsText: "4", repsText: "6", weightText: "66", notes: "Machine; backrest 3"),
                SeededExercise(position: 6, name: "Leg Press", setsText: "3", repsText: "10", weightText: "86", notes: "Machine; seat 3"),
                SeededExercise(position: 7, name: "Seated Leg Curl", setsText: "2", repsText: "10", weightText: "45", notes: "Machine; backrest 3, 1, 2"),
                SeededExercise(position: 8, name: "Calf press", setsText: "3", repsText: "6", weightText: "79", notes: "Either standing, seated, or machine"),
                SeededExercise(position: 9, name: "Assisted chin-up", setsText: "3", repsText: "8", weightText: "-23", notes: "Machine"),
                SeededExercise(position: 10, name: "Cable row", setsText: "3", repsText: "8", weightText: "52", notes: "Machine"),
                SeededExercise(position: 11, name: "Overhead Press", setsText: "2", repsText: "10", weightText: "25", notes: "Small barbells"),
                SeededExercise(position: 12, name: "Diverging lat pulldown", setsText: "2", repsText: "12", weightText: "45", notes: "Machine"),
                SeededExercise(position: 13, name: "Cable tricep pulldowns", setsText: "1", repsText: "12", weightText: "32", notes: "Machine"),
                SeededExercise(position: 14, name: "Dumbbell curls", setsText: "2", repsText: "6", weightText: "12", notes: "Free dumbbells")
            ]
        )
    }

    func testSeedDoesNotOverwriteEditedWorkout() throws {
        try SeedWorkoutFactory.seedIfNeeded(in: context)
        let exercise = try XCTUnwrap(context.fetch(FetchDescriptor<Exercise>()).first)
        exercise.name = "Custom warm-up"
        try context.save()

        try SeedWorkoutFactory.seedIfNeeded(in: context)

        XCTAssertEqual(try context.fetch(FetchDescriptor<Exercise>()).first?.name, "Custom warm-up")
    }

    private func fetchExercises() throws -> [Exercise] {
        try context.fetch(FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\Exercise.position)]))
    }
}

private struct SeededExercise: Equatable {
    let position: Int
    let name: String
    let setsText: String
    let repsText: String
    let weightText: String
    let notes: String

    init(_ exercise: Exercise) {
        position = exercise.position
        name = exercise.name
        setsText = exercise.setsText
        repsText = exercise.repsText
        weightText = exercise.weightText
        notes = exercise.notes
    }

    init(position: Int, name: String, setsText: String, repsText: String, weightText: String, notes: String) {
        self.position = position
        self.name = name
        self.setsText = setsText
        self.repsText = repsText
        self.weightText = weightText
        self.notes = notes
    }
}

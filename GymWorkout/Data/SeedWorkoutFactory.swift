import SwiftData

enum SeedWorkoutFactory {
    static func seedIfNeeded(in context: ModelContext) throws {
        guard try context.fetchCount(FetchDescriptor<Workout>()) == 0 else {
            return
        }

        let workout = Workout(name: "Workout A", position: 0)
        context.insert(workout)

        for exercise in workoutA {
            let inserted = Exercise(
                position: exercise.position,
                name: exercise.name,
                setsText: exercise.setsText,
                repsText: exercise.repsText,
                weightText: exercise.weightText,
                notes: exercise.notes,
                bundledPhotoName: exercise.bundledPhotoName
            )
            inserted.workout = workout
            context.insert(inserted)
        }

        try context.save()
    }

    private static let workoutA = [
        SeedExercise(position: 1, name: "Cross trainer", setsText: "N/A", repsText: "N/A", weightText: "N/A", notes: "10 mins", bundledPhotoName: "cross-trainer"),
        SeedExercise(position: 2, name: "Wall Agents", setsText: "2", repsText: "12", weightText: "", notes: "", bundledPhotoName: "wall-angels"),
        SeedExercise(position: 3, name: "Shoulder dislocates (with band or bar)", setsText: "2", repsText: "12", weightText: "", notes: "", bundledPhotoName: "shoulder-dislocates"),
        SeedExercise(position: 4, name: "Body weight squats", setsText: "2", repsText: "12", weightText: "", notes: "", bundledPhotoName: "bodyweight-squats"),
        SeedExercise(position: 5, name: "Leg Extension", setsText: "4", repsText: "6", weightText: "66", notes: "Machine; backrest 3", bundledPhotoName: "leg-extension"),
        SeedExercise(position: 6, name: "Leg Press", setsText: "3", repsText: "10", weightText: "86", notes: "Machine; seat 3", bundledPhotoName: "leg-press"),
        SeedExercise(position: 7, name: "Seated Leg Curl", setsText: "2", repsText: "10", weightText: "45", notes: "Machine; backrest 3, 1, 2", bundledPhotoName: "seated-leg-curl"),
        SeedExercise(position: 8, name: "Calf press", setsText: "3", repsText: "6", weightText: "79", notes: "Either standing, seated, or machine", bundledPhotoName: "calf-press"),
        SeedExercise(position: 9, name: "Assisted chin-up", setsText: "3", repsText: "8", weightText: "-23", notes: "Machine", bundledPhotoName: "assisted-chin-up"),
        SeedExercise(position: 10, name: "Cable row", setsText: "3", repsText: "8", weightText: "52", notes: "Machine", bundledPhotoName: "cable-row"),
        SeedExercise(position: 11, name: "Overhead Press", setsText: "2", repsText: "10", weightText: "25", notes: "Small barbells", bundledPhotoName: "overhead-press"),
        SeedExercise(position: 12, name: "Diverging lat pulldown", setsText: "2", repsText: "12", weightText: "45", notes: "Machine", bundledPhotoName: "diverging-lat-pulldown"),
        SeedExercise(position: 13, name: "Cable tricep pulldowns", setsText: "1", repsText: "12", weightText: "32", notes: "Machine", bundledPhotoName: "cable-tricep-pulldowns"),
        SeedExercise(position: 14, name: "Dumbbell curls", setsText: "2", repsText: "6", weightText: "12", notes: "Free dumbbells", bundledPhotoName: "dumbbell-curls")
    ]
}

private struct SeedExercise {
    let position: Int
    let name: String
    let setsText: String
    let repsText: String
    let weightText: String
    let notes: String
    let bundledPhotoName: String
}

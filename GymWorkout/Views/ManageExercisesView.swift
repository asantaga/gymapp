import SwiftData
import SwiftUI

struct ManageExercisesView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var workout: Workout

    @State private var isShowingAddExercise = false
    @State private var editingExercise: Exercise?

    private var sortedExercises: [Exercise] {
        workout.exercises.sorted { $0.position < $1.position }
    }

    var body: some View {
        List {
            ForEach(sortedExercises) { exercise in
                Button {
                    editingExercise = exercise
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(exercise.name)
                            .font(.body)
                            .foregroundStyle(.primary)
                        Text("Sets \(exercise.setsText) • Reps \(exercise.repsText) • \(exercise.weightText)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteExercises)
            .onMove(perform: moveExercises)
        }
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isShowingAddExercise = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $isShowingAddExercise) {
            ExerciseEditView(workout: workout, exercise: nil)
        }
        .sheet(item: $editingExercise) { exercise in
            ExerciseEditView(workout: workout, exercise: exercise)
        }
    }

    private func deleteExercises(at offsets: IndexSet) {
        let exercises = sortedExercises
        for offset in offsets {
            let exercise = exercises[offset]
            if let filename = exercise.userPhotoFilename {
                ExercisePhotoStore.delete(filename: filename)
            }
            modelContext.delete(exercise)
        }
        save()
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        var exercises = sortedExercises
        exercises.move(fromOffsets: source, toOffset: destination)
        for (index, exercise) in exercises.enumerated() {
            exercise.position = index
        }
        save()
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Unable to save exercises: \(error)")
        }
    }
}

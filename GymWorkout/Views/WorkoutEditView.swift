import SwiftData
import SwiftUI

struct WorkoutEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let workout: Workout?
    private let onCreate: ((Workout) -> Void)?

    @State private var name: String

    init(workout: Workout?, onCreate: ((Workout) -> Void)? = nil) {
        self.workout = workout
        self.onCreate = onCreate
        _name = State(initialValue: workout?.name ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Workout name", text: $name)
                        .autocorrectionDisabled(false)
                }

                if let workout {
                    Section {
                        Button("Delete Workout", role: .destructive) {
                            delete(workout)
                        }
                    }
                }
            }
            .navigationTitle(workout == nil ? "New Workout" : "Rename Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if let workout {
            workout.name = trimmedName
        } else {
            let count = (try? modelContext.fetchCount(FetchDescriptor<Workout>())) ?? 0
            let newWorkout = Workout(name: trimmedName, position: count)
            modelContext.insert(newWorkout)
            onCreate?(newWorkout)
        }

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Unable to save workout: \(error)")
        }

        dismiss()
    }

    private func delete(_ workout: Workout) {
        modelContext.delete(workout)
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Unable to delete workout: \(error)")
        }
        dismiss()
    }
}

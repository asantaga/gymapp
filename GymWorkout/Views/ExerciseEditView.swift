import PhotosUI
import SwiftData
import SwiftUI

struct ExerciseEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let workout: Workout
    private let exercise: Exercise?

    @State private var name: String
    @State private var setsText: String
    @State private var repsText: String
    @State private var weightText: String
    @State private var notes: String

    @State private var photosPickerItem: PhotosPickerItem?
    @State private var pendingPhotoData: Data?
    @State private var didClearPhoto = false

    init(workout: Workout, exercise: Exercise?) {
        self.workout = workout
        self.exercise = exercise
        _name = State(initialValue: exercise?.name ?? "")
        _setsText = State(initialValue: exercise?.setsText ?? "")
        _repsText = State(initialValue: exercise?.repsText ?? "")
        _weightText = State(initialValue: exercise?.weightText ?? "")
        _notes = State(initialValue: exercise?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Exercise name", text: $name)
                }

                Section("Sets, Reps & Weight") {
                    TextField("Sets", text: $setsText)
                    TextField("Reps", text: $repsText)
                    TextField("Weight", text: $weightText)
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Photo") {
                    photoPreview
                    PhotosPicker("Choose Photo", selection: $photosPickerItem, matching: .images)
                    if hasAnyPhoto {
                        Button("Remove Photo", role: .destructive) {
                            pendingPhotoData = nil
                            photosPickerItem = nil
                            didClearPhoto = true
                        }
                    }
                }

                if let exercise {
                    Section {
                        Button("Delete Exercise", role: .destructive) {
                            delete(exercise)
                        }
                    }
                }
            }
            .navigationTitle(exercise == nil ? "New Exercise" : "Edit Exercise")
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
            .onChange(of: photosPickerItem) {
                loadPickedPhoto()
            }
        }
    }

    private var hasAnyPhoto: Bool {
        pendingPhotoData != nil || (!didClearPhoto && exercise?.userPhotoFilename != nil)
    }

    @ViewBuilder
    private var photoPreview: some View {
        if let pendingPhotoData, let uiImage = UIImage(data: pendingPhotoData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(height: 160)
                .frame(maxWidth: .infinity)
        } else if !didClearPhoto,
                  let filename = exercise?.userPhotoFilename,
                  let uiImage = ExercisePhotoStore.loadImage(filename: filename) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(height: 160)
                .frame(maxWidth: .infinity)
        }
    }

    private func loadPickedPhoto() {
        guard let photosPickerItem else { return }
        Task {
            if let data = try? await photosPickerItem.loadTransferable(type: Data.self) {
                pendingPhotoData = data
                didClearPhoto = false
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        let target: Exercise
        if let exercise {
            target = exercise
        } else {
            target = Exercise(
                position: workout.exercises.count,
                name: trimmedName,
                setsText: setsText,
                repsText: repsText,
                weightText: weightText,
                notes: notes
            )
            target.workout = workout
            modelContext.insert(target)
        }

        target.name = trimmedName
        target.setsText = setsText
        target.repsText = repsText
        target.weightText = weightText
        target.notes = notes

        if let pendingPhotoData {
            if let oldFilename = target.userPhotoFilename {
                ExercisePhotoStore.delete(filename: oldFilename)
            }
            target.userPhotoFilename = ExercisePhotoStore.save(pendingPhotoData)
        } else if didClearPhoto {
            if let oldFilename = target.userPhotoFilename {
                ExercisePhotoStore.delete(filename: oldFilename)
            }
            target.userPhotoFilename = nil
        }

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Unable to save exercise: \(error)")
        }

        dismiss()
    }

    private func delete(_ exercise: Exercise) {
        if let filename = exercise.userPhotoFilename {
            ExercisePhotoStore.delete(filename: filename)
        }
        modelContext.delete(exercise)
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Unable to delete exercise: \(error)")
        }
        dismiss()
    }
}

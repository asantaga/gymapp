import SwiftUI
import UIKit

struct ExerciseDetailCard: View {
    let exercise: Exercise

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 12) {
                exercisePhoto(
                    height: WorkoutPlayerLayout.exercisePhotoHeight(
                        forCardHeight: geometry.size.height
                    )
                )

                Text(exercise.name)
                    .font(.title.bold())
                    .foregroundStyle(WorkoutTheme.forest)
                    .fixedSize(horizontal: false, vertical: true)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        valueTile(label: "Sets", value: exercise.setsText)
                        valueTile(label: "Reps", value: exercise.repsText)
                        valueTile(label: "kg", value: exercise.weightText)
                    }

                    VStack(spacing: 10) {
                        valueTile(label: "Sets", value: exercise.setsText)
                        valueTile(label: "Reps", value: exercise.repsText)
                        valueTile(label: "kg", value: exercise.weightText)
                    }
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text("Notes")
                        .font(.headline)
                        .foregroundStyle(WorkoutTheme.forest)

                    Text(exercise.notes.isEmpty ? "No additional notes." : exercise.notes)
                        .font(.body)
                        .foregroundStyle(WorkoutTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
        }
        .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 14, y: 6)
    }

    @ViewBuilder
    private func exercisePhoto(height: CGFloat) -> some View {
        Group {
            if let userPhotoFilename = exercise.userPhotoFilename,
               let image = ExercisePhotoStore.loadImage(filename: userPhotoFilename) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if let photoName = exercise.bundledPhotoName,
               let image = UIImage(named: photoName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ZStack {
                    WorkoutTheme.mint
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 54, weight: .medium))
                        .foregroundStyle(WorkoutTheme.green)
                }
            }
        }
        .background(WorkoutTheme.mint)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(exercise.name) exercise photo")
        .accessibilityHint("Shows the movement or equipment for this exercise.")
    }

    private func valueTile(label: String, value: String) -> some View {
        VStack(spacing: 5) {
            Text(value.isEmpty ? "—" : value)
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(WorkoutTheme.forest)
                .fixedSize(horizontal: false, vertical: true)

            Text(label.uppercased())
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(WorkoutTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .padding(.horizontal, 8)
        .background(WorkoutTheme.mint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(value.isEmpty ? "not specified" : value)")
    }
}

import Foundation
import SwiftData

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var position: Int
    var name: String
    var setsText: String
    var repsText: String
    var weightText: String
    var notes: String
    var bundledPhotoName: String?
    var userPhotoFilename: String?

    init(
        position: Int,
        name: String,
        setsText: String,
        repsText: String,
        weightText: String,
        notes: String,
        bundledPhotoName: String? = nil,
        userPhotoFilename: String? = nil
    ) {
        self.id = UUID()
        self.position = position
        self.name = name
        self.setsText = setsText
        self.repsText = repsText
        self.weightText = weightText
        self.notes = notes
        self.bundledPhotoName = bundledPhotoName
        self.userPhotoFilename = userPhotoFilename
    }
}

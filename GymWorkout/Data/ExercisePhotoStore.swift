import Foundation
import UIKit

enum ExercisePhotoStore {
    private static let directoryName = "ExercisePhotos"

    private static var directoryURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent(directoryName, isDirectory: true)
    }

    @discardableResult
    static func save(_ data: Data) -> String? {
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        } catch {
            return nil
        }

        let filename = "\(UUID().uuidString).jpg"
        let fileURL = directoryURL.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL, options: .atomic)
            return filename
        } catch {
            return nil
        }
    }

    static func loadImage(filename: String) -> UIImage? {
        let fileURL = directoryURL.appendingPathComponent(filename)
        return UIImage(contentsOfFile: fileURL.path)
    }

    static func delete(filename: String) {
        let fileURL = directoryURL.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
    }
}

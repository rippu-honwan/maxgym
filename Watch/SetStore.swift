import Foundation
import MaxGymCore

/// Saves each set as a CSV file in Documents/sets.
enum SetStore {
    static var folder: URL {
        URL.documentsDirectory.appending(path: "sets", directoryHint: .isDirectory)
    }

    @discardableResult
    static func save(_ meta: SetMetadata, samples: [MotionSample]) throws -> URL {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appending(path: SetCSV.fileName(for: meta))
        try SetCSV.encode(meta, samples: samples).write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}

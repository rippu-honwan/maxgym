import Foundation
import WatchConnectivity

/// Saves each set as a CSV, then sends it to the iPhone.
/// The leading "#" lines record the labels (exercise, true rep count);
/// Python skips them automatically with pd.read_csv(path, comment="#").
final class SetStore: NSObject, WCSessionDelegate {
    static let shared = SetStore()

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    /// Save to disk + queue the transfer to iPhone (even if the iPhone is away, it sends once reconnected)
    @discardableResult
    func save(rows: [String], exerciseID: String, exerciseName: String,
              trueReps: Int, sampleRate: Double) throws -> URL {
        let now = Date()
        let iso = ISO8601DateFormatter().string(from: now)
        let stamp = Self.fileStamp.string(from: now)
        let fileName = "\(stamp)_\(exerciseID)_\(trueReps)reps.csv"

        var lines: [String] = [
            "# exercise=\(exerciseID)",
            "# exercise_name=\(exerciseName)",
            "# true_reps=\(trueReps)",
            "# sample_rate_hz=\(Int(sampleRate))",
            "# recorded_at=\(iso)",
            MotionRecorder.csvHeader
        ]
        lines.append(contentsOf: rows)

        let url = Self.folder.appendingPathComponent(fileName)
        try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)

        if WCSession.default.activationState == .activated {
            WCSession.default.transferFile(url, metadata: ["fileName": fileName])
        }
        return url
    }

    /// Number of sets not yet transferred to iPhone (for display)
    var pendingTransfers: Int {
        WCSession.isSupported() ? WCSession.default.outstandingFileTransfers.count : 0
    }

    static var folder: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("sets", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static let fileStamp: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd-HHmmss"
        return f
    }()

    // MARK: WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        // On success, delete it from the watch to save space; on failure, keep it to retry later
        if error == nil {
            try? FileManager.default.removeItem(at: fileTransfer.file.fileURL)
        }
    }
}

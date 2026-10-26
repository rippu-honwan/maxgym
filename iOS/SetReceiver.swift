import Foundation
import Observation
import OSLog
import WatchConnectivity

/// Receives CSV files from the watch and keeps them in Documents/sets.
/// Info.plist enables file sharing, so the folder also shows up in the Files app and in Finder over USB.
@MainActor @Observable
final class SetReceiver: NSObject {
    private(set) var files: [URL] = []

    nonisolated static var folder: URL {
        URL.documentsDirectory.appending(path: "sets", directoryHint: .isDirectory)
    }

    private nonisolated let log = Logger(subsystem: "com.kenlip.MaxGym", category: "transfer")

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        reload()
    }

    func reload() {
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: Self.folder, includingPropertiesForKeys: nil)) ?? []
        files = urls.filter { $0.pathExtension == "csv" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    func delete(at offsets: IndexSet) {
        for i in offsets {
            try? FileManager.default.removeItem(at: files[i])
        }
        reload()
    }
}

extension SetReceiver: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState,
                             error: Error?) {
        if let error {
            log.error("Activation failed: \(error.localizedDescription)")
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate() // e.g. after switching to another paired watch
    }

    /// The system deletes `file.fileURL` as soon as this returns, so move it synchronously here.
    nonisolated func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let name = file.fileURL.lastPathComponent
        let dest = Self.folder.appending(path: name)
        do {
            try FileManager.default.createDirectory(at: Self.folder, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.moveItem(at: file.fileURL, to: dest)
        } catch {
            // The watch has already deleted its copy, so this set is lost. Make it visible in the log.
            log.fault("Could not store \(name): \(error.localizedDescription)")
        }
        Task { @MainActor in self.reload() }
    }
}

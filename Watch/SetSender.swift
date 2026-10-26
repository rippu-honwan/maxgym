import Foundation
import OSLog
import WatchConnectivity

/// Sends saved CSV files to the iPhone with WatchConnectivity.
/// A file is deleted from the watch only after the transfer succeeds, so nothing is lost
/// when the iPhone is out of range: the system queues the transfer until it reconnects.
final class SetSender: NSObject, WCSessionDelegate, Sendable {
    static let shared = SetSender()

    private let log = Logger(subsystem: "com.kenlip.MaxGym", category: "transfer")

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Queues one file. If the session is not active yet, `sendPending()` picks it up on activation.
    func send(_ url: URL) {
        guard WCSession.default.activationState == .activated else { return }
        WCSession.default.transferFile(url, metadata: nil)
    }

    /// Queues every saved file that is not already being transferred.
    private func sendPending() {
        let session = WCSession.default
        let inFlight = Set(session.outstandingFileTransfers.map { $0.file.fileURL.lastPathComponent })
        let files = (try? FileManager.default.contentsOfDirectory(
            at: SetStore.folder, includingPropertiesForKeys: nil)) ?? []
        for url in files where url.pathExtension == "csv" && !inFlight.contains(url.lastPathComponent) {
            session.transferFile(url, metadata: nil)
        }
    }

    // MARK: WCSessionDelegate (called on a background queue)

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {
        if let error {
            log.error("Activation failed: \(error.localizedDescription)")
        }
        if state == .activated {
            sendPending()
        }
    }

    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        let url = fileTransfer.file.fileURL
        if let error {
            // ponytail: retried on next app launch (activation); add a retry timer if that proves too slow.
            log.error("Transfer failed for \(url.lastPathComponent): \(error.localizedDescription)")
            return
        }
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            log.error("Could not delete sent file \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }
}

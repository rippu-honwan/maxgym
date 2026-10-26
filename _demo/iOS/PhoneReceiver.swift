import Foundation
import WatchConnectivity

/// The iPhone receives CSVs sent from the watch and stores them in the app's Documents/sets.
/// Because Info.plist enables file sharing, you can see this folder in the Files app,
/// or connect to a Mac over USB and drag the files out in Finder.
@MainActor
final class PhoneReceiver: NSObject, ObservableObject {
    @Published private(set) var files: [URL] = []

    nonisolated static var folder: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("sets", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

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
        for i in offsets { try? FileManager.default.removeItem(at: files[i]) }
        reload()
    }
}

extension PhoneReceiver: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith state: WCSessionActivationState,
                             error: Error?) {}
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    /// Important: the system deletes the temp file once this function returns, so move it immediately
    nonisolated func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let name = (file.metadata?["fileName"] as? String) ?? file.fileURL.lastPathComponent
        let dest = Self.folder.appendingPathComponent(name)
        try? FileManager.default.removeItem(at: dest)
        try? FileManager.default.moveItem(at: file.fileURL, to: dest)
        Task { @MainActor in self.reload() }
    }
}

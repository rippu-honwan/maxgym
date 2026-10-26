import Foundation
import CoreMotion

/// Records the Apple Watch motion-sensor data (50 samples per second).
/// Each row = one time point: time, acceleration (x,y,z), gravity direction (x,y,z), rotation rate (x,y,z)
final class MotionRecorder {
    private let manager = CMMotionManager()
    private var rows: [String] = []
    private var startTimestamp: TimeInterval?

    let sampleRate: Double = 50

    var isAvailable: Bool { manager.isDeviceMotionAvailable }

    func start() {
        rows = []
        startTimestamp = nil
        manager.deviceMotionUpdateInterval = 1.0 / sampleRate
        // Collect on the main queue: 50 Hz is light, so this is the simplest and least buggy approach
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let m = motion else { return }
            if self.startTimestamp == nil { self.startTimestamp = m.timestamp }
            let t = m.timestamp - (self.startTimestamp ?? m.timestamp)
            let a = m.userAcceleration
            let g = m.gravity
            let r = m.rotationRate
            self.rows.append(String(
                format: "%.4f,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f",
                t, a.x, a.y, a.z, g.x, g.y, g.z, r.x, r.y, r.z
            ))
        }
    }

    /// Stop recording and return all data rows
    func stop() -> [String] {
        manager.stopDeviceMotionUpdates()
        return rows
    }

    static let csvHeader = "t,acc_x,acc_y,acc_z,grav_x,grav_y,grav_z,rot_x,rot_y,rot_z"
}

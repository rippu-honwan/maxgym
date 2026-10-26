import CoreMotion
import MaxGymCore

/// Reads CMDeviceMotion at 50 Hz and keeps every reading as a MotionSample.
@MainActor
final class MotionRecorder {
    static let sampleRateHz = 50

    private let manager = CMMotionManager()
    private var samples: [MotionSample] = []
    private var firstTimestamp: TimeInterval?

    var isAvailable: Bool { manager.isDeviceMotionAvailable }

    func start() {
        samples = []
        firstTimestamp = nil
        manager.deviceMotionUpdateInterval = 1.0 / Double(Self.sampleRateHz)
        // ponytail: main queue is fine at 50 Hz (~3,000 samples per minute); use a background queue if the UI stutters.
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion else { return }
            MainActor.assumeIsolated { self?.append(motion) }
        }
    }

    /// Stops the sensors and returns everything recorded since `start()`.
    func stop() -> [MotionSample] {
        manager.stopDeviceMotionUpdates()
        return samples
    }

    private func append(_ m: CMDeviceMotion) {
        let first = firstTimestamp ?? m.timestamp
        firstTimestamp = first
        let a = m.userAcceleration, g = m.gravity, r = m.rotationRate, q = m.attitude.quaternion
        samples.append(MotionSample(
            t: m.timestamp - first,
            acc: [a.x, a.y, a.z],
            grav: [g.x, g.y, g.z],
            rot: [r.x, r.y, r.z],
            att: [q.w, q.x, q.y, q.z]
        ))
    }
}

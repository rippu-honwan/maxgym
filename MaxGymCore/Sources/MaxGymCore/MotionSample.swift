/// One CMDeviceMotion reading, copied into plain numbers so the core has no CoreMotion dependency.
public struct MotionSample: Sendable, Equatable {
    /// Seconds since the first sample of the set.
    public var t: Double
    /// User acceleration (gravity removed), in g.
    public var acc: SIMD3<Double>
    /// Gravity direction, in g.
    public var grav: SIMD3<Double>
    /// Rotation rate, in rad/s.
    public var rot: SIMD3<Double>
    /// Attitude quaternion stored as (w, x, y, z).
    public var att: SIMD4<Double>

    public init(t: Double, acc: SIMD3<Double>, grav: SIMD3<Double>, rot: SIMD3<Double>, att: SIMD4<Double>) {
        self.t = t
        self.acc = acc
        self.grav = grav
        self.rot = rot
        self.att = att
    }
}

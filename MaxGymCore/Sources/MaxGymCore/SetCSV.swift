import Foundation

public enum Side: String, Sendable {
    case left, right
}

/// Everything about a set except the samples. Written as `# key=value` header lines.
public struct SetMetadata: Sendable, Equatable {
    public var exercise: Exercise
    /// The label: rep count entered by the user after the set.
    public var trueReps: Int
    /// Load in kg. nil = bodyweight (written as an empty value).
    public var weightKg: Double?
    public var sampleRateHz: Int
    public var recordedAt: Date
    /// Which wrist the watch is worn on, and which side the crown faces. Both flip the sensor axes.
    public var wrist: Side
    public var crown: Side

    public init(exercise: Exercise, trueReps: Int, weightKg: Double?, sampleRateHz: Int, recordedAt: Date, wrist: Side, crown: Side) {
        self.exercise = exercise
        self.trueReps = trueReps
        self.weightKg = weightKg
        self.sampleRateHz = sampleRateHz
        self.recordedAt = recordedAt
        self.wrist = wrist
        self.crown = crown
    }
}

/// CSV format v1. This is a contract with `analysis/maxgym_csv.py`; see README.md.
public enum SetCSV {
    public static let formatVersion = 1
    public static let columns = "t,acc_x,acc_y,acc_z,grav_x,grav_y,grav_z,rot_x,rot_y,rot_z,att_w,att_x,att_y,att_z"

    public static func encode(_ meta: SetMetadata, samples: [MotionSample]) -> String {
        var lines = [
            "# format_version=\(formatVersion)",
            "# exercise=\(meta.exercise.id)",
            "# true_reps=\(meta.trueReps)",
            "# weight_kg=\(meta.weightKg.map { String(format: "%g", $0) } ?? "")",
            "# sample_rate_hz=\(meta.sampleRateHz)",
            "# recorded_at=\(meta.recordedAt.formatted(.iso8601))",
            "# wrist=\(meta.wrist.rawValue)",
            "# crown=\(meta.crown.rawValue)",
            columns,
        ]
        for s in samples {
            let values = [s.acc.x, s.acc.y, s.acc.z, s.grav.x, s.grav.y, s.grav.z,
                          s.rot.x, s.rot.y, s.rot.z, s.att[0], s.att[1], s.att[2], s.att[3]]
            lines.append(([String(format: "%.4f", s.t)] + values.map { String(format: "%.5f", $0) })
                .joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// `yyyyMMdd-HHmmss_<exercise>_<n>reps.csv`, time in `timeZone` (local by default).
    public static func fileName(for meta: SetMetadata, timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: meta.recordedAt)
        let stamp = String(format: "%04d%02d%02d-%02d%02d%02d",
                           c.year!, c.month!, c.day!, c.hour!, c.minute!, c.second!)
        return "\(stamp)_\(meta.exercise.id)_\(meta.trueReps)reps.csv"
    }

    /// Reads the exercise ID and rep count back from a file name. Returns nil if it does not match.
    /// The ID is a plain String so files from exercises added later still parse.
    public static func parseFileName(_ name: String) -> (exerciseID: String, trueReps: Int)? {
        guard name.hasSuffix(".csv") else { return nil }
        let parts = name.dropLast(4).split(separator: "_")
        guard parts.count >= 3,
              let last = parts.last, last.hasSuffix("reps"),
              let reps = Int(last.dropLast(4)) else { return nil }
        return (parts.dropFirst().dropLast().joined(separator: "_"), reps)
    }
}

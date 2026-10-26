/// Exercises we collect data for. The raw value is the ID written to CSV files and file names.
/// Squat is a control: little wrist motion, so it is expected to be hard to count.
public enum Exercise: String, CaseIterable, Identifiable, Sendable {
    case bicepCurl = "bicep_curl"
    case shoulderPress = "shoulder_press"
    case benchPress = "bench_press"
    case lateralRaise = "lateral_raise"
    case tricepPushdown = "tricep_pushdown"
    case squat = "squat"

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .bicepCurl: "Bicep Curl"
        case .shoulderPress: "Shoulder Press"
        case .benchPress: "Bench Press"
        case .lateralRaise: "Lateral Raise"
        case .tricepPushdown: "Tricep Pushdown"
        case .squat: "Squat"
        }
    }

    /// Decides how weight is entered (see README, weight convention).
    public var equipment: Equipment {
        switch self {
        case .bicepCurl, .shoulderPress, .lateralRaise: .dumbbell
        case .benchPress, .squat: .barbell
        case .tricepPushdown: .machine
        }
    }
}

public enum Equipment: Sendable {
    /// Weight of one dumbbell (the hand wearing the watch).
    case dumbbell
    /// Total weight including the bar.
    case barbell
    /// Stack value shown on the machine or cable.
    case machine
}

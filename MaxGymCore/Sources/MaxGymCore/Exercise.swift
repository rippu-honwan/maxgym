/// Exercises we record. The raw value is the ID written to CSV files and file names.
/// Recording rule: only exercises where the wrist moves or rotates in space (see README).
public enum Exercise: String, CaseIterable, Identifiable, Sendable {
    // Core
    case cableLateralRaise = "cable_lateral_raise"
    case cableBicepsCurl = "cable_biceps_curl"
    case latPulldown = "lat_pulldown"
    case latPulldownNarrow = "lat_pulldown_narrow"
    case machineChestPress = "machine_chest_press"
    case machineSeatedRow = "machine_seated_row"
    case machineShoulderPress = "machine_shoulder_press"
    case cableOverheadTricepsExtension = "cable_overhead_triceps_extension"
    case cableChestFly = "cable_chest_fly"
    case smithRDL = "smith_rdl"
    case cableTricepsPushdown = "cable_triceps_pushdown"
    case cableFacePull = "cable_face_pull"
    // Experimental
    case assistedPullUp = "assisted_pull_up"
    case assistedDip = "assisted_dip"
    case smithSquat = "smith_squat"
    case smithHipThrust = "smith_hip_thrust"
    case cableCrunch = "cable_crunch"
    case machineTorsoRotation = "machine_torso_rotation"

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .cableLateralRaise: "Cable Lateral Raise"
        case .cableBicepsCurl: "Cable Biceps Curl"
        case .latPulldown: "Lat Pulldown"
        case .latPulldownNarrow: "Lat Pulldown Narrow"
        case .machineChestPress: "Chest Press"
        case .machineSeatedRow: "Seated Row"
        case .machineShoulderPress: "Shoulder Press"
        case .cableOverheadTricepsExtension: "Overhead Triceps Ext."
        case .cableChestFly: "Cable Chest Fly"
        case .smithRDL: "Smith RDL"
        case .cableTricepsPushdown: "Triceps Pushdown"
        case .cableFacePull: "Face Pull"
        case .assistedPullUp: "Assisted Pull-up"
        case .assistedDip: "Assisted Dip"
        case .smithSquat: "Smith Squat"
        case .smithHipThrust: "Smith Hip Thrust"
        case .cableCrunch: "Cable Crunch"
        case .machineTorsoRotation: "Torso Rotation"
        }
    }

    public var tier: Tier {
        switch self {
        case .assistedPullUp, .assistedDip, .smithSquat, .smithHipThrust, .cableCrunch, .machineTorsoRotation:
            .experimental
        default:
            .core
        }
    }

    /// Decides how weight is entered (see README, weight convention).
    public var equipment: Equipment {
        switch self {
        case .latPulldown, .latPulldownNarrow, .machineChestPress, .machineSeatedRow,
             .machineShoulderPress, .machineTorsoRotation:
            .machine
        case .cableLateralRaise, .cableBicepsCurl, .cableOverheadTricepsExtension, .cableChestFly,
             .cableTricepsPushdown, .cableFacePull, .cableCrunch:
            .cable
        case .smithRDL, .smithSquat, .smithHipThrust:
            .smith
        case .assistedPullUp, .assistedDip:
            .assisted
        }
    }
}

public enum Tier: String, Sendable {
    /// Clear wrist signal; main focus of Phase 2.
    case core
    /// Recorded anyway; expected to be hard to count.
    case experimental
}

public enum Equipment: Sendable {
    /// Weight = stack value shown on the machine.
    case machine
    /// Weight = stack value shown on the cable station.
    case cable
    /// Weight = plates only, without the bar.
    case smith
    /// Weight = assistance as a negative number (e.g. -47).
    case assisted
}

extension Equipment {
    /// Converts the value entered on the watch to `weight_kg`.
    /// 0 means bodyweight (nil, written empty), except on Smith where 0 means bar only.
    public func weightKg(fromEntered value: Double) -> Double? {
        value == 0 && self != .smith ? nil : value
    }
}

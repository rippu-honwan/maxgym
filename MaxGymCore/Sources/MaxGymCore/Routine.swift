/// One training day: the recordable exercises in gym order.
public struct WorkoutDay: Identifiable, Hashable, Sendable {
    public let name: String
    public let exercises: [Exercise]

    public var id: String { name }
}

/// The current routine. Plain static data; edit here to change it.
public enum Routine {
    public static let days: [WorkoutDay] = [
        WorkoutDay(name: "Upper A", exercises: [
            .machineChestPress, .machineSeatedRow, .latPulldown, .machineShoulderPress,
            .cableLateralRaise, .cableOverheadTricepsExtension, .cableBicepsCurl, .cableCrunch,
        ]),
        WorkoutDay(name: "Upper B", exercises: [
            .assistedPullUp, .assistedDip, .latPulldownNarrow, .cableChestFly,
            .cableLateralRaise, .cableFacePull, .cableTricepsPushdown, .cableBicepsCurl,
        ]),
        WorkoutDay(name: "Lower A", exercises: [.smithRDL]),
        WorkoutDay(name: "Lower B", exercises: [.smithSquat, .smithHipThrust, .machineTorsoRotation]),
    ]
}

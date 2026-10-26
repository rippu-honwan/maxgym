import Foundation

/// Phase 1 only covers moves with clear wrist motion, so the data stays much cleaner.
/// Squat is kept last as a control: expected to be harder, which is exactly why it is useful.
struct Exercise: Identifiable, Hashable {
    let id: String      // Written to the file name and CSV; English keeps Python processing simple
    let name: String    // Display label

    static let all: [Exercise] = [
        Exercise(id: "bicep_curl", name: "Bicep Curl"),
        Exercise(id: "shoulder_press", name: "Shoulder Press"),
        Exercise(id: "bench_press", name: "Bench Press"),
        Exercise(id: "lateral_raise", name: "Lateral Raise"),
        Exercise(id: "tricep_pushdown", name: "Tricep Pushdown"),
        Exercise(id: "squat", name: "Squat (control)")
    ]
}

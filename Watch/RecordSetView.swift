import SwiftUI
import WatchKit

/// Second screen: record one set
/// Flow: Start → do the set → Stop → turn the Digital Crown to enter the true rep count → Save
/// The "true rep count" is the machine-learning label (ground truth), so it must be entered correctly.
struct RecordSetView: View {
    let exercise: Exercise
    let onSaved: () -> Void

    @EnvironmentObject var workout: WorkoutManager
    @Environment(\.dismiss) private var dismiss

    private enum Phase { case ready, recording, labeling }

    @State private var phase: Phase = .ready
    @State private var recorder = MotionRecorder()
    @State private var rows: [String] = []
    @State private var startDate = Date()
    // The Crown only reports Double values, so store a Double and round to Int when used
    @State private var crownValue: Double = 10
    private var reps: Int { Int(crownValue.rounded()) }
    @State private var errorText: String?

    var body: some View {
        VStack(spacing: 8) {
            Text(exercise.name).font(.headline)

            switch phase {
            case .ready:
                Button {
                    workout.startIfNeeded()
                    recorder.start()
                    startDate = Date()
                    WKInterfaceDevice.current().play(.start)
                    phase = .recording
                } label: {
                    Label("Start", systemImage: "record.circle")
                        .frame(maxWidth: .infinity)
                }
                .tint(.green)
                .disabled(!recorder.isAvailable)

                if !recorder.isAvailable {
                    Text("This device has no motion sensors (Simulator?)")
                        .font(.footnote).foregroundStyle(.secondary)
                }

            case .recording:
                TimelineView(.periodic(from: startDate, by: 1)) { context in
                    Text(elapsed(context.date))
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }
                Button {
                    rows = recorder.stop()
                    WKInterfaceDevice.current().play(.stop)
                    phase = .labeling
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(.red)

            case .labeling:
                Text("How many reps did you actually do?").font(.footnote)
                Text("\(reps)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .focusable()
                    .digitalCrownRotation($crownValue, from: 0, through: 50, by: 1,
                                          sensitivity: .low, isHapticFeedbackEnabled: true)
                HStack {
                    Button("Discard") { reset() }
                    Button("Save") { save() }.tint(.blue)
                }
                if let errorText {
                    Text(errorText).font(.footnote).foregroundStyle(.red)
                }
            }
        }
        .padding(.horizontal, 4)
        .navigationBarBackButtonHidden(phase == .recording)
    }

    private func elapsed(_ now: Date) -> String {
        let s = Int(now.timeIntervalSince(startDate))
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    private func save() {
        do {
            try SetStore.shared.save(rows: rows, exerciseID: exercise.id,
                                     exerciseName: exercise.name,
                                     trueReps: reps, sampleRate: recorder.sampleRate)
            WKInterfaceDevice.current().play(.success)
            onSaved()
            dismiss()
        } catch {
            errorText = "Save failed: \(error.localizedDescription)"
        }
    }

    private func reset() {
        rows = []
        phase = .ready
    }
}

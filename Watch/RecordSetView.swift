import SwiftUI
import WatchKit
import MaxGymCore

/// Records one set: Start → do the set → Stop → enter the true rep count with the crown → Save.
/// The rep count is the label (ground truth), so Discard is there for when you are not sure.
struct RecordSetView: View {
    let exercise: Exercise
    let onSaved: () -> Void

    @Environment(WorkoutManager.self) private var workout
    @Environment(\.dismiss) private var dismiss

    private enum Phase { case ready, recording, labeling }

    @State private var phase = Phase.ready
    @State private var recorder = MotionRecorder()
    @State private var samples: [MotionSample] = []
    @State private var startDate = Date()
    @State private var crownValue = 10.0 // the crown needs a floating-point binding
    @State private var errorText: String?

    private var reps: Int { Int(crownValue.rounded()) }

    var body: some View {
        VStack(spacing: 6) {
            switch phase {
            case .ready:
                bigButton("Start", icon: "play.fill", color: .green, action: start)
                    .disabled(!recorder.isAvailable)
                if !recorder.isAvailable {
                    Text("No motion sensor").font(.footnote).foregroundStyle(.secondary)
                }

            case .recording:
                TimelineView(.periodic(from: startDate, by: 1)) { context in
                    Text(Duration.seconds(context.date.timeIntervalSince(startDate))
                        .formatted(.time(pattern: .minuteSecond)))
                        .font(.title2.monospacedDigit())
                }
                bigButton("Stop", icon: "stop.fill", color: .red, action: stop)

            case .labeling:
                Text("\(reps)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .focusable()
                    .digitalCrownRotation($crownValue, from: 1, through: 50, by: 1,
                                          sensitivity: .low, isContinuous: false,
                                          isHapticFeedbackEnabled: true)
                HStack {
                    Button("Discard", role: .destructive, action: discard)
                    Button("Save", action: save).tint(.blue)
                }
            }
            if let errorText {
                Text(errorText).font(.footnote).foregroundStyle(.red)
            }
        }
        .navigationTitle(exercise.name)
        // Leaving mid-set would lose the recording; Discard is the explicit way out.
        .navigationBarBackButtonHidden(phase != .ready)
    }

    private func bigButton(_ title: String, icon: String, color: Color,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.title2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(color)
    }

    private func start() {
        workout.startIfNeeded()
        recorder.start()
        startDate = Date()
        errorText = nil
        WKInterfaceDevice.current().play(.start)
        phase = .recording
    }

    private func stop() {
        samples = recorder.stop()
        WKInterfaceDevice.current().play(.stop)
        phase = .labeling
    }

    private func save() {
        let device = WKInterfaceDevice.current()
        let meta = SetMetadata(
            exercise: exercise,
            trueReps: reps,
            sampleRateHz: MotionRecorder.sampleRateHz,
            recordedAt: startDate,
            wrist: device.wristLocation == .left ? .left : .right,
            crown: device.crownOrientation == .left ? .left : .right
        )
        do {
            try SetStore.save(meta, samples: samples)
            device.play(.success)
            onSaved()
            dismiss()
        } catch {
            device.play(.failure)
            errorText = "Save failed"
        }
    }

    private func discard() {
        samples = []
        WKInterfaceDevice.current().play(.retry)
        phase = .ready
    }
}

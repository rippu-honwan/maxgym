import SwiftUI
import WatchKit
import MaxGymCore

/// Records one set: Start → do the set → Stop → reps (crown) → weight (crown) → Save.
/// The rep count is the label (ground truth), so Discard is there for when you are not sure.
struct RecordSetView: View {
    let exercise: Exercise
    let onSaved: () -> Void

    @Environment(WorkoutManager.self) private var workout
    @Environment(\.dismiss) private var dismiss

    private enum Phase { case ready, recording, reps, weight }

    @State private var phase = Phase.ready
    @State private var recorder = MotionRecorder()
    @State private var samples: [MotionSample] = []
    @State private var startDate = Date()
    // The crown needs floating-point bindings; reps are rounded to Int.
    @State private var repsValue = 10.0
    @State private var weightValue = 0.0 // 0 = bodyweight
    @State private var errorText: String?

    private var reps: Int { Int(repsValue.rounded()) }
    private var weightKg: Double? { weightValue > 0 ? weightValue : nil }
    /// Short reminder of the weight convention (README), shown under the value.
    private var weightUnit: String {
        switch exercise.equipment {
        case .dumbbell: "kg per hand"
        case .barbell: "kg incl. bar"
        case .machine: "kg stack"
        }
    }
    /// Last weight per exercise, so the next set starts at the same load.
    private var weightKey: String { "lastWeightKg.\(exercise.id)" }

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

            case .reps:
                crownNumber("\(reps)", unit: "reps", value: $repsValue, range: 1...50, step: 1)
                HStack {
                    Button("Discard", role: .destructive, action: discard)
                    Button("Next", action: showWeight).tint(.blue)
                }

            case .weight:
                crownNumber(weightKg.map { $0.formatted() } ?? "BW",
                            unit: weightKg == nil ? "bodyweight" : weightUnit,
                            value: $weightValue, range: 0...300, step: 0.5)
                HStack {
                    Button("Back") { phase = .reps }
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

    /// A big number set with the Digital Crown.
    private func crownNumber(_ text: String, unit: String, value: Binding<Double>,
                             range: ClosedRange<Double>, step: Double) -> some View {
        VStack(spacing: 0) {
            Text(text)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(unit).font(.footnote).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .focusable()
        .digitalCrownRotation(value, from: range.lowerBound, through: range.upperBound, by: step,
                              sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
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
        phase = .reps
    }

    private func showWeight() {
        weightValue = UserDefaults.standard.double(forKey: weightKey) // 0 if never set
        WKInterfaceDevice.current().play(.click)
        phase = .weight
    }

    private func save() {
        let device = WKInterfaceDevice.current()
        let meta = SetMetadata(
            exercise: exercise,
            trueReps: reps,
            weightKg: weightKg,
            sampleRateHz: MotionRecorder.sampleRateHz,
            recordedAt: startDate,
            wrist: device.wristLocation == .left ? .left : .right,
            crown: device.crownOrientation == .left ? .left : .right
        )
        do {
            let url = try SetStore.save(meta, samples: samples)
            SetSender.shared.send(url)
            UserDefaults.standard.set(weightValue, forKey: weightKey)
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

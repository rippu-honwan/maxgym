import SwiftUI
import WatchKit
import MaxGymCore

/// First screen: pick an exercise.
struct ExerciseListView: View {
    @Environment(WorkoutManager.self) private var workout
    @State private var savedCount = 0

    var body: some View {
        NavigationStack {
            List {
                ForEach(Exercise.allCases) { exercise in
                    NavigationLink(exercise.name, value: exercise)
                }
                if savedCount > 0 {
                    Text("\(savedCount) sets saved")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if workout.isRunning {
                    Button("End Workout", systemImage: "stop.circle", role: .destructive) {
                        workout.end()
                        WKInterfaceDevice.current().play(.stop)
                    }
                }
                if let message = workout.errorMessage {
                    Text(message).font(.footnote).foregroundStyle(.red)
                }
            }
            .navigationTitle("MaxGym")
            .navigationDestination(for: Exercise.self) { exercise in
                RecordSetView(exercise: exercise) { savedCount += 1 }
            }
        }
    }
}

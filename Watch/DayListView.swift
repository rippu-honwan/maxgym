import SwiftUI
import WatchKit
import MaxGymCore

/// First screen: pick the training day, then an exercise from that day (in gym order).
struct DayListView: View {
    @Environment(WorkoutManager.self) private var workout
    @State private var savedCount = 0

    var body: some View {
        NavigationStack {
            List {
                ForEach(Routine.days) { day in
                    NavigationLink(day.name, value: day)
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
            .navigationDestination(for: WorkoutDay.self) { day in
                List(day.exercises) { exercise in
                    NavigationLink(exercise.name, value: exercise)
                }
                .navigationTitle(day.name)
            }
            .navigationDestination(for: Exercise.self) { exercise in
                RecordSetView(exercise: exercise) { savedCount += 1 }
            }
        }
    }
}

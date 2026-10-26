import SwiftUI

/// First screen: pick an exercise
struct ExerciseListView: View {
    @EnvironmentObject var workout: WorkoutManager
    @State private var savedCount = 0

    var body: some View {
        NavigationStack {
            List {
                ForEach(Exercise.all) { exercise in
                    NavigationLink(value: exercise) {
                        Text(exercise.name)
                    }
                }

                if savedCount > 0 {
                    Text("\(savedCount) sets saved today")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if workout.isRunning {
                    Button(role: .destructive) {
                        workout.end()
                    } label: {
                        Label("End Workout", systemImage: "stop.circle")
                    }
                }

                if let msg = workout.errorMessage {
                    Text(msg).font(.footnote).foregroundStyle(.red)
                }
            }
            .navigationTitle("MaxGym")
            .navigationDestination(for: Exercise.self) { exercise in
                RecordSetView(exercise: exercise) { savedCount += 1 }
            }
        }
    }
}

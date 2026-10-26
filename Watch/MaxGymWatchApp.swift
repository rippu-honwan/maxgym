import SwiftUI

@main
struct MaxGymWatchApp: App {
    @State private var workout = WorkoutManager()

    var body: some Scene {
        WindowGroup {
            ExerciseListView()
                .environment(workout)
                .task { await workout.requestAuthorization() }
        }
    }
}

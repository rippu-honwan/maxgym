import SwiftUI

@main
struct MaxGymWatchApp: App {
    @StateObject private var workout = WorkoutManager()

    init() {
        _ = SetStore.shared   // Warm up the iPhone connection as soon as the app launches
    }

    var body: some Scene {
        WindowGroup {
            ExerciseListView()
                .environmentObject(workout)
                .task { await workout.requestAuthorization() }
        }
    }
}

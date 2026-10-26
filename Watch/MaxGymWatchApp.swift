import SwiftUI
import MaxGymCore

@main
struct MaxGymWatchApp: App {
    @State private var workout = WorkoutManager()

    var body: some Scene {
        WindowGroup {
            Text("MaxGym")
                .environment(workout)
                .task { await workout.requestAuthorization() }
        }
    }
}

import SwiftUI

@main
struct MaxGymWatchApp: App {
    @State private var workout = WorkoutManager()

    init() {
        SetSender.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            DayListView()
                .environment(workout)
                .task { await workout.requestAuthorization() }
        }
    }
}

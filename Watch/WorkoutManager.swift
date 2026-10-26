import Foundation
import HealthKit
import Observation

/// Keeps a strength workout running. Without it, watchOS suspends the app (and stops the
/// motion sensors) as soon as the wrist is lowered.
@MainActor @Observable
final class WorkoutManager {
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    private(set) var isRunning = false
    private(set) var errorMessage: String?

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let read: Set<HKObjectType> = [
            HKQuantityType(.heartRate),
            HKQuantityType(.activeEnergyBurned),
        ]
        do {
            try await healthStore.requestAuthorization(toShare: [HKObjectType.workoutType()], read: read)
        } catch {
            errorMessage = "Health access failed: \(error.localizedDescription)"
        }
    }

    /// Starts a workout unless one is already running. Called when the first set starts.
    func startIfNeeded() {
        guard session == nil else { return }
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor
        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
            let start = Date()
            session.startActivity(with: start)
            builder.beginCollection(withStart: start) { _, _ in }
            self.session = session
            self.builder = builder
            isRunning = true
        } catch {
            errorMessage = "Could not start workout: \(error.localizedDescription)"
        }
    }

    /// Ends the workout and saves it to the Health app.
    func end() {
        guard let session, let builder else { return }
        session.end()
        builder.endCollection(withEnd: Date()) { _, _ in
            builder.finishWorkout { _, _ in }
        }
        self.session = nil
        self.builder = nil
        isRunning = false
    }
}

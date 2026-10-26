import Foundation
import HealthKit

/// Why start a workout session?
/// When you lower your wrist, the watch suspends the app and the sensors stop.
/// Starting an HKWorkoutSession tells watchOS "a workout is in progress", so it keeps the app
/// recording in the background.
/// It is like telling a waiter "I'm still eating" so they won't clear your plate.
@MainActor
final class WorkoutManager: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    @Published var isRunning = false
    @Published var errorMessage: String?

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let share: Set<HKSampleType> = [HKObjectType.workoutType()]
        let read: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        do {
            try await healthStore.requestAuthorization(toShare: share, read: read)
        } catch {
            errorMessage = "HealthKit authorization failed: \(error.localizedDescription)"
        }
    }

    /// Start if not already started; do nothing if a session is already running
    func startIfNeeded() {
        guard session == nil else { return }
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor
        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
            self.session = session
            self.builder = builder
            let start = Date()
            session.startActivity(with: start)
            builder.beginCollection(withStart: start) { _, _ in }
            isRunning = true
        } catch {
            errorMessage = "Could not start workout: \(error.localizedDescription)"
        }
    }

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

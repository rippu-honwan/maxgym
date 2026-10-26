import Testing
import MaxGymCore

/// IDs go into file names and Python, so keep them lowercase snake_case.
@Test func exerciseIDsAreSnakeCase() {
    for exercise in Exercise.allCases {
        #expect(exercise.id.wholeMatch(of: /[a-z]+(_[a-z]+)*/) != nil, "\(exercise.id)")
    }
}

/// An exercise missing from every day could never be recorded.
@Test func everyExerciseIsInTheRoutine() {
    let used = Set(Routine.days.flatMap(\.exercises))
    #expect(used == Set(Exercise.allCases))
}

@Test func noDuplicatesWithinADay() {
    for day in Routine.days {
        #expect(Set(day.exercises).count == day.exercises.count, "\(day.name)")
    }
}

@Test func zeroWeightIsBodyweightExceptSmith() {
    #expect(Equipment.cable.weightKg(fromEntered: 0) == nil)
    #expect(Equipment.assisted.weightKg(fromEntered: 0) == nil)
    #expect(Equipment.smith.weightKg(fromEntered: 0) == 0)
    #expect(Equipment.assisted.weightKg(fromEntered: -47) == -47)
}

import Testing
import MaxGymCore

/// IDs go into file names and Python, so keep them lowercase snake_case.
@Test func exerciseIDsAreSnakeCase() {
    for exercise in Exercise.allCases {
        #expect(exercise.id.wholeMatch(of: /[a-z]+(_[a-z]+)*/) != nil, "\(exercise.id)")
    }
}

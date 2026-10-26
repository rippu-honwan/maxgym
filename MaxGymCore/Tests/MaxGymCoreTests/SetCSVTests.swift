import Foundation
import Testing
import MaxGymCore

private let meta = SetMetadata(
    exercise: .bicepCurl, trueReps: 3, weightKg: 12.5, sampleRateHz: 50,
    recordedAt: Date(timeIntervalSince1970: 1_792_995_300), // 2026-10-26T06:15:00Z
    wrist: .left, crown: .right
)

private let samples = [
    MotionSample(t: 0, acc: [0.01, -0.02, 0.03], grav: [0, -1, 0], rot: [0.1, 0.2, 0.3], att: [1, 0, 0, 0]),
    MotionSample(t: 0.02, acc: [0.015, -0.025, 0.035], grav: [0.1, -0.99499, 0], rot: [0.15, 0.25, 0.35],
                 att: [0.99875, 0.04998, 0, 0]),
    // Extra digits check rounding to 5 places.
    MotionSample(t: 0.04, acc: [-0.123456, 0, 0.5], grav: [0.2, -0.9798, 0], rot: [-1, 0, 2.5],
                 att: [0.995, 0.09983, 0, 0]),
]

/// The golden file is the contract with Python (`analysis/test_maxgym_csv.py` reads the same file).
@Test func encodeMatchesGoldenFile() throws {
    let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()
    let golden = try String(contentsOf: root.appending(path: "fixtures/set_v1.csv"), encoding: .utf8)
    #expect(SetCSV.encode(meta, samples: samples) == golden)
}

@Test func fileNameRoundTrips() throws {
    let name = SetCSV.fileName(for: meta, timeZone: TimeZone(identifier: "UTC")!)
    #expect(name == "20261026-061500_bicep_curl_3reps.csv")
    let parsed = try #require(SetCSV.parseFileName(name))
    #expect(parsed.exerciseID == "bicep_curl")
    #expect(parsed.trueReps == 3)
}

@Test func parseFileNameRejectsOtherFiles() {
    #expect(SetCSV.parseFileName("notes.txt") == nil)
    #expect(SetCSV.parseFileName("20261026-061500_squat.csv") == nil)
    #expect(SetCSV.parseFileName("20261026-061500_squat_xreps.csv") == nil)
}

@Test func bodyweightWritesEmptyWeight() {
    var bodyweight = meta
    bodyweight.weightKg = nil
    #expect(SetCSV.encode(bodyweight, samples: []).contains("\n# weight_kg=\n"))
}

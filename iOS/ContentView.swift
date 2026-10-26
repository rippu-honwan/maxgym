import SwiftUI
import MaxGymCore

/// Shows how many sets arrived per exercise and shares all CSVs in one tap (e.g. AirDrop to the Mac).
struct ContentView: View {
    @Environment(SetReceiver.self) private var receiver

    /// Aim for at least this many sets per exercise before analysing.
    private let targetSets = 15

    private var countsByExercise: [(id: String, count: Int)] {
        var counts: [String: Int] = [:]
        for url in receiver.files {
            if let parsed = SetCSV.parseFileName(url.lastPathComponent) {
                counts[parsed.exerciseID, default: 0] += 1
            }
        }
        return counts.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Sets per exercise (target \(targetSets))") {
                    if countsByExercise.isEmpty {
                        Text("No sets yet. Record one on your Apple Watch.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(countsByExercise, id: \.id) { item in
                        LabeledContent(Exercise(rawValue: item.id)?.name ?? item.id) {
                            Text("\(item.count)")
                                .monospacedDigit()
                                .foregroundStyle(item.count >= targetSets ? .green : .orange)
                        }
                    }
                }

                Section("Files (\(receiver.files.count))") {
                    ForEach(receiver.files, id: \.self) { url in
                        Text(url.lastPathComponent).font(.caption.monospaced())
                    }
                    .onDelete(perform: receiver.delete)
                }
            }
            .navigationTitle("MaxGym")
            .refreshable { receiver.reload() }
            .toolbar {
                if !receiver.files.isEmpty {
                    ShareLink(items: receiver.files) {
                        Label("Share All", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

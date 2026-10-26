import SwiftUI

/// iPhone screen: see how many sets arrived, how many per exercise, and share all CSVs in one tap (AirDrop to Mac)
struct ContentView: View {
    @EnvironmentObject var receiver: PhoneReceiver

    private var countsByExercise: [(String, Int)] {
        var counts: [String: Int] = [:]
        for url in receiver.files {
            // File name format: 20261023-141500_bicep_curl_10reps.csv
            let parts = url.deletingPathExtension().lastPathComponent.split(separator: "_")
            guard parts.count >= 3 else { continue }
            let exercise = parts.dropFirst().dropLast().joined(separator: "_")
            counts[exercise, default: 0] += 1
        }
        return counts.sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Sets collected per exercise (target: ≥ 15 each)") {
                    if countsByExercise.isEmpty {
                        Text("No data yet. Open MaxGym on your Apple Watch to record your first set.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(countsByExercise, id: \.0) { name, count in
                        HStack {
                            Text(name)
                            Spacer()
                            Text("\(count)")
                                .monospacedDigit()
                                .foregroundStyle(count >= 15 ? .green : .orange)
                        }
                    }
                }

                Section("All files (\(receiver.files.count))") {
                    ForEach(receiver.files, id: \.self) { url in
                        Text(url.lastPathComponent)
                            .font(.caption.monospaced())
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

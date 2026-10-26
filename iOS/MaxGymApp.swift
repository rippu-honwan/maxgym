import SwiftUI

@main
struct MaxGymApp: App {
    @State private var receiver = SetReceiver()

    var body: some Scene {
        WindowGroup {
            ContentView().environment(receiver)
        }
    }
}

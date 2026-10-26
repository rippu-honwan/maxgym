import SwiftUI

@main
struct MaxGymApp: App {
    @StateObject private var receiver = PhoneReceiver()

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(receiver)
        }
    }
}

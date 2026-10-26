// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MaxGymCore",
    // macOS is only here so `swift test` can run on the Mac.
    platforms: [.watchOS(.v10), .iOS(.v17), .macOS(.v14)],
    products: [.library(name: "MaxGymCore", targets: ["MaxGymCore"])],
    targets: [
        .target(name: "MaxGymCore"),
        .testTarget(name: "MaxGymCoreTests", dependencies: ["MaxGymCore"]),
    ]
)

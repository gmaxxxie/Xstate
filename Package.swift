// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Xstate",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "MonitorCore",
            targets: ["MonitorCore"]
        ),
        .executable(
            name: "Xstate",
            targets: ["SystemPulseApp"]
        )
    ],
    targets: [
        .target(
            name: "MonitorCore",
            path: "Sources/MonitorCore"
        ),
        .executableTarget(
            name: "SystemPulseApp",
            dependencies: ["MonitorCore"],
            path: "Sources/SystemPulseApp"
        ),
        .testTarget(
            name: "SystemPulseAppTests",
            dependencies: ["SystemPulseApp"],
            path: "Tests/SystemPulseAppTests"
        ),
        .testTarget(
            name: "MonitorCoreTests",
            dependencies: ["MonitorCore"],
            path: "Tests/MonitorCoreTests"
        )
    ]
)

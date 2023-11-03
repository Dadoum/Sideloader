// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "Sideloader",
    platforms: [.macOS(.v12), .iOS(.v15)],
    targets: [
        .binaryTarget(name: "SideloaderBackend", path: "Dependencies/SideloaderBackend.xcframework"),
        .executableTarget(
            name: "Sideloader",
            dependencies: ["SideloaderBackend"],
            path: "Sources"
        ),
    ]
)

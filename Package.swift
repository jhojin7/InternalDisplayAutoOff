// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "InternalDisplayAutoOff",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "InternalDisplayAutoOff", targets: ["InternalDisplayAutoOff"])
    ],
    targets: [
        .executableTarget(
            name: "InternalDisplayAutoOff",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("ServiceManagement")
            ]
        ),
        .testTarget(
            name: "InternalDisplayAutoOffTests",
            dependencies: ["InternalDisplayAutoOff"]
        )
    ]
)

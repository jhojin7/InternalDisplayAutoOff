// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacToolbox",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "MacToolbox", targets: ["MacToolbox"])
    ],
    targets: [
        .executableTarget(
            name: "MacToolbox",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("ServiceManagement")
            ]
        ),
        .testTarget(
            name: "MacToolboxTests",
            dependencies: ["MacToolbox"]
        )
    ]
)

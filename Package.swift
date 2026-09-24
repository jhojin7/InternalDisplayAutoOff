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
            dependencies: ["SystemControlsShim"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("ServiceManagement")
            ]
        ),
        .target(
            name: "SystemControlsShim",
            publicHeadersPath: "include",
            linkerSettings: [.linkedFramework("Foundation")]
        ),
        .testTarget(
            name: "MacToolboxTests",
            dependencies: ["MacToolbox"]
        )
    ]
)

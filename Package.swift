// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WindowResizer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "WindowResizer",
            targets: ["WindowResizer"]
        )
    ],
    targets: [
        .executableTarget(
            name: "WindowResizer",
            dependencies: [],
            path: "WindowResizer"
        )
    ]
)

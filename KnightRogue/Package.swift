// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "KnightRogue",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    dependencies: [],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "KnightRogue",
            dependencies: [],
            path: "Sources"
        )
    ]
)

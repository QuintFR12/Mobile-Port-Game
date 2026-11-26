// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MobilePortGame",
    platforms: [.iOS(.v16), .macOS(.v14)],
    products: [
        .library(name: "MobilePortCore", targets: ["MobilePortCore"]),
        .executable(name: "MobilePortApp", targets: ["MobilePortApp"])
    ],
    targets: [
        .target(name: "MobilePortCore", path: "Sources/MobilePortCore"),
        .executableTarget(
            name: "MobilePortApp",
            dependencies: ["MobilePortCore"],
            path: "Sources/MobilePortApp"
        ),
        .testTarget(
            name: "MobilePortCoreTests",
            dependencies: ["MobilePortCore"],
            path: "Tests/MobilePortCoreTests"
        )
    ]
)

// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MobilePortGame",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "MobilePortCore", targets: ["MobilePortCore"])
    ],
    targets: [
        .target(name: "MobilePortCore", path: "Sources/MobilePortCore"),
        .testTarget(
            name: "MobilePortCoreTests",
            dependencies: ["MobilePortCore"],
            path: "Tests/MobilePortCoreTests"
        )
    ]
)

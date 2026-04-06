// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TCAFlow",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16)
    ],
    products: [
        .library(
            name: "TCAFlow",
            targets: ["TCAFlow"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.25.5")
    ],
    targets: [
        .target(
            name: "TCAFlow",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .testTarget(
            name: "TCAFlowTests",
            dependencies: ["TCAFlow"]
        ),
    ]
)
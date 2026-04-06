// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TCAFlowExamplesSPM",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .executable(
            name: "TCAFlowExamplesSPM",
            targets: ["TCAFlowExamplesSPM"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.25.5"),
        .package(path: "../.."), // TCAFlow 로컬 패키지
    ],
    targets: [
        .executableTarget(
            name: "TCAFlowExamplesSPM",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "TCAFlow", package: "TCAFlow"),
            ]
        ),
    ]
)
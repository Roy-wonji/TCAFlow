// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TCAFlowApp",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .executable(name: "TCAFlowApp", targets: ["TCAFlowApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.25.5"),
        .package(path: "../.."), // TCAFlow 로컬 패키지
    ],
    targets: [
        .executableTarget(
            name: "TCAFlowApp",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "TCAFlow", package: "TCAFlow"),
            ]
        ),
    ]
)
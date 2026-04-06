// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TCAFlowPackageExample",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .executable(name: "TCAFlowPackageExample", targets: ["TCAFlowPackageExample"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.25.5"),
        .package(path: "../.."), // TCAFlow 로컬 패키지 참조
    ],
    targets: [
        .executableTarget(
            name: "TCAFlowPackageExample",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "TCAFlow", package: "TCAFlow"),
            ]
        ),
    ]
)
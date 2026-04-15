// swift-tools-version: 6.0
import PackageDescription
import CompilerPluginSupport

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
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.25.5"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
        .package(url: "https://github.com/Roy-wonji/LogMacro", from: "1.0.0"),
    ],
    targets: [
        .macro(
            name: "TCAFlowMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
            path: "Sources/TCAFlowMacros"
        ),
        .target(
            name: "TCAFlow",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "TCAFlowMacros",
                .product(name: "LogMacro", package: "LogMacro"),
            ],
            path: "Sources/TCAFlow",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency"),
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .testTarget(
            name: "TCAFlowTests",
            dependencies: ["TCAFlow"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "TCAFlowMacrosTests",
            dependencies: [
                "TCAFlowMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
    ]
)

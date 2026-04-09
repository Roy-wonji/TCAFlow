import ProjectDescription

let project = Project(
    name: "TCAFlowExamples",
    packages: [
        .local(path: "../.."),
        .remote(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            requirement: .upToNextMajor(from: "1.25.5")
        ),
        .remote(
            url: "https://github.com/pointfreeco/swift-identified-collections",
            requirement: .upToNextMajor(from: "1.1.1")
        )
    ],
    targets: [
        .target(
            name: "TCAFlowExamples",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tcaflow.examples",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:]
            ]),
            sources: [
                "TCAFlowExamples/TCAFlowExamplesApp.swift"
            ],
            resources: [],
            dependencies: [
                .package(product: "TCAFlow"),
                .package(product: "ComposableArchitecture"),
                .package(product: "IdentifiedCollections")
            ],
            settings: .settings(base: [
                "ENABLE_DEBUG_DYLIB": "NO",
                "SWIFT_STRICT_CONCURRENCY": "targeted",
                "SWIFT_VERSION": "5"
            ])
        )
    ]
)

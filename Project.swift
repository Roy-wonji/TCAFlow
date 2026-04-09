import ProjectDescription

let project = Project(
    name: "TCAFlow",
    targets: [
        .target(
            name: "TCAFlow",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.tcaflow.framework",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Sources/TCAFlow/**"],
            dependencies: [
                .external(name: "ComposableArchitecture"),
                .target(name: "TCAFlowMacros")
            ]
        ),
        .target(
            name: "TCAFlowMacros",
            destinations: .macOS,
            product: .macro,
            bundleId: "com.tcaflow.macros",
            deploymentTargets: .macOS("13.0"),
            infoPlist: .default,
            sources: ["Sources/TCAFlowMacros/**"],
            dependencies: [
                .external(name: "SwiftSyntaxMacros"),
                .external(name: "SwiftCompilerPlugin")
            ],
            settings: .settings(
                base: [
                    "SKIP_INSTALL": "YES",
                ]
            )
        )
    ]
)
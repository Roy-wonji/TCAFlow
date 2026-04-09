import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: .init([
        .remote(url: "https://github.com/pointfreeco/swift-composable-architecture", requirement: .upToNextMajor(from: "1.25.5")),
        .remote(url: "https://github.com/swiftlang/swift-syntax.git", requirement: .upToNextMajor(from: "600.0.0"))
    ])
)
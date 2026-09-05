import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: .init([
        .remote(url: "https://github.com/pointfreeco/swift-composable-architecture", requirement: .upToNextMajor(from: "1.26.2")),
        .remote(url: "https://github.com/swiftlang/swift-syntax.git", requirement: .exact("603.0.2"))
    ])
)

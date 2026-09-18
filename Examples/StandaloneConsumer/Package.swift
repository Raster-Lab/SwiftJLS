// swift-tools-version: 6.2
// SPDX-License-Identifier: MIT
import PackageDescription

let package = Package(
    name: "StandaloneConsumer",
    platforms: [
        .macOS("26.0"),
        .iOS("26.0"),
        .tvOS("26.0"),
        .visionOS("26.0"),
        .watchOS("26.0")
    ],
    dependencies: [
        .package(path: "../../")
    ],
    targets: [
        .executableTarget(
            name: "StandaloneConsumer",
            dependencies: [.product(name: "SwiftJLS", package: "SwiftJLS")]
        )
    ],
    swiftLanguageModes: [.v6]
)

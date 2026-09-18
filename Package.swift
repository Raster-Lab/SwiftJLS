// swift-tools-version: 6.2
// SPDX-License-Identifier: MIT
import PackageDescription

let package = Package(
    name: "SwiftJLS",
    platforms: [
        .macOS("26.0"),
        .iOS("26.0"),
        .tvOS("26.0"),
        .visionOS("26.0"),
        .watchOS("26.0")
    ],
    products: [
        .library(name: "SwiftJLS", targets: ["SwiftJLS"])
    ],
    dependencies: [],
    targets: [
        .target(name: "SwiftJLS"),
        .testTarget(name: "SwiftJLSTests", dependencies: ["SwiftJLS"])
    ],
    swiftLanguageModes: [.v6]
)

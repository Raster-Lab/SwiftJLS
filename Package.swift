// swift-tools-version: 6.2
// SPDX-License-Identifier: MIT
import PackageDescription

let package = Package(
    name: "SwiftJLS",
    platforms: [.macOS(.v26), .iOS(.v26), .tvOS(.v26), .visionOS(.v26), .watchOS(.v26)],
    products: [.library(name: "SwiftJLS", targets: ["SwiftJLS"])],
    targets: [
        .target(name: "SwiftJLS"),
        .testTarget(name: "SwiftJLSTests", dependencies: ["SwiftJLS"])
    ],
    swiftLanguageModes: [.v6]
)

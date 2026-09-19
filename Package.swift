// swift-tools-version: 6.4
// SPDX-License-Identifier: MIT
import PackageDescription

let package = Package(
    name: "SwiftJLS",
    platforms: [.macOS(.v27), .iOS(.v27), .tvOS(.v27), .visionOS(.v27), .watchOS(.v27)],
    products: [.library(name: "SwiftJLS", targets: ["SwiftJLS"]),
               .executable(name: "swiftjls", targets: ["SwiftJLSCLI"])],
    targets: [
        .target(name: "SwiftJLS"),
        .executableTarget(name: "SwiftJLSCLI", dependencies: ["SwiftJLS"]),
        .testTarget(name: "SwiftJLSTests", dependencies: ["SwiftJLS"])
    ],
    swiftLanguageModes: [.v6]
)

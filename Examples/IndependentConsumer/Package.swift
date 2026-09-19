// swift-tools-version: 6.4
// SPDX-License-Identifier: MIT
import PackageDescription
let package = Package(
    name: "IndependentConsumer",
    platforms: [.macOS(.v27)],
    dependencies: [.package(path: "../..")],
    targets: [.executableTarget(name: "Consumer", dependencies: [.product(name: "SwiftJLS", package: "SwiftJLS")])],
    swiftLanguageModes: [.v6]
)

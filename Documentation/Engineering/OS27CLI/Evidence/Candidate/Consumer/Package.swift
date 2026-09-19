// swift-tools-version: 6.4
import PackageDescription
let package = Package(name: "FreshConsumer", platforms: [.macOS(.v27)],
 dependencies: [.package(path: "/Users/suresh/Documents/Codex/2026-09-18/create-coding-agents-to-start-work/outputs/SwiftJLS")],
 targets: [.executableTarget(name: "Consumer", dependencies: [.product(name: "SwiftJLS", package: "SwiftJLS")])],
 swiftLanguageModes: [.v6])

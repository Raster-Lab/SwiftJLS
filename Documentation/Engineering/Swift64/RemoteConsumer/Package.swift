// swift-tools-version: 6.4
import PackageDescription
let package = Package(name: "RemoteMigrationConsumer", platforms: [.macOS("26.0")],
 dependencies: [.package(url: "https://github.com/Raster-Lab/SwiftJLS.git", revision: "f63e52c5e2a82fc0aff3e7d9eef85f3122161e0d")],
 targets: [.executableTarget(name: "MigrationExample", dependencies: [.product(name: "SwiftJLS", package: "SwiftJLS")])],
 swiftLanguageModes: [.v6])

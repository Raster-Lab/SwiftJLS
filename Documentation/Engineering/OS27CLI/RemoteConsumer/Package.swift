// swift-tools-version: 6.4
import PackageDescription
let package = Package(name: "RemoteMigrationConsumer", platforms: [.macOS("27.0")],
 dependencies: [.package(url: "https://github.com/Raster-Lab/SwiftJLS.git", revision: "c7c871731c4b58c503cb35aa81b8d6763722a021")],
 targets: [.executableTarget(name: "MigrationExample", dependencies: [.product(name: "SwiftJLS", package: "SwiftJLS")])],
 swiftLanguageModes: [.v6])

// swift-tools-version: 6.4
import PackageDescription
let package = Package(
    name: "RemoteConsumerSwiftJLS",
    platforms: [.macOS("27.0")],
    dependencies: [.package(url: "https://github.com/Raster-Lab/SwiftJLS.git", revision: "eeee61edc3fcafbc945930dbf21dd89b6bd37079")],
    targets: [.executableTarget(name: "Consumer", dependencies: [.product(name: "SwiftJLS", package: "SwiftJLS")])],
    swiftLanguageModes: [.v6]
)

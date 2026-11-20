// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "HomeViewPreview",
    platforms: [.macOS(.v15)],
    products: [.executable(name: "HomeViewPreview", targets: ["HomeViewPreview"])],
    targets: [.executableTarget(name: "HomeViewPreview", resources: [.copy("Resources")])],
    swiftLanguageModes: [.v5]
)

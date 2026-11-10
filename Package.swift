// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MacUtilityKit",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "MacUtilityKit", targets: ["MacUtilityKit"])
    ],
    targets: [
        .target(name: "MacUtilityKit")
    ],
    swiftLanguageVersions: [.v5]
)

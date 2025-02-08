// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "KoboldFramework",
    platforms: [
        .iOS("17.0"),
        .macOS("14.0")
    ],
    products: [
        .library(
            name: "KoboldFramework",
            targets: ["KoboldFramework"]),
    ],
    targets: [
        .target(
            name: "KoboldFramework"),
    ]
)

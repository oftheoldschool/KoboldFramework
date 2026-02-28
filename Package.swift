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
    dependencies: [
        .package(url: "https://github.com/oftheoldschool/KoboldLogging.git", "0.0.1"..<"1.0.0"),
    ],
    targets: [
        .target(
            name: "KoboldFramework",
            dependencies: [
                .product(name: "KoboldLogging", package: "KoboldLogging"),
            ]),
    ]
)

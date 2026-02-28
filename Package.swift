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
        .library(
            name: "KoboldLogging",
            targets: ["KoboldLogging"]),
    ],
    dependencies: [
        .package(url: "https://github.com/oftheoldschool/KoboldMathExtensions.git", "0.0.1"..<"1.0.0"),
    ],
    targets: [
        .target(
            name: "KoboldFramework",
            dependencies: [
                "KoboldLogging",
                .product(name: "KoboldMathExtensions", package: "KoboldMathExtensions")
            ]),
        .target(
            name: "KoboldLogging"),
    ]
)

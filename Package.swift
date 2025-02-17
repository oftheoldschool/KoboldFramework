// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "KoboldFramework",
    products: [
        .library(
            name: "KoboldFramework",
            targets: ["KoboldFramework"]),
        .library(
            name: "KoboldLogging",
            targets: ["KoboldLogging"]),
    ],
    targets: [
        .target(
            name: "KoboldFramework",
            dependencies: ["KoboldLogging"]),
        .target(
            name: "KoboldLogging"),
    ]
)

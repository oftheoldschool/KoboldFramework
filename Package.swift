// swift-tools-version: 5.10

import Foundation
import PackageDescription

// When this package is consumed as a path dep alongside a sibling KoboldLogging
// path dep (i.e., both vendored under a parent's Sources/Vendored/), prefer the
// sibling so SwiftPM doesn't see a duplicate identity from a GitHub-URL ref.
// Otherwise (consumed via the GitHub URL itself, or built standalone), keep the
// canonical URL dep. Context.packageDirectory is required because SPM evaluates
// sub-package manifests with a CWD that isn't this package's root, so plain
// relative paths to "../KoboldLogging" don't resolve.
let siblingPath = "\(Context.packageDirectory)/../KoboldLogging"
let koboldLoggingDep: Package.Dependency =
    FileManager.default.fileExists(atPath: "\(siblingPath)/Package.swift")
        ? .package(path: siblingPath)
        : .package(url: "https://github.com/oftheoldschool/KoboldLogging.git", "0.0.1"..<"1.0.0")

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
        koboldLoggingDep,
    ],
    targets: [
        .target(
            name: "KoboldFramework",
            dependencies: [
                .product(name: "KoboldLogging", package: "KoboldLogging"),
            ]),
    ]
)

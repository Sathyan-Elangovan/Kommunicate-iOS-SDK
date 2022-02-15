// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Kommunicate",
    defaultLocalization: "en",
    platforms: [.iOS(.v12)],
    products: [
        .library(
            name: "Kommunicate",
            targets: ["Kommunicate"]
        ),
    ],
    dependencies: [
        .package(name: "KommunicateChatUI-iOS-SDK", url: "https://github.com/Sathyan-Elangovan/KommunicateChatUI-iOS-SDK.git", .revision("131f26d9a0102320635693351f6a8bdb193158dc")),
    ],
    targets: [
        .target(
            name: "Kommunicate",
            dependencies: [.product(name: "KommunicateChatUI-iOS-SDK", package: "KommunicateChatUI-iOS-SDK")],
            path: "Sources",
            resources: [.process("Resources")]
        ),
    ]
)

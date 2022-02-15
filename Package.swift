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
        .package(name: "KommunicateChatUI-iOS-SDK", url: "https://github.com/Sathyan-Elangovan/KommunicateChatUI-iOS-SDK.git", .revision("cb7ca39d69d9c7c045a3a784905819092d9ad4ab")),
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

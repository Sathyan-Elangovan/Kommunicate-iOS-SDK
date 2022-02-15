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
        .package(name: "KommunicateChatUI-iOS-SDK", url: "https://github.com/Sathyan-Elangovan/KommunicateChatUI-iOS-SDK.git", .revision("137cf03ac3047c762164515c3b1a2f755d265122")),
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

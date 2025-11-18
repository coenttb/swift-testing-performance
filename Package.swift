// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "swift-testing-performance",
    products: [
        .library(
            name: "TestingPerformance",
            targets: ["TestingPerformance"]
        )
    ],
    targets: [
        .target(
            name: "TestingPerformance",
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "TestingPerformance Tests",
            dependencies: ["TestingPerformance"]
        )
    ]
)

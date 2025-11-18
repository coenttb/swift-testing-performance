// swift-tools-version: 6.2

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
            name: "CAllocationTracking",
            linkerSettings: [
                .linkedLibrary("dl", .when(platforms: [.linux]))
            ]
        ),
        .target(
            name: "TestingPerformance",
            dependencies: [
                .target(name: "CAllocationTracking", condition: .when(platforms: [.linux]))
            ],
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
